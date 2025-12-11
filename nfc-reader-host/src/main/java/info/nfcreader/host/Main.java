package info.nfcreader.host;

/**
 * Main entry point for the NFC Reader Native Messaging Host.
 * Supports multiple commands: list-readers, listen, native-messaging
 */
public class Main {
    
    public static void main(String[] args) {
        try {
            // If no args or first arg is a chrome-extension:// URL, default to native-messaging mode
            if (args.length == 0 || args[0].startsWith("chrome-extension://")) {
                handleNativeMessaging();
                return;
            }

            String command = args[0].toLowerCase();
            
            switch (command) {
                case "list-readers":
                    handleListReaders();
                    break;
                    
                case "listen":
                    if (args.length < 2) {
                        System.err.println("Error: listen command requires reader index");
                        printUsage();
                        System.exit(1);
                    }
                    int readerIndex = Integer.parseInt(args[1]);
                    handleListen(readerIndex);
                    break;
                    
                case "native-messaging":
                    handleNativeMessaging();
                    break;
                    
                case "help":
                case "--help":
                case "-h":
                    printUsage();
                    break;
                    
                default:
                    System.err.println("Unknown command: " + command);
                    printUsage();
                    System.exit(1);
            }
            
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    private static void handleListReaders() throws Exception {
        try {
            ReaderManager readerManager = new ReaderManager();
            String[] readers = readerManager.listReaders();
            
            if (readers.length == 0) {
                System.err.println("No readers found.");
                System.err.println();
                System.err.println("Troubleshooting:");
                System.err.println("  1. Check if reader is connected: lsusb | grep -i acr");
                System.err.println("  2. Check if pcscd is running: systemctl status pcscd");
                System.err.println("  3. Restart pcscd: sudo systemctl restart pcscd");
                System.err.println("  4. Check permissions: sudo usermod -aG pcscd $USER");
                System.err.println("  5. Install ccid driver: sudo pacman -S ccid (Arch) or sudo apt install libccid (Ubuntu)");
                System.exit(1);
            }
            
            CommandHandler handler = new CommandHandler(readerManager);
            String response = handler.handleListReaders();
            System.out.println(response);
        } catch (javax.smartcardio.CardException e) {
            System.err.println("Error accessing smart card readers:");
            System.err.println("  " + e.getMessage());
            System.err.println();
            
            if (e.getCause() != null && e.getCause().toString().contains("SCARD_E_NO_READERS_AVAILABLE")) {
                System.err.println("Cause: No readers available to PC/SC subsystem");
                System.err.println();
                System.err.println("Troubleshooting steps:");
                System.err.println("  1. Install pcsclite: sudo pacman -S pcsclite ccid");
                System.err.println("  2. Start pcscd: sudo systemctl start pcscd");
                System.err.println("  3. Check USB: lsusb | grep -i acr");
                System.err.println("  4. Reconnect the reader (unplug and plug back in)");
                System.err.println("  5. Check dmesg: dmesg | tail -20");
                System.err.println("  6. Test with: pcsc_scan");
            } else if (e.getCause() != null && e.getCause().toString().contains("SCARD_E_NO_SERVICE")) {
                System.err.println("Cause: PC/SC daemon (pcscd) is not running");
                System.err.println();
                System.err.println("Fix:");
                System.err.println("  sudo systemctl start pcscd");
            }
            
            System.exit(1);
        }
    }
    
    private static void handleListen(int readerIndex) throws Exception {
        ReaderManager readerManager = new ReaderManager();
        String[] readers = readerManager.listReaders();
        
        if (readerIndex < 0 || readerIndex >= readers.length) {
            System.err.println("Error: Invalid reader index. Available readers: " + readers.length);
            System.exit(1);
        }
        
        CardReader cardReader = new CardReader(readerManager, readerIndex);
        CommandHandler handler = new CommandHandler(readerManager);
        
        System.out.println("Listening for NFC cards on reader: " + readers[readerIndex]);
        System.out.println("Press Ctrl+C to stop");
        
        // Continuous listening mode
        while (true) {
            try {
                String uid = cardReader.waitForCard();
                if (uid != null) {
                    System.out.println("Card detected - UID: " + uid);
                }
            } catch (Exception e) {
                System.err.println("Error reading card: " + e.getMessage());
            }
            
            // Small delay to prevent CPU spinning
            Thread.sleep(100);
        }
    }
    
    private static void handleNativeMessaging() throws Exception {
        ReaderManager readerManager = new ReaderManager();
        CommandHandler commandHandler = new CommandHandler(readerManager);
        NativeMessagingHost host = new NativeMessagingHost(commandHandler);
        
        // Run the native messaging protocol loop
        host.run();
    }
    
    private static void printUsage() {
        System.out.println("NFC Reader Native Messaging Host");
        System.out.println();
        System.out.println("Usage:");
        System.out.println("  nfc-reader-host list-readers              List all available NFC readers");
        System.out.println("  nfc-reader-host listen <reader-index>     Listen for cards on specified reader");
        System.out.println("  nfc-reader-host native-messaging          Run as native messaging host");
        System.out.println("  nfc-reader-host help                      Show this help message");
        System.out.println();
        System.out.println("Examples:");
        System.out.println("  nfc-reader-host list-readers");
        System.out.println("  nfc-reader-host listen 0");
        System.out.println();
    }
}
