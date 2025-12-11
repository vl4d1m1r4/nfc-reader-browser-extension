/**
 * Background Service Worker
 * Manages native messaging connection and coordinates between popup and content scripts
 */

// Import native messaging handler (for module-based service worker)
import NativeMessaging from './native-messaging.js';

const nativeMessaging = new NativeMessaging();
let currentState = {
  readers: [],
  selectedReaderIndex: -1,
  isListening: false,
  lastUID: null,
  error: null,
  uidFormat: 'plain'
};

// Initialize on install
chrome.runtime.onInstalled.addListener(() => {
  console.log('NFC Reader extension installed');
  
  // Load saved preferences
  chrome.storage.local.get(['selectedReaderIndex', 'uidFormat'], (result) => {
    if (result.selectedReaderIndex !== undefined) {
      currentState.selectedReaderIndex = result.selectedReaderIndex;
    }
    if (result.uidFormat) {
      currentState.uidFormat = result.uidFormat;
    }
  });
});

// Set up native messaging event handlers
nativeMessaging.on('connected', () => {
  console.log('Native host connected');
  currentState.error = null;
  broadcastStateUpdate();
});

nativeMessaging.on('disconnected', () => {
  console.log('Native host disconnected');
  currentState.isListening = false;
  broadcastStateUpdate();
});

nativeMessaging.on('error', (data) => {
  console.error('Native host error:', data.error);
  currentState.error = data.error;
  currentState.isListening = false;
  broadcastStateUpdate();
});

nativeMessaging.on('response', (response) => {
  console.log('Response from native host:', response);
  handleNativeResponse(response);
});

nativeMessaging.on('card-detected', (data) => {
  console.log('Card detected:', data.uid);
  currentState.lastUID = data.uid;
  
  // Send UID to active tab's content script with format
  chrome.tabs.query({ active: true, currentWindow: true }, (tabs) => {
    if (tabs[0]) {
      chrome.tabs.sendMessage(tabs[0].id, {
        action: 'fill-uid',
        uid: data.uid,
        uidType: data.uidType,
        format: currentState.uidFormat
      }).catch(err => {
        console.log('Could not send UID to content script:', err);
      });
    }
  });
  
  broadcastStateUpdate();
});

/**
 * Handles responses from native host
 */
function handleNativeResponse(response) {
  if (response.success) {
    if (response.readers) {
      currentState.readers = response.readers;
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
  chrome.runtime.sendMessage({
    action: 'state-update',
    state: currentState
  }).catch(() => {
    // Popup might not be open, ignore error
  });
}

/**
 * Handles messages from popup and content scripts
 */
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  console.log('Message received:', message);
  
  switch (message.action) {
    case 'connect':
      nativeMessaging.connect();
      sendResponse({ success: true });
      break;
      
    case 'disconnect':
      nativeMessaging.disconnect();
      sendResponse({ success: true });
      break;
      
    case 'list-readers':
      nativeMessaging.sendMessage({ action: 'list-readers' });
      sendResponse({ success: true });
      break;
      
    case 'start-listening':
      if (message.readerIndex !== undefined) {
        currentState.selectedReaderIndex = message.readerIndex;
        currentState.isListening = true;
        
        // Save preference
        chrome.storage.local.set({ 
          selectedReaderIndex: message.readerIndex 
        });
        
        nativeMessaging.sendMessage({
          action: 'start-listening',
          readerIndex: message.readerIndex
        });
      }
      sendResponse({ success: true });
      break;
      
    case 'stop-listening':
      currentState.isListening = false;
      nativeMessaging.sendMessage({ action: 'stop-listening' });
      sendResponse({ success: true });
      break;
      
    case 'set-format':
      if (message.format) {
        currentState.uidFormat = message.format;
        chrome.storage.local.set({ uidFormat: message.format });
      }
      sendResponse({ success: true });
      break;
      
    case 'get-state':
      sendResponse({ state: currentState });
      break;
      
    default:
      sendResponse({ success: false, error: 'Unknown action' });
  }
  
  return true; // Keep message channel open for async response
});

// Auto-connect on startup
nativeMessaging.connect();

console.log('NFC Reader background script loaded');
