/**
 * Native Messaging Handler
 * Manages communication with the native host application
 */

const NATIVE_HOST_NAME = "info.nfcreader.host";

class NativeMessaging {
  constructor() {
    this.port = null;
    this.isConnected = false;
    this.listeners = new Map();
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 3;
    this.hostNotInstalled = false;
  }

  /**
   * Connects to the native messaging host
   * @param {boolean} isRetry - Whether this is a reconnection attempt
   */
  connect(isRetry = false) {
    if (this.isConnected) {
      console.log("Already connected to native host");
      return;
    }

    // Only reset attempts if this is a fresh connection request (not a retry)
    if (!isRetry) {
      this.reconnectAttempts = 0;
    }

    try {
      console.log("Connecting to native host:", NATIVE_HOST_NAME);
      this.port = chrome.runtime.connectNative(NATIVE_HOST_NAME);

      this.port.onMessage.addListener((message) => {
        this.handleMessage(message);
      });

      this.port.onDisconnect.addListener(() => {
        this.handleDisconnect();
      });

      this.isConnected = true;
      this.hostNotInstalled = false;
      console.log("Connected to native host");

      // Reset reconnect attempts after 5 seconds of stable connection
      if (this.connectionStableTimer) {
        clearTimeout(this.connectionStableTimer);
      }
      this.connectionStableTimer = setTimeout(() => {
        if (this.isConnected) {
          this.reconnectAttempts = 0;
        }
      }, 5000);

      this.emit("connected");
    } catch (error) {
      console.error("Failed to connect to native host:", error);
      this.isConnected = false;
      this.hostNotInstalled = true;
      this.emit("error", {
        error: "Failed to connect to native host",
        notInstalled: true,
      });
    }
  }

  /**
   * Disconnects from the native messaging host
   */
  disconnect() {
    if (this.connectionStableTimer) {
      clearTimeout(this.connectionStableTimer);
      this.connectionStableTimer = null;
    }
    if (this.port) {
      this.port.disconnect();
      this.port = null;
    }
    this.isConnected = false;
    this.emit("disconnected");
  }

  /**
   * Sends a message to the native host
   */
  sendMessage(message) {
    if (!this.isConnected || !this.port) {
      console.error("Not connected to native host");
      this.emit("error", {
        error:
          "Not connected to native host. Please install the native host application.",
        notInstalled: this.hostNotInstalled,
      });
      return;
    }

    try {
      this.port.postMessage(message);
    } catch (error) {
      console.error("Error sending message to native host:", error);
      this.emit("error", { error: "Error communicating with native host" });
    }
  }

  /**
   * Handles messages from the native host
   */
  handleMessage(message) {
    console.log("Message from native host:", message);

    if (message.event) {
      // Event from native host (card-detected, error, etc.)
      this.emit(message.event, message);
    } else {
      // Response to a command
      this.emit("response", message);
    }
  }

  /**
   * Handles disconnection from the native host
   */
  handleDisconnect() {
    console.log("Disconnected from native host");

    if (this.connectionStableTimer) {
      clearTimeout(this.connectionStableTimer);
      this.connectionStableTimer = null;
    }

    const error = chrome.runtime.lastError;
    if (error) {
      console.error("Native host disconnect error:", error.message);

      // Check if host is not installed
      if (
        error.message.includes("native messaging host") ||
        error.message.includes("not found") ||
        error.message.includes("Specified native messaging host not found")
      ) {
        this.hostNotInstalled = true;
        this.emit("error", {
          error:
            "Native messaging host not installed. Please install the host application first.",
          notInstalled: true,
        });
      } else {
        this.emit("error", { error: error.message });
      }
    }

    this.isConnected = false;
    this.port = null;
    this.emit("disconnected");

    // Only attempt to reconnect if host is installed but connection failed
    if (
      !this.hostNotInstalled &&
      this.reconnectAttempts < this.maxReconnectAttempts
    ) {
      this.reconnectAttempts++;
      console.log(
        `Reconnect attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts}`
      );
      setTimeout(() => this.connect(true), 2000);
    } else if (this.hostNotInstalled) {
      console.log("Host not installed, skipping reconnection attempts");
    }
  }

  /**
   * Adds an event listener
   */
  on(event, callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event).push(callback);
  }

  /**
   * Removes an event listener
   */
  off(event, callback) {
    if (!this.listeners.has(event)) return;

    const callbacks = this.listeners.get(event);
    const index = callbacks.indexOf(callback);
    if (index > -1) {
      callbacks.splice(index, 1);
    }
  }

  /**
   * Emits an event to all listeners
   */
  emit(event, data) {
    if (!this.listeners.has(event)) return;

    const callbacks = this.listeners.get(event);
    callbacks.forEach((callback) => callback(data));
  }
}

// Export for use in background script
export default NativeMessaging;
