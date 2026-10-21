/* Cores do tema {{ theme_title }} para o Firefox (gerado pelo theme-set a partir de
   ~/.config/theme/templates/firefox.css.tpl). O userChrome.css e o userContent.css importam
   este arquivo (chrome/theme.css); o Firefox só lê de novo ao ser reaberto. */
:root {
  --tp-foreground: {{ foreground }};
  --tp-foreground-rgb: {{ foreground_rgb }};
  --tp-bright: {{ bright_foreground }};
  --tp-accent: {{ accent }};
  --tp-accent-rgb: {{ accent_rgb }};
  --tp-active: {{ active }};
  --tp-active-rgb: {{ active_rgb }};
  --tp-highlight: {{ highlight }};
  --tp-background: {{ background }};
  --tp-bg: {{ dark_background }};
  --tp-bg2: {{ lighter_background }};
  --tp-line: {{ mix background accent 16% }};
  --tp-radius: {{ rounding_small }}px;
}
