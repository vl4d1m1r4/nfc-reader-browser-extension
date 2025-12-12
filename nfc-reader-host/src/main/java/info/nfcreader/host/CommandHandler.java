package info.nfcreader.host;

import java.util.HashMap;
import java.util.Map;

import javax.smartcardio.CardException;

import com.google.gson.Gson;
import com.google.gson.JsonObject;

/**
 * Handles commands from the browser extension and generates JSON responses.
 * Processes commands like list-readers, start-listening, stop-listening.
 */
public class CommandHandler {

    private final ReaderManager readerManager;
    private final Gson gson;
    private CardReader activeCardReader;
    private Thread listeningThread;
    private volatile boolean isListening = false;

    public CommandHandler(ReaderManager readerManager) {
        this.readerManager = readerManager;
        this.gson = new Gson();
    }

    /**
     * Processes a command from the browser extension.
     * 
     * @param commandJson JSON string containing the command
     * @return JSON response string
     */
    public String handleCommand(String commandJson) {
        try {
            JsonObject command = gson.fromJson(commandJson, JsonObject.class);
            String action = command.get("action").getAsString();

            switch (action) {
                case "get-version":
                    return handleGetVersion();

                case "list-readers":
                    return handleListReaders();

                case "start-listening":
                    int readerIndex = command.get("readerIndex").getAsInt();
                    return handleStartListening(readerIndex);

                case "stop-listening":
                    return handleStopListening();

                case "get-status":
                    return handleGetStatus();

                default:
                    return createErrorResponse("Unknown action: " + action);
            }

        } catch (Exception e) {
            return createErrorResponse("Error processing command: " + e.getMessage());
        }
    }

    /**
     * Gets the native host version.
     * 
     * @return JSON response with version
     */
    public String handleGetVersion() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("version", Main.VERSION);

        return gson.toJson(response);
    }

    /**
     * Lists all available card readers.
     * 
     * @return JSON response with reader list
     */
    public String handleListReaders() {
        try {
            String[] readers = readerManager.listReaders();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("readers", readers);
            response.put("count", readers.length);

            return gson.toJson(response);

        } catch (CardException e) {
            // Return empty list instead of error when no readers are available
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("readers", new String[0]);
            response.put("count", 0);
            response.put("message", "No readers detected. Please connect an NFC reader.");

            return gson.toJson(response);
        }
    }

    /**
     * Starts listening for cards on the specified reader.
     * 
     * @param readerIndex Index of the reader to use
     * @return JSON response
     */
    public String handleStartListening(int readerIndex) {
        try {
            // Stop any existing listening
            if (isListening) {
                stopListening();
            }

            // Validate reader index
            String[] readers = readerManager.listReaders();
            if (readers.length == 0) {
                return createErrorResponse("No readers available. Please connect an NFC reader.");
            }
            if (readerIndex < 0 || readerIndex >= readers.length) {
                return createErrorResponse("Invalid reader index: " + readerIndex);
            }

            // Create card reader
            activeCardReader = new CardReader(readerManager, readerIndex);
            isListening = true;

            // Start listening in background thread
            listeningThread = new Thread(() -> {
                int consecutiveErrors = 0;
                while (isListening) {
                    try {
                        String uid = activeCardReader.waitForCard();
                        if (uid != null && isListening) {
                            // Send card detected event
                            sendCardDetectedEvent(uid);
                        }
                        // Reset error counter on successful read (whether card found or not)
                        consecutiveErrors = 0;
                    } catch (CardException e) {
                        if (isListening) {
                            consecutiveErrors++;
                            // Send error only once, then stop listening to prevent spam
                            if (consecutiveErrors == 1) {
                                sendErrorEvent("Error reading card: " + e.getMessage());
                            }
                            // Stop listening after 3 consecutive errors (likely reader disconnected)
                            if (consecutiveErrors >= 3) {
                                isListening = false;
                                break;
                            }
                        }
                    } catch (Exception e) {
                        if (isListening) {
                            sendErrorEvent("Error reading card: " + e.getMessage());
                            isListening = false;
                            break;
                        }
                    }

                    try {
                        Thread.sleep(100);
                    } catch (InterruptedException e) {
                        break;
                    }
                }
            });
            listeningThread.start();

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Started listening on reader: " + readers[readerIndex]);
            response.put("readerIndex", readerIndex);
            response.put("readerName", readers[readerIndex]);

            return gson.toJson(response);

        } catch (Exception e) {
            return createErrorResponse("Failed to start listening: " + e.getMessage());
        }
    }

    /**
     * Stops listening for cards.
     * 
     * @return JSON response
     */
    public String handleStopListening() {
        stopListening();

        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Stopped listening");

        return gson.toJson(response);
    }

    /**
     * Gets the current status of the card reader.
     * 
     * @return JSON response with status
     */
    public String handleGetStatus() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("listening", isListening);

        if (activeCardReader != null) {
            try {
                response.put("cardPresent", activeCardReader.isCardPresent());
            } catch (Exception e) {
                response.put("cardPresent", false);
            }
        } else {
            response.put("cardPresent", false);
        }

        return gson.toJson(response);
    }

    /**
     * Stops the listening thread and cleans up resources.
     */
    private void stopListening() {
        isListening = false;

        if (listeningThread != null) {
            listeningThread.interrupt();
            try {
                listeningThread.join(1000);
            } catch (InterruptedException e) {
                // Ignore
            }
            listeningThread = null;
        }

        activeCardReader = null;
    }

    /**
     * Sends a card detected event to the browser extension.
     * 
     * @param uid Card UID
     */
    private void sendCardDetectedEvent(String uid) {
        Map<String, Object> event = new HashMap<>();
        event.put("event", "card-detected");
        event.put("uid", uid);
        event.put("uidType", CardReader.getUIDType(uid));

        String eventJson = gson.toJson(event);
        NativeMessagingHost.sendMessage(eventJson);
    }

    /**
     * Sends an error event to the browser extension.
     * 
     * @param error Error message
     */
    private void sendErrorEvent(String error) {
        Map<String, Object> event = new HashMap<>();
        event.put("event", "error");
        event.put("error", error);

        String eventJson = gson.toJson(event);
        NativeMessagingHost.sendMessage(eventJson);
    }

    /**
     * Creates a JSON error response.
     * 
     * @param errorMessage Error message
     * @return JSON error response
     */
    private String createErrorResponse(String errorMessage) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("error", errorMessage);

        return gson.toJson(response);
    }

    /**
     * Cleanup method to be called on shutdown.
     */
    public void cleanup() {
        stopListening();
    }
}
