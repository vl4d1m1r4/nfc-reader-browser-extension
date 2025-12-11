/**
 * Popup Script
 * Handles the extension popup UI and user interactions
 */

let currentState = {
  readers: [],
  selectedReaderIndex: -1,
  isListening: false,
  lastUID: null,
  error: null,
  uidFormat: 'plain'
};

// DOM elements
const statusIndicator = document.getElementById('statusIndicator');
const statusText = document.getElementById('statusText');
const errorSection = document.getElementById('errorSection');
const errorMessage = document.getElementById('errorMessage');
const readerSelect = document.getElementById('readerSelect');
const refreshBtn = document.getElementById('refreshBtn');
const toggleBtn = document.getElementById('toggleBtn');
const uidSection = document.getElementById('uidSection');
const uidValue = document.getElementById('uidValue');
const uidType = document.getElementById('uidType');
const formatSelect = document.getElementById('formatSelect');

/**
 * Initialize popup
 */
async function initialize() {
  console.log('Initializing popup');
  
  // Load saved format preference
  chrome.storage.local.get(['uidFormat'], (result) => {
    if (result.uidFormat) {
      currentState.uidFormat = result.uidFormat;
      formatSelect.value = result.uidFormat;
    }
  });
  
  // Get current state from background
  chrome.runtime.sendMessage({ action: 'get-state' }, (response) => {
    if (response && response.state) {
      updateState(response.state);
    }
  });
  
  // Request reader list
  chrome.runtime.sendMessage({ action: 'list-readers' });
  
  // Set up event listeners
  setupEventListeners();
}

/**
 * Set up event listeners
 */
function setupEventListeners() {
  // Listen for state updates from background
  chrome.runtime.onMessage.addListener((message) => {
    if (message.action === 'state-update') {
      updateState(message.state);
    }
  });
  
  // Reader selection change
  readerSelect.addEventListener('change', () => {
    currentState.selectedReaderIndex = parseInt(readerSelect.value);
  });
  
  // Refresh readers button
  refreshBtn.addEventListener('click', () => {
    chrome.runtime.sendMessage({ action: 'list-readers' });
  });
  
  // Toggle listening button
  toggleBtn.addEventListener('click', () => {
    if (currentState.isListening) {
      stopListening();
    } else {
      startListening();
    }
  });
  
  // Format selection change
  formatSelect.addEventListener('change', () => {
    currentState.uidFormat = formatSelect.value;
    // Save preference
    chrome.storage.local.set({ uidFormat: formatSelect.value });
    // Notify background script
    chrome.runtime.sendMessage({ 
      action: 'set-format', 
      format: formatSelect.value 
    });
    // Update displayed UID if present
    if (currentState.lastUID) {
      showUID(currentState.lastUID);
    }
  });
}

/**
 * Updates the UI state
 */
function updateState(state) {
  currentState = state;
  
  // Update status indicator
  updateStatusIndicator();
  
  // Update error display
  if (state.error) {
    showError(state.error);
  } else {
    hideError();
  }
  
  // Update reader list
  if (state.readers && state.readers.length > 0) {
    updateReaderList(state.readers);
    readerSelect.disabled = state.isListening;
    refreshBtn.disabled = state.isListening;
    toggleBtn.disabled = false;
  } else {
    readerSelect.innerHTML = '<option value="">No readers found</option>';
    readerSelect.disabled = true;
    refreshBtn.disabled = false;
    toggleBtn.disabled = true;
  }
  
  // Update toggle button
  if (state.isListening) {
    toggleBtn.textContent = 'Stop Listening';
    toggleBtn.classList.add('stop');
  } else {
    toggleBtn.textContent = 'Start Listening';
    toggleBtn.classList.remove('stop');
  }
  
  // Update UID display
  if (state.lastUID) {
    showUID(state.lastUID);
  }
}

/**
 * Updates the status indicator
 */
function updateStatusIndicator() {
  if (currentState.error) {
    statusIndicator.className = 'status-indicator error';
    statusText.textContent = 'Error';
  } else if (currentState.isListening) {
    statusIndicator.className = 'status-indicator listening';
    statusText.textContent = 'Listening for cards...';
  } else if (currentState.readers.length > 0) {
    statusIndicator.className = 'status-indicator connected';
    statusText.textContent = 'Connected';
  } else {
    statusIndicator.className = 'status-indicator';
    statusText.textContent = 'Connecting...';
  }
}

/**
 * Updates the reader dropdown list
 */
function updateReaderList(readers) {
  readerSelect.innerHTML = '';
  
  readers.forEach((reader, index) => {
    const option = document.createElement('option');
    option.value = index;
    option.textContent = reader;
    readerSelect.appendChild(option);
  });
  
  // Select the previously selected reader
  if (currentState.selectedReaderIndex >= 0 && 
      currentState.selectedReaderIndex < readers.length) {
    readerSelect.value = currentState.selectedReaderIndex;
  } else {
    readerSelect.selectedIndex = 0;
    currentState.selectedReaderIndex = 0;
  }
}

/**
 * Shows an error message
 */
function showError(error) {
  errorMessage.textContent = error;
  errorSection.style.display = 'block';
}

/**
 * Hides the error message
 */
function hideError() {
  errorSection.style.display = 'none';
}

/**
 * Shows the UID display
 */
function showUID(uid) {
  uidValue.textContent = formatUID(uid, currentState.uidFormat);
  
  // Determine UID type
  const byteLength = uid.length / 2;
  let type = '';
  switch (byteLength) {
    case 4: type = 'Single size (4 bytes)'; break;
    case 7: type = 'Double size (7 bytes)'; break;
    case 10: type = 'Triple size (10 bytes)'; break;
    default: type = `${byteLength} bytes`;
  }
  uidType.textContent = type;
  
  uidSection.style.display = 'block';
}

/**
 * Starts listening for NFC cards
 */
function startListening() {
  const readerIndex = parseInt(readerSelect.value);
  
  if (readerIndex < 0 || isNaN(readerIndex)) {
    showError('Please select a reader');
    return;
  }
  
  chrome.runtime.sendMessage({
    action: 'start-listening',
    readerIndex: readerIndex
  });
}

/**
 * Stops listening for NFC cards
 */
function stopListening() {
  chrome.runtime.sendMessage({ action: 'stop-listening' });
}

/**
 * Formats a UID according to the specified format
 */
function formatUID(uid, format) {
  if (!uid) return uid;
  
  // Convert to uppercase hex string without separators
  const cleanUID = uid.replace(/[^0-9A-Fa-f]/g, '').toUpperCase();
  
  switch (format) {
    case 'spaced':
      return cleanUID.match(/.{1,2}/g).join(' ');
    case 'colon':
      return cleanUID.match(/.{1,2}/g).join(':');
    case 'dash':
      return cleanUID.match(/.{1,2}/g).join('-');
    case 'plain':
    default:
      return cleanUID;
  }
}

// Initialize when popup opens
document.addEventListener('DOMContentLoaded', initialize);
