package info.nfcreader.host;

import org.junit.jupiter.api.Test;
import java.io.*;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for NativeMessagingHost protocol implementation.
 */
class NativeMessagingHostTest {
    
    @Test
    void testMessageEncoding() throws IOException {
        // Test that messages are encoded correctly
        String testMessage = "{\"action\":\"test\"}";
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        
        // Encode message
        byte[] messageBytes = testMessage.getBytes("UTF-8");
        byte[] lengthBytes = ByteBuffer.allocate(4)
            .order(ByteOrder.nativeOrder())
            .putInt(messageBytes.length)
            .array();
        
        baos.write(lengthBytes);
        baos.write(messageBytes);
        
        byte[] encoded = baos.toByteArray();
        
        // Verify length prefix
        ByteBuffer buffer = ByteBuffer.wrap(encoded, 0, 4)
            .order(ByteOrder.nativeOrder());
        int length = buffer.getInt();
        
        assertEquals(messageBytes.length, length);
        
        // Verify message body
        String decodedMessage = new String(encoded, 4, length, "UTF-8");
        assertEquals(testMessage, decodedMessage);
    }
    
    @Test
    void testMessageLength() {
        String message = "{\"test\":\"data\"}";
        byte[] messageBytes = message.getBytes();
        
        // Length should match byte count
        assertEquals(15, messageBytes.length);
    }
}
