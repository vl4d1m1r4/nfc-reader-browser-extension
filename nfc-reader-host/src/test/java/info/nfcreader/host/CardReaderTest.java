package info.nfcreader.host;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for CardReader UID type detection.
 */
class CardReaderTest {
    
    @Test
    void testGetUIDType_SingleSize() {
        String uid = "04A1B2C3"; // 4 bytes
        String type = CardReader.getUIDType(uid);
        assertEquals("Single size UID (4 bytes)", type);
    }
    
    @Test
    void testGetUIDType_DoubleSize() {
        String uid = "04A1B2C3D4E5F6"; // 7 bytes
        String type = CardReader.getUIDType(uid);
        assertEquals("Double size UID (7 bytes)", type);
    }
    
    @Test
    void testGetUIDType_TripleSize() {
        String uid = "04A1B2C3D4E5F6071819"; // 10 bytes
        String type = CardReader.getUIDType(uid);
        assertEquals("Triple size UID (10 bytes)", type);
    }
    
    @Test
    void testGetUIDType_Unknown() {
        String uid = "04A1"; // 2 bytes (unusual)
        String type = CardReader.getUIDType(uid);
        assertTrue(type.contains("Unknown"));
    }
}
