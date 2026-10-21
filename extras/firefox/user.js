// Cores do tema atual do sistema (chrome/userChrome.css + chrome/theme.css do theme-set)
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // ativa chrome/userChrome.css
user_pref("extensions.activeThemeID", "default-theme@mozilla.org"); // tema "Sistema": claro/escuro do sistema
user_pref("browser.theme.toolbar-theme", 2);   // interface: segue o sistema
user_pref("browser.theme.content-theme", 2);   // sites: segue o sistema (prefers-color-scheme)
user_pref("layout.css.prefers-color-scheme.content-override", 2);
