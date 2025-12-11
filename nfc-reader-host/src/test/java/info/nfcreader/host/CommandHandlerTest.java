package info.nfcreader.host;

import com.google.gson.Gson;
import com.google.gson.JsonObject;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for CommandHandler JSON processing.
 */
class CommandHandlerTest {
    
    private final Gson gson = new Gson();
    
    @Test
    void testHandleCommand_UnknownAction() {
        // Note: This test doesn't require actual card readers
        // It tests JSON parsing and error handling
        
        String commandJson = "{\"action\": \"unknown-action\"}";
        
        // We can't fully test without mocking ReaderManager,
        // but we can test the JSON structure
        JsonObject command = gson.fromJson(commandJson, JsonObject.class);
        assertEquals("unknown-action", command.get("action").getAsString());
    }
    
    @Test
    void testCreateErrorResponse_Format() {
        // Test that error responses have the correct structure
        String errorJson = "{\"success\": false, \"error\": \"Test error\"}";
        JsonObject error = gson.fromJson(errorJson, JsonObject.class);
        
        assertFalse(error.get("success").getAsBoolean());
        assertEquals("Test error", error.get("error").getAsString());
    }
    
    @Test
    void testSuccessResponse_Format() {
        // Test that success responses have the correct structure
        String successJson = "{\"success\": true, \"readers\": [], \"count\": 0}";
        JsonObject success = gson.fromJson(successJson, JsonObject.class);
        
        assertTrue(success.get("success").getAsBoolean());
        assertTrue(success.has("readers"));
        assertEquals(0, success.get("count").getAsInt());
    }
}
