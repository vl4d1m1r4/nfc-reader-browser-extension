document.addEventListener("DOMContentLoaded", () => {
  const hasFeatures = document.getElementById("features") !== null;
  const prefix = hasFeatures ? "" : "index.html";

  const navHtml = `
    <nav>
        <a href="index.html" class="logo">
            <i class="fa-solid fa-id-card-clip"></i> NFC Reader
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
  document.body.insertAdjacentHTML("afterbegin", navHtml);

  // Insert Footer
  document.body.insertAdjacentHTML("beforeend", footerHtml);
});
