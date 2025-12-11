package info.nfcreader.host;

import javax.smartcardio.*;
import java.util.ArrayList;
import java.util.List;

/**
 * Manages smart card readers and provides access to connected terminals.
 * Uses javax.smartcardio API for cross-platform card reader access.
 */
public class ReaderManager {
    
    private TerminalFactory factory;
    private CardTerminals terminals;
    
    public ReaderManager() throws CardException {
        // Get the default terminal factory (PC/SC)
        factory = TerminalFactory.getDefault();
        terminals = factory.terminals();
    }
    
    /**
     * Lists all available card readers.
     * @return Array of reader names
     */
    public String[] listReaders() throws CardException {
        List<CardTerminal> terminalList = terminals.list();
        List<String> readerNames = new ArrayList<>();
        
        for (CardTerminal terminal : terminalList) {
            readerNames.add(terminal.getName());
        }
        
        return readerNames.toArray(new String[0]);
    }
    
    /**
     * Gets a specific card terminal by index.
     * @param index Index of the reader
     * @return CardTerminal instance
     */
    public CardTerminal getReader(int index) throws CardException {
        List<CardTerminal> terminalList = terminals.list();
        
        if (index < 0 || index >= terminalList.size()) {
            throw new IllegalArgumentException("Invalid reader index: " + index);
        }
        
        return terminalList.get(index);
    }
    
    /**
     * Gets a card terminal by name.
     * @param name Name of the reader
     * @return CardTerminal instance or null if not found
     */
    public CardTerminal getReaderByName(String name) throws CardException {
        List<CardTerminal> terminalList = terminals.list();
        
        for (CardTerminal terminal : terminalList) {
            if (terminal.getName().equals(name)) {
                return terminal;
            }
        }
        
        return null;
    }
    
    /**
     * Checks if a card is present on the specified terminal.
     * @param terminal The card terminal to check
     * @return true if a card is present
     */
    public boolean isCardPresent(CardTerminal terminal) throws CardException {
        return terminal.isCardPresent();
    }
    
    /**
     * Waits for a card to be inserted into the terminal.
     * @param terminal The card terminal to monitor
     * @param timeoutMs Timeout in milliseconds (0 for infinite)
     * @return true if a card was detected within the timeout
     */
    public boolean waitForCard(CardTerminal terminal, long timeoutMs) throws CardException {
        return terminal.waitForCardPresent(timeoutMs);
    }
    
    /**
     * Waits for a card to be removed from the terminal.
     * @param terminal The card terminal to monitor
     * @param timeoutMs Timeout in milliseconds (0 for infinite)
     * @return true if the card was removed within the timeout
     */
    public boolean waitForCardRemoval(CardTerminal terminal, long timeoutMs) throws CardException {
        return terminal.waitForCardAbsent(timeoutMs);
    }
    
    /**
     * Connects to a card in the specified terminal.
     * @param terminal The card terminal
     * @param protocol Protocol to use (* for any, T=0, T=1, or direct)
     * @return Card instance
     */
    public Card connect(CardTerminal terminal, String protocol) throws CardException {
        return terminal.connect(protocol);
    }
}
