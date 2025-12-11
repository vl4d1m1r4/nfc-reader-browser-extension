package info.nfcreader.host;

import java.io.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

/**
 * Implements the Chrome/Firefox Native Messaging protocol.
 * Reads messages from stdin and writes responses to stdout.
 * 
 * Protocol:
 * - Each message is prefixed with 4-byte length (native byte order)
 * - Message body is UTF-8 encoded JSON
 */
public class NativeMessagingHost {
    
    private final CommandHandler commandHandler;
    private static OutputStream outputStream = System.out;
    
    public NativeMessagingHost(CommandHandler commandHandler) {
        this.commandHandler = commandHandler;
    }
    
    /**
     * Runs the native messaging protocol loop.
     * Reads messages from stdin and processes them until EOF.
     */
    public void run() throws IOException {
        // Use binary streams for precise byte handling
        InputStream input = System.in;
        
        // Add shutdown hook for cleanup
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            commandHandler.cleanup();
        }));
        
        try {
            while (true) {
                // Read message
                String message = readMessage(input);
                if (message == null) {
                    // EOF reached, exit gracefully
                    break;
                }
                
                // Process command
                String response = commandHandler.handleCommand(message);
                
                // Send response
                sendMessage(response);
            }
        } catch (EOFException e) {
            // Normal termination
        } catch (IOException e) {
            System.err.println("I/O error in native messaging: " + e.getMessage());
            throw e;
        } finally {
            commandHandler.cleanup();
        }
    }
    
    /**
     * Reads a message from the input stream.
     * @param input Input stream
     * @return Message string, or null if EOF
     */
    private String readMessage(InputStream input) throws IOException {
        // Read 4-byte length header
        byte[] lengthBytes = new byte[4];
        int bytesRead = readFully(input, lengthBytes);
        
        if (bytesRead == -1) {
            return null; // EOF
        }
        
        if (bytesRead != 4) {
            throw new IOException("Incomplete length header");
        }
        
        // Convert to integer (native byte order)
        int messageLength = ByteBuffer.wrap(lengthBytes)
            .order(ByteOrder.nativeOrder())
            .getInt();
        
        // Validate message length
        if (messageLength <= 0 || messageLength > 1024 * 1024) {
            throw new IOException("Invalid message length: " + messageLength);
        }
        
        // Read message body
        byte[] messageBytes = new byte[messageLength];
        bytesRead = readFully(input, messageBytes);
        
        if (bytesRead != messageLength) {
            throw new IOException("Incomplete message body");
        }
        
        // Convert to string
        return new String(messageBytes, "UTF-8");
    }
    
    /**
     * Sends a message to the output stream.
     * @param message Message string
     */
    public static synchronized void sendMessage(String message) {
        try {
            // Convert message to bytes
            byte[] messageBytes = message.getBytes("UTF-8");
            
            // Create length header (4 bytes, native byte order)
            byte[] lengthBytes = ByteBuffer.allocate(4)
                .order(ByteOrder.nativeOrder())
                .putInt(messageBytes.length)
                .array();
            
            // Write length header
            outputStream.write(lengthBytes);
            
            // Write message body
            outputStream.write(messageBytes);
            
            // Flush to ensure immediate delivery
            outputStream.flush();
            
        } catch (IOException e) {
            System.err.println("Error sending message: " + e.getMessage());
        }
    }
    
    /**
     * Reads exactly the specified number of bytes from the input stream.
     * @param input Input stream
     * @param buffer Buffer to read into
     * @return Number of bytes read, or -1 if EOF reached before any bytes
     */
    private int readFully(InputStream input, byte[] buffer) throws IOException {
        int totalRead = 0;
        int length = buffer.length;
        
        while (totalRead < length) {
            int read = input.read(buffer, totalRead, length - totalRead);
            
            if (read == -1) {
                if (totalRead == 0) {
                    return -1; // EOF at start
                } else {
                    throw new EOFException("Unexpected EOF");
                }
            }
            
            totalRead += read;
        }
        
        return totalRead;
    }
    
    /**
     * Sets the output stream for testing purposes.
     * @param stream Output stream
     */
    public static void setOutputStream(OutputStream stream) {
        outputStream = stream;
    }
}
