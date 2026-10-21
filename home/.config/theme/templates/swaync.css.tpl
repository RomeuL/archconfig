/* Central de notificações (swaync) no tema {{ theme_title }} (gerado pelo theme-set a partir de
   ~/.config/theme/templates/swaync.css.tpl): o CSS padrão do swaync com as cores, a fonte, os
   cantos e a borda do tema */
@import url("file:///etc/xdg/swaync/style.css");

:root {
  --cc-bg: rgba({{ background_rgb }}, 0.94);
  --noti-border-color: rgba({{ accent_rgb }}, 0.35);
  --noti-bg: {{ lighter_background_rgb }};
  --noti-bg-alpha: 0.9;
  --noti-bg-darker: {{ dark_background }};
  --noti-bg-hover: {{ mix lighter_background foreground 8% }};
  --noti-bg-focus: rgba({{ accent_rgb }}, 0.18);
  --noti-close-bg: {{ mix lighter_background foreground 12% }};
  --noti-close-bg-hover: {{ mix lighter_background foreground 22% }};
  --text-color: {{ foreground }};
  --text-color-disabled: {{ dark_foreground }};
  --bg-selected: {{ accent }};
  --border-radius: {{ rounding_small }}px;
  --font-size-body: {{ small_font_size }}pt;
  --font-size-summary: {{ font_size }}px;
}

* { font-family: "{{ font }}", sans-serif; }

.control-center {
  border: {{ border_size }}px solid {{ accent }};
  border-radius: {{ rounding }}px;
}
.widget-title > label { color: {{ active }}; font-weight: bold; }
.widget-title > button { color: {{ foreground }}; }
.widget-title > button:hover { background: {{ accent }}; color: {{ background }}; }
.notification.critical { border: 1px solid {{ alert }}; }
.control-center-list-placeholder { color: {{ dark_foreground }}; }
