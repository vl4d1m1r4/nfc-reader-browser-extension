package info.nfcreader.host;

import javax.smartcardio.Card;
import javax.smartcardio.CardChannel;
import javax.smartcardio.CardException;
import javax.smartcardio.CardTerminal;
import javax.smartcardio.CommandAPDU;
import javax.smartcardio.ResponseAPDU;

/**
 * Handles reading NFC-A cards and extracting UIDs.
 * Supports 4-byte, 7-byte, and 10-byte UIDs.
 */
public class CardReader {
    
    private final ReaderManager readerManager;
    private final CardTerminal terminal;
    private final int readerIndex;
    
    // APDU command to get NFC card UID (ACR122U specific)
    private static final byte[] GET_UID_COMMAND = new byte[] {
        (byte) 0xFF, // CLA (Class)
        (byte) 0xCA, // INS (Instruction) - Get Data
        (byte) 0x00, // P1 (Parameter 1)
        (byte) 0x00, // P2 (Parameter 2)
        (byte) 0x00  // Le (Expected length - 0 means any)
    };
    
    public CardReader(ReaderManager readerManager, int readerIndex) throws CardException {
        this.readerManager = readerManager;
        this.readerIndex = readerIndex;
        this.terminal = readerManager.getReader(readerIndex);
    }
    
    /**
     * Waits for a card to be present and reads its UID.
     * @return UID as hex string, or null if no card detected
     */
    public String waitForCard() throws CardException {
        // Wait for card presence (100ms timeout for non-blocking check)
        boolean cardPresent = readerManager.waitForCard(terminal, 100);
        
        if (!cardPresent) {
            return null;
        }
        
        // Small delay to let card stabilize on reader
        try {
            Thread.sleep(50);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        // Try reading with retry for status 6300 (card not ready)
        String uid = null;
        int maxRetries = 3;
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
            try {
                uid = readUID();
                break; // Success, exit retry loop
            } catch (CardException e) {
                if (e.getMessage().contains("6300") && attempt < maxRetries) {
                    // Card not ready or moved, retry after short delay
                    try {
                        Thread.sleep(100);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        throw e;
                    }
                } else {
                    // Other error or max retries reached
                    throw e;
                }
            }
        }
        
        // Wait for card removal before detecting again
        if (uid != null) {
            readerManager.waitForCardRemoval(terminal, 0);
        }
        
        return uid;
    }
    
    /**
     * Reads the UID from the currently present card.
     * @return UID as hex string
     */
    public String readUID() throws CardException {
        Card card = null;
        try {
            // Connect to the card using any protocol
            card = readerManager.connect(terminal, "*");
            
            // Get the basic channel
            CardChannel channel = card.getBasicChannel();
            
            // Send the GET UID command
            CommandAPDU command = new CommandAPDU(GET_UID_COMMAND);
            ResponseAPDU response = channel.transmit(command);
            
            // Check if the command was successful (SW1SW2 = 9000)
            int sw = response.getSW();
            if (sw != 0x9000) {
                String errorMsg = getStatusCodeDescription(sw);
                throw new CardException("Failed to read UID. Status: " + 
                    String.format("%04X", sw) + " - " + errorMsg);
            }
            
            // Get the UID bytes from the response
            byte[] uidBytes = response.getData();
            
            if (uidBytes == null || uidBytes.length == 0) {
                throw new CardException("No UID data returned from card");
            }
            
            // Convert to hex string
            return bytesToHex(uidBytes);
            
        } finally {
            if (card != null) {
                try {
                    card.disconnect(false);
                } catch (CardException e) {
                    // Ignore disconnect errors
                }
            }
        }
    }
    
    /**
     * Gets a human-readable description for common status codes.
     * @param statusCode The status word from APDU response
     * @return Description of the error
     */
    private String getStatusCodeDescription(int statusCode) {
        switch (statusCode) {
            case 0x6300:
                return "Card verification failed or card removed during operation. Keep card on reader.";
            case 0x6400:
                return "Card state unchanged (no data returned)";
            case 0x6A81:
                return "Function not supported";
            case 0x6A82:
                return "File or application not found";
            case 0x6A86:
                return "Incorrect parameters P1-P2";
            case 0x6A88:
                return "Referenced data not found";
            case 0x6B00:
                return "Wrong parameters P1-P2";
            case 0x6D00:
                return "Instruction not supported";
            case 0x6E00:
                return "Class not supported";
            case 0x6F00:
                return "No precise diagnosis (card internal error)";
            case 0x9000:
                return "Success";
            default:
                return "Unknown error";
        }
    }
    
    /**
     * Checks if a card is currently present.
     * @return true if a card is present
     */
    public boolean isCardPresent() throws CardException {
        return readerManager.isCardPresent(terminal);
    }
    
    /**
     * Converts byte array to hex string.
     * @param bytes Byte array
     * @return Hex string (uppercase, no separators)
     */
    private String bytesToHex(byte[] bytes) {
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02X", b));
        }
        return sb.toString();
    }
    
    /**
     * Determines the UID type based on length.
     * @param uid UID hex string
     * @return UID type description
     */
    public static String getUIDType(String uid) {
        int length = uid.length() / 2; // Convert hex string length to byte count
        
        switch (length) {
            case 4:
                return "Single size UID (4 bytes)";
            case 7:
                return "Double size UID (7 bytes)";
            case 10:
                return "Triple size UID (10 bytes)";
            default:
                return "Unknown UID type (" + length + " bytes)";
        }
    }
}
