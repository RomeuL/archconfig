/* Tela de login (regreet) no tema {{ theme_title }}, gerado pelo theme-set a partir de
   ~/.config/theme/templates/login.css.tpl e copiado para /var/lib/theme-set (o usuário greeter
   não enxerga o $HOME). Moldura no accent; fonte, cantos e bordas do style.toml do tema */
* { font-family: "{{ font }}", sans-serif; font-size: {{ small_font_size }}pt; }
window { background-color: {{ background }}; color: {{ active }}; }
frame, .background { background-color: alpha({{ background }}, {{ login_opacity }}); }
frame { border: {{ border_size }}px solid {{ accent }}; border-radius: {{ rounding }}px; }
label { color: {{ active }}; }
entry {
  background-color: {{ lighter_background }};
  color: {{ highlight }};
  border: 1px solid {{ active }};
  border-radius: {{ rounding_small }}px;
}
entry:focus { border-color: {{ highlight }}; }
button {
  background: {{ lighter_background }};
  color: {{ active }};
  border: 1px solid {{ accent }};
  border-radius: {{ rounding_small }}px;
}
button:hover { background: {{ accent }}; color: {{ background }}; }
button.suggested-action { background: {{ accent }}; color: {{ background }}; }
