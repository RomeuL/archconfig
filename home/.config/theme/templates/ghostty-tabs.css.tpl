/* Barra de abas do Ghostty no tema {{ theme_title }} (gerado pelo theme-set a partir de
   ~/.config/theme/templates/ghostty-tabs.css.tpl: edite o template, não este arquivo) */
tabbar .box {
    background-color: {{ dark_background }};
    box-shadow: none;
    border-bottom: 1px solid {{ mix background accent 16% }};
}
tabbar tab {
    color: rgba({{ foreground_rgb }}, 0.7);
    border-radius: 8px 8px 0 0;
}
tabbar tab:hover {
    background-color: rgba({{ accent_rgb }}, 0.12);
}
tabbar tab:selected {
    color: {{ active }};
    background-color: {{ lighter_background }};
    box-shadow: inset 0 2px {{ active }};
}
tabbar tab button { color: {{ accent }}; }
