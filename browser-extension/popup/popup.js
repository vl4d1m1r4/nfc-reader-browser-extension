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
  uidFormat: "spaced",
  nativeHostVersion: null,
  versionMismatch: false,
};

// DOM elements
const statusIndicator = document.getElementById("statusIndicator");
const statusText = document.getElementById("statusText");
const errorSection = document.getElementById("errorSection");
const errorMessage = document.getElementById("errorMessage");
const installNotice = document.getElementById("installNotice");
const versionWarning = document.getElementById("versionWarning");
const extensionVersion = document.getElementById("extensionVersion");
const nativeHostVersion = document.getElementById("nativeHostVersion");
const readerSelect = document.getElementById("readerSelect");
const refreshBtn = document.getElementById("refreshBtn");
const toggleBtn = document.getElementById("toggleBtn");
const uidSection = document.getElementById("uidSection");
const uidValue = document.getElementById("uidValue");
const uidType = document.getElementById("uidType");
const formatSelect = document.getElementById("formatSelect");

/**
 * Initialize popup
 */
async function initialize() {
  console.log("Initializing popup");
  console.log("Install notice element:", installNotice);

  // Set up event listeners first
  setupEventListeners();

  // Load saved format preference
  chrome.storage.local.get(["uidFormat"], (result) => {
    if (result.uidFormat) {
      currentState.uidFormat = result.uidFormat;
      if (formatSelect) formatSelect.value = result.uidFormat;
    } else {
      // Set default to spaced if no preference saved
      if (formatSelect) formatSelect.value = "spaced";
    }
  });

  // Get current state from background
  try {
    chrome.runtime.sendMessage({ action: "get-state" }, (response) => {
      if (chrome.runtime.lastError) {
        console.error("Error getting state:", chrome.runtime.lastError);
        return;
      }
      console.log("Received state from background:", response);
      if (response && response.state) {
        updateState(response.state);
      }
    });
  } catch (error) {
    console.error("Failed to send get-state message:", error);
  }
}

/**
 * Set up event listeners
 */
function setupEventListeners() {
  // Listen for state updates from background
  chrome.runtime.onMessage.addListener((message) => {
    if (message.action === "state-update") {
      updateState(message.state);
    }
  });

  // Reader selection change
  readerSelect.addEventListener("change", () => {
    currentState.selectedReaderIndex = parseInt(readerSelect.value);
  });

  // Refresh readers button
  refreshBtn.addEventListener("click", () => {
    chrome.runtime.sendMessage({ action: "list-readers" });
  });

  // Toggle listening button
  toggleBtn.addEventListener("click", () => {
    if (currentState.isListening) {
      stopListening();
    } else {
      startListening();
    }
  });

  // Format selection change
  formatSelect.addEventListener("change", () => {
    currentState.uidFormat = formatSelect.value;
    // Save preference
    chrome.storage.local.set({ uidFormat: formatSelect.value });
    // Notify background script
    chrome.runtime.sendMessage({
      action: "set-format",
      format: formatSelect.value,
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
  console.log("Updating state:", state);
  currentState = state;

  // Update status indicator
  updateStatusIndicator();

  // Update version warning
  if (state.versionMismatch && state.nativeHostVersion) {
    showVersionWarning(
      chrome.runtime.getManifest().version,
      state.nativeHostVersion
    );
  } else {
    hideVersionWarning();
  }

  // Update error display and install notice
  if (state.error) {
    console.log(
      "Error detected:",
      state.error,
      "notInstalled:",
      state.notInstalled
    );
    // Check if this is a "not installed" error
    if (state.notInstalled) {
      console.log("Showing install notice");
      // Only show install notice, hide error
      hideError();
      showInstallNotice();
      // Disable all controls when host is not installed
      readerSelect.disabled = true;
      refreshBtn.disabled = true;
      toggleBtn.disabled = true;
    } else {
      console.log("Showing error message");
      // Show error for other issues, hide install notice
      showError(state.error);
      hideInstallNotice();
    }
  } else {
    hideError();
    hideInstallNotice();
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
    toggleBtn.textContent = "Stop Listening";
    toggleBtn.classList.add("stop");
    // Hide stop button if only one reader
    if (state.readers && state.readers.length === 1) {
      toggleBtn.style.display = "none";
    } else {
      toggleBtn.style.display = "";
    }
  } else {
    toggleBtn.textContent = "Start Listening";
    toggleBtn.classList.remove("stop");
    toggleBtn.style.display = "";
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
    statusIndicator.className = "status-indicator error";
    statusText.textContent = "Error";
  } else if (currentState.isListening) {
    statusIndicator.className = "status-indicator listening";
    statusText.textContent = "Listening for cards...";
  } else if (currentState.readers.length > 0) {
    statusIndicator.className = "status-indicator connected";
    statusText.textContent = "Connected";
  } else {
    statusIndicator.className = "status-indicator";
    statusText.textContent = "Connecting...";
  }
}

/**
 * Updates the reader dropdown list
 */
function updateReaderList(readers) {
  readerSelect.innerHTML = "";

  readers.forEach((reader, index) => {
    const option = document.createElement("option");
    option.value = index;
    option.textContent = reader;
    readerSelect.appendChild(option);
  });

  // Select the previously selected reader
  if (
    currentState.selectedReaderIndex >= 0 &&
    currentState.selectedReaderIndex < readers.length
  ) {
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
  errorSection.style.display = "block";
}

/**
 * Hides the error message
 */
function hideError() {
  errorSection.style.display = "none";
}

/**
 * Shows the installation notice
 */
function showInstallNotice() {
  console.log("showInstallNotice called, setting display to flex");
  if (installNotice) {
    installNotice.style.display = "flex";
    console.log("Install notice display:", installNotice.style.display);
  } else {
    console.error("Install notice element not found!");
  }
}

/**
 * Hides the installation notice
 */
function hideInstallNotice() {
  console.log("hideInstallNotice called");
  if (installNotice) {
    installNotice.style.display = "none";
  }
}

/**
 * Shows the version warning
 */
function showVersionWarning(extVersion, hostVersion) {
  if (versionWarning && extensionVersion && nativeHostVersion) {
    extensionVersion.textContent = "v" + extVersion;
    nativeHostVersion.textContent = "v" + hostVersion;
    versionWarning.style.display = "block";
  }
}

/**
 * Hides the version warning
 */
function hideVersionWarning() {
  if (versionWarning) {
    versionWarning.style.display = "none";
  }
}

/**
 * Shows the UID display
 */
function showUID(uid) {
  uidValue.textContent = formatUID(uid, currentState.uidFormat);

  // Determine UID type
  const byteLength = uid.length / 2;
  let type = "";
  switch (byteLength) {
    case 4:
      type = "Single size (4 bytes)";
      break;
    case 7:
      type = "Double size (7 bytes)";
      break;
    case 10:
      type = "Triple size (10 bytes)";
      break;
    default:
      type = `${byteLength} bytes`;
  }
  uidType.textContent = type;

  uidSection.style.display = "block";
}

/**
 * Starts listening for NFC cards
 */
function startListening() {
  const readerIndex = parseInt(readerSelect.value);

  if (readerIndex < 0 || isNaN(readerIndex)) {
    showError("Please select a reader");
    return;
  }

  chrome.runtime.sendMessage({
    action: "start-listening",
    readerIndex: readerIndex,
  });
}

/**
 * Stops listening for NFC cards
 */
function stopListening() {
  chrome.runtime.sendMessage({ action: "stop-listening" });
}

/**
 * Formats a UID according to the specified format
 */
function formatUID(uid, format) {
  if (!uid) return uid;

  // Convert to uppercase hex string without separators
  const cleanUID = uid.replace(/[^0-9A-Fa-f]/g, "").toUpperCase();

  switch (format) {
    case "spaced":
      return cleanUID.match(/.{1,2}/g).join(" ");
    case "colon":
      return cleanUID.match(/.{1,2}/g).join(":");
    case "dash":
      return cleanUID.match(/.{1,2}/g).join("-");
    case "plain":
    default:
      return cleanUID;
  }
}

// Initialize when popup opens
document.addEventListener("DOMContentLoaded", initialize);
