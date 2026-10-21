/* wofi no tema {{ theme_title }} (gerado pelo theme-set a partir de
   ~/.config/theme/templates/wofi.css.tpl). Estilo Cyber-Arch, portado do cyberpunk.rasi do rofi */
@import url("{{ home }}/.config/theme/current/colors.css");
window { background-color: alpha(@background, 0.92); border: 2px solid @accent; border-radius: {{ rounding }}px; font-family: "{{ font }}"; font-size: {{ small_font_size }}pt; }
#input { margin: 8px; padding: 6px 10px; border: 2px solid @active; border-radius: {{ rounding_small }}px; background: @background; color: @highlight; }
#input:focus { box-shadow: none; }
#inner-box, #outer-box { margin: 4px; }
#entry { padding: 4px 8px; border: 2px solid transparent; border-radius: {{ rounding_small }}px; }
#entry:selected { background-color: transparent; border: 2px solid @active; }
#text { color: @foreground; }
#text:selected { color: @active; }
