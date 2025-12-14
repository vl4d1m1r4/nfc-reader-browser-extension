/**
 * Background Service Worker
 * Manages native messaging connection and coordinates between popup and content scripts
 */

// Import native messaging handler (for module-based service worker)
import NativeMessaging from "./native-messaging.js";

const nativeMessaging = new NativeMessaging();

// Extension version from manifest
const EXTENSION_VERSION = chrome.runtime.getManifest().version;

let currentState = {
  readers: [],
  selectedReaderIndex: -1,
  isListening: false,
  lastUID: null,
  error: null,
  notInstalled: false,
  uidFormat: "spaced",
  nativeHostVersion: null,
  versionMismatch: false,
};

/**
 * Load saved preferences from storage
 */
function loadPreferences() {
  chrome.storage.local.get(["selectedReaderIndex", "uidFormat"], (result) => {
    if (result.selectedReaderIndex !== undefined) {
      currentState.selectedReaderIndex = result.selectedReaderIndex;
    }
    if (result.uidFormat) {
      currentState.uidFormat = result.uidFormat;
    }
    // Check if we can auto-start now that preferences are loaded
    checkAutoStart();
  });
}

/**
 * Checks if listening should be auto-started based on available readers and preferences
 */
function checkAutoStart() {
  console.log(
    "Checking auto-start. Readers:",
    currentState.readers.length,
    "Selected:",
    currentState.selectedReaderIndex,
    "Listening:",
    currentState.isListening
  );

  if (currentState.isListening) return;
  if (currentState.readers.length === 0) return;

  // If we have a selected reader index and it's valid
  if (
    currentState.selectedReaderIndex >= 0 &&
    currentState.selectedReaderIndex < currentState.readers.length
  ) {
    console.log(
      "Starting listening on selected reader:",
      currentState.selectedReaderIndex
    );
    currentState.isListening = true;
    nativeMessaging.sendMessage({
      action: "start-listening",
      readerIndex: currentState.selectedReaderIndex,
    });
  }
  // Auto-start listening when exactly one reader is detected (and no specific selection or selection is invalid)
  else if (currentState.readers.length === 1) {
    console.log("Single reader detected, auto-starting listening");
    currentState.selectedReaderIndex = 0;
    currentState.isListening = true;
    nativeMessaging.sendMessage({
      action: "start-listening",
      readerIndex: 0,
    });
  }
}

// Initialize on install
chrome.runtime.onInstalled.addListener(() => {
  console.log("NFC Reader extension installed");
  loadPreferences();
});

// Initialize on browser startup
chrome.runtime.onStartup.addListener(() => {
  console.log("NFC Reader extension started");
  loadPreferences();
  // Ensure connection is established
  if (!nativeMessaging.isConnected) {
    nativeMessaging.connect();
  }
});

// Ensure connection on various browser events to handle cases where onStartup doesn't fire
// (e.g. "Continue where you left off" setting)
function ensureConnection() {
  if (!nativeMessaging.isConnected) {
    console.log("Ensuring connection to native host...");
    nativeMessaging.connect();
  }
}

chrome.tabs.onActivated.addListener(ensureConnection);
chrome.windows.onFocusChanged.addListener(ensureConnection);
chrome.tabs.onCreated.addListener(ensureConnection);

// Load preferences immediately when script loads
loadPreferences();

// Set up native messaging event handlers
nativeMessaging.on("connected", () => {
  console.log("Native host connected");
  currentState.error = null;
  currentState.notInstalled = false;
  currentState.isListening = false; // Ensure we start with a clean state
  lastError = null; // Clear error tracking on new connection
  errorCount = 0;

  // Check version first
  nativeMessaging.sendMessage({ action: "get-version" });

  // Request reader list on connection
  nativeMessaging.sendMessage({ action: "list-readers" });

  broadcastStateUpdate();
});

nativeMessaging.on("disconnected", () => {
  console.log("Native host disconnected");
  currentState.isListening = false;
  broadcastStateUpdate();
});

let lastError = null;
let errorCount = 0;

nativeMessaging.on("error", (data) => {
  // Suppress duplicate consecutive errors (but allow first 2 occurrences)
  if (lastError === data.error) {
    errorCount++;
    if (errorCount > 2) {
      // Suppress logging but still update state for first error in a sequence
      currentState.error = data.error;
      currentState.notInstalled = data.notInstalled || false;
      return; // Skip logging and broadcasting for excessive duplicates
    }
  } else {
    lastError = data.error;
    errorCount = 1;
  }

  console.error("Native host error:", data.error);
  currentState.error = data.error;
  currentState.notInstalled = data.notInstalled || false;

  // Store previous listening state for auto-restart
  const wasListening = currentState.isListening;
  const previousReaderIndex = currentState.selectedReaderIndex;

  currentState.isListening = false;

  // Send stop-listening to clean up Java side
  if (wasListening) {
    nativeMessaging.sendMessage({ action: "stop-listening" });
  }

  broadcastStateUpdate();

  // If reader disconnected during listening with single reader, try to restart when available
  if (
    wasListening &&
    currentState.readers.length === 1 &&
    !currentState.notInstalled
  ) {
    console.log(
      "Reader disconnected during listening, will auto-restart when available"
    );
    // Poll for reader reconnection
    const pollInterval = setInterval(() => {
      nativeMessaging.sendMessage({ action: "list-readers" });

      // Check if reader is back after a short delay
      setTimeout(() => {
        if (currentState.readers.length === 1 && !currentState.isListening) {
          console.log("Reader reconnected, restarting listening");
          currentState.selectedReaderIndex = 0;
          currentState.isListening = true;
          lastError = null; // Clear error tracking
          errorCount = 0;
          nativeMessaging.sendMessage({
            action: "start-listening",
            readerIndex: 0,
          });
          clearInterval(pollInterval);
        }
      }, 200);
    }, 2000);

    // Stop polling after 30 seconds
    setTimeout(() => clearInterval(pollInterval), 30000);
  }
});

nativeMessaging.on("response", (response) => {
  console.log("Response from native host:", response);
  handleNativeResponse(response);
});

nativeMessaging.on("card-detected", (data) => {
  console.log("Card detected:", data.uid);
  currentState.lastUID = data.uid;

  // Send UID to active tab's content script with format
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    if (tabs[0]) {
      chrome.tabs
        .sendMessage(tabs[0].id, {
          action: "fill-uid",
          uid: data.uid,
          uidType: data.uidType,
          format: currentState.uidFormat,
        })
        .catch((err) => {
          console.log("Could not send UID to content script:", err);
        });
    }
  });

  broadcastStateUpdate();
});

/**
 * Handles responses from native host
 */
function handleNativeResponse(response) {
  // Handle version response
  if (response.version !== undefined) {
    currentState.nativeHostVersion = response.version;
    currentState.versionMismatch = response.version !== EXTENSION_VERSION;

    if (currentState.versionMismatch) {
      console.warn(
        `Version mismatch: Extension v${EXTENSION_VERSION}, Native Host v${response.version}`
      );
    }

    broadcastStateUpdate();
    return;
  }

  if (response.success) {
    if (response.readers) {
      currentState.readers = response.readers;

      // Check if we should auto-start listening
      checkAutoStart();

      // Stop listening when no readers available
      if (currentState.readers.length === 0 && currentState.isListening) {
        console.log("No readers detected, stopping listening");
        currentState.isListening = false;
        nativeMessaging.sendMessage({ action: "stop-listening" });
      }

      // Clear error when we successfully get reader list
      if (currentState.readers.length > 0) {
        currentState.error = null;
      }
    }
    if (response.message) {
      console.log(response.message);
    }
    currentState.error = null;
  } else if (response.error) {
    currentState.error = response.error;
  }

  broadcastStateUpdate();
}

/**
 * Broadcasts state updates to popup
 */
function broadcastStateUpdate() {
  chrome.runtime
    .sendMessage({
      action: "state-update",
      state: currentState,
    })
    .catch(() => {
      // Popup might not be open, ignore error
    });
}

/**
 * Handles messages from popup and content scripts
 */
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log("Message received:", message);

  switch (message.action) {
    case "connect":
      nativeMessaging.connect();
      sendResponse({ success: true });
      break;

    case "disconnect":
      nativeMessaging.disconnect();
      sendResponse({ success: true });
      break;

    case "list-readers":
      nativeMessaging.sendMessage({ action: "list-readers" });
      sendResponse({ success: true });
      break;

    case "start-listening":
      if (message.readerIndex !== undefined) {
        currentState.selectedReaderIndex = message.readerIndex;
        currentState.isListening = true;

        // Save preference
        chrome.storage.local.set({
          selectedReaderIndex: message.readerIndex,
        });

        nativeMessaging.sendMessage({
          action: "start-listening",
          readerIndex: message.readerIndex,
        });
      }
      sendResponse({ success: true });
      break;

    case "stop-listening":
      currentState.isListening = false;
      nativeMessaging.sendMessage({ action: "stop-listening" });
      sendResponse({ success: true });
      break;

    case "set-format":
      if (message.format) {
        currentState.uidFormat = message.format;
        chrome.storage.local.set({ uidFormat: message.format });
      }
      sendResponse({ success: true });
      break;

    case "get-state":
      sendResponse({ state: currentState });
      break;

    default:
      sendResponse({ success: false, error: "Unknown action" });
  }

  return true; // Keep message channel open for async response
});

// Cleanup when extension is suspended or browser closes
chrome.runtime.onSuspend.addListener(() => {
  console.log("Extension suspending - cleaning up");

  // Stop listening if currently active
  if (currentState.isListening) {
    nativeMessaging.sendMessage({ action: "stop-listening" });
    currentState.isListening = false;
  }

  // Disconnect from native host
  nativeMessaging.disconnect();
});

// Auto-connect on startup
nativeMessaging.connect();

console.log("NFC Reader background script loaded");
