/**
 * Content Script
 * Runs on all web pages and handles auto-filling input fields with NFC card UIDs
 */

// Listen for messages from background script
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.action === 'fill-uid') {
    fillUID(message.uid, message.uidType, message.format || 'plain');
    sendResponse({ success: true });
  }
  return true;
});

/**
 * Fills the currently focused input field with the UID
 */
function fillUID(uid, uidType, format) {
  const activeElement = document.activeElement;
  
  // Format the UID according to user preference
  const formattedUID = formatUID(uid, format);
  
  // Check if the active element is an input field
  if (activeElement && 
      (activeElement.tagName === 'INPUT' || activeElement.tagName === 'TEXTAREA')) {
    
    // Check if it's a text-like input
    const inputType = activeElement.type ? activeElement.type.toLowerCase() : 'text';
    const validTypes = ['text', 'search', 'tel', 'url', 'email', 'number'];
    
    if (activeElement.tagName === 'TEXTAREA' || validTypes.includes(inputType)) {
      // Set the value
      activeElement.value = formattedUID;
      
      // Trigger input events to ensure the page detects the change
      activeElement.dispatchEvent(new Event('input', { bubbles: true }));
      activeElement.dispatchEvent(new Event('change', { bubbles: true }));
      
      // Show visual feedback
      showNotification(`Card UID filled: ${formattedUID}`);
      
      // Add temporary highlight to the field
      highlightField(activeElement);
    } else {
      showNotification('Please focus on a text input field', 'warning');
    }
  } else {
    showNotification('Please focus on an input field first', 'warning');
  }
}

/**
 * Highlights the input field briefly
 */
function highlightField(element) {
  const originalOutline = element.style.outline;
  const originalTransition = element.style.transition;
  const originalBoxShadow = element.style.boxShadow;
  
  element.style.transition = 'all 0.3s cubic-bezier(0.4, 0, 0.2, 1)';
  element.style.outline = '3px solid #14B8A6';
  element.style.boxShadow = '0 0 0 4px rgba(20, 184, 166, 0.2), 0 8px 16px rgba(20, 184, 166, 0.15)';
  
  setTimeout(() => {
    element.style.outline = originalOutline;
    element.style.boxShadow = originalBoxShadow;
    setTimeout(() => {
      element.style.transition = originalTransition;
    }, 300);
  }, 1200);
}

/**
 * Shows a notification to the user
 */
function showNotification(message, type = 'success') {
  // Check if notification already exists
  let notification = document.getElementById('nfc-reader-notification');
  
  if (!notification) {
    notification = document.createElement('div');
    notification.id = 'nfc-reader-notification';
    document.body.appendChild(notification);
  }
  
  // Set the appropriate background gradient
  const background = type === 'success' 
    ? 'linear-gradient(135deg, #14B8A6 0%, #0D9488 100%)' 
    : 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)';
  
  notification.style.cssText = `
    position: fixed;
    top: 24px;
    right: 24px;
    padding: 16px 24px;
    background: ${background};
    color: white;
    border-radius: 12px;
    box-shadow: 0 8px 24px rgba(20, 184, 166, 0.25), 0 2px 8px rgba(0, 0, 0, 0.1);
    z-index: 999999;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 14px;
    font-weight: 600;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    max-width: 320px;
    opacity: 1;
    transform: translateX(0) scale(1);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.2);
  `;
  
  // Add icon based on type
  const icon = type === 'success' ? '✓' : '⚠';
  notification.innerHTML = `
    <div style="display: flex; align-items: center; gap: 10px;">
      <span style="font-size: 18px; font-weight: bold;">${icon}</span>
      <span style="line-height: 1.4;">${message}</span>
    </div>
  `;
  
  // Animate in
  requestAnimationFrame(() => {
    notification.style.transform = 'translateX(0) scale(1)';
  });
  
  // Hide after 3 seconds
  setTimeout(() => {
    notification.style.opacity = '0';
    notification.style.transform = 'translateX(20px) scale(0.95)';
    setTimeout(() => {
      if (notification.parentNode) {
        notification.parentNode.removeChild(notification);
      }
    }, 300);
  }, 3000);
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

console.log('NFC Reader content script loaded');
