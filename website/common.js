document.addEventListener("DOMContentLoaded", () => {
  const path = window.location.pathname;
  const isIndex =
    path.endsWith("index.html") || path.endsWith("/") || path.endsWith("\\"); // Handle local file paths too roughly

  // If we are on index.html, we use anchor links directly.
  // If we are on other pages, we prepend index.html
  // However, to be safe and simple, we can always use index.html#anchor if we don't mind a reload on index.
  // But for smooth scrolling on index, we prefer just #anchor.

  // Simple check: if the URL doesn't contain 'index.html' and isn't root, assume it's a sub-page
  // But wait, local file system paths might be tricky.
  // Let's just check if the document title contains "NFC Reader - Connect" (index title) vs others.
  // Or just check if the element with id 'features' exists.

  const hasFeatures = document.getElementById("features") !== null;
  const prefix = hasFeatures ? "" : "index.html";

  const navHtml = `
    <nav>
        <a href="index.html" class="logo">
            <i class="fa-solid fa-id-card-clip"></i> NFC Bridge
        </a>
        <div class="nav-links">
            <a href="${prefix}#features">Features</a>
            <a href="${prefix}#download">Download</a>
            <a href="support.html">Support</a>
        </div>
    </nav>
    `;

  const footerHtml = `
    <footer>
        <p>&copy; 2025 NFC Reader Project. Open Source. | <a href="privacy-policy.html">Privacy Policy</a> | <a href="support.html">Support</a></p>
    </footer>
    `;
  // Inject Favicon
  const link = document.createElement("link");
  link.rel = "icon";
  link.type = "image/svg+xml";
  link.href = "nfc-icon.svg";
  document.head.appendChild(link);
  // Insert Nav
  // We look for a placeholder or just prepend to body
  // But we need to be careful not to duplicate if it's already there (during development/transition)
  // The user asked to extract, so I will remove the hardcoded ones from HTML.
  document.body.insertAdjacentHTML("afterbegin", navHtml);

  // Insert Footer
  document.body.insertAdjacentHTML("beforeend", footerHtml);
});
