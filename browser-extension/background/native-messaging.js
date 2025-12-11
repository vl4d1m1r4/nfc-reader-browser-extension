/**
 * Native Messaging Handler
 * Manages communication with the native host application
 */

const NATIVE_HOST_NAME = 'com.nfcreader.host';

class NativeMessaging {
  constructor() {
    this.port = null;
    this.isConnected = false;
    this.listeners = new Map();
    this.reconnectAttempts = 0;
    this.maxReconnectAttempts = 3;
  }

  /**
   * Connects to the native messaging host
   */
  connect() {
    if (this.isConnected) {
      console.log('Already connected to native host');
      return;
    }

    try {
      console.log('Connecting to native host:', NATIVE_HOST_NAME);
      this.port = chrome.runtime.connectNative(NATIVE_HOST_NAME);
      
      this.port.onMessage.addListener((message) => {
        this.handleMessage(message);
      });

      this.port.onDisconnect.addListener(() => {
        this.handleDisconnect();
      });

      this.isConnected = true;
      this.reconnectAttempts = 0;
      console.log('Connected to native host');
      
      this.emit('connected');
      
    } catch (error) {
      console.error('Failed to connect to native host:', error);
      this.isConnected = false;
      this.emit('error', { error: 'Failed to connect to native host' });
    }
  }

  /**
   * Disconnects from the native messaging host
   */
  disconnect() {
    if (this.port) {
      this.port.disconnect();
      this.port = null;
    }
    this.isConnected = false;
  }

  /**
   * Sends a message to the native host
   */
  sendMessage(message) {
    if (!this.isConnected || !this.port) {
      console.error('Not connected to native host');
      this.emit('error', { error: 'Not connected to native host. Please install the native host application.' });
      return;
    }

    try {
      this.port.postMessage(message);
    } catch (error) {
      console.error('Error sending message to native host:', error);
      this.emit('error', { error: 'Error communicating with native host' });
    }
  }

  /**
   * Handles messages from the native host
   */
  handleMessage(message) {
    console.log('Message from native host:', message);

    if (message.event) {
      // Event from native host (card-detected, error, etc.)
      this.emit(message.event, message);
    } else {
      // Response to a command
      this.emit('response', message);
    }
  }

  /**
   * Handles disconnection from the native host
   */
  handleDisconnect() {
    console.log('Disconnected from native host');
    
    const error = chrome.runtime.lastError;
    if (error) {
      console.error('Native host disconnect error:', error.message);
      
      // Check if host is not installed
      if (error.message.includes('native messaging host') || 
          error.message.includes('not found') ||
          error.message.includes('Specified native messaging host not found')) {
        this.emit('error', { 
          error: 'Native messaging host not installed. Please install the host application first.',
          notInstalled: true
        });
      } else {
        this.emit('error', { error: error.message });
      }
    }

    this.isConnected = false;
    this.port = null;
    this.emit('disconnected');

    // Attempt to reconnect
    if (this.reconnectAttempts < this.maxReconnectAttempts) {
      this.reconnectAttempts++;
      console.log(`Reconnect attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts}`);
      setTimeout(() => this.connect(), 2000);
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
    callbacks.forEach(callback => callback(data));
  }
}

// Export for use in background script
export default NativeMessaging;
