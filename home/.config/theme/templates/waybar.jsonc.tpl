// Partes da Waybar que mudam com o tema {{ theme_title }} (gerado pelo theme-set a partir de
// ~/.config/theme/templates/waybar.jsonc.tpl). A ~/.config/waybar/config.jsonc inclui este
// arquivo e tem prioridade sobre ele, então o que um tema quiser mudar não pode estar lá.
{
    "height": 30,
    "spacing": 4,
    "margin-top": 6,
    "margin-left": 10,
    "margin-right": 10,

    "hyprland/workspaces": {
        // Numeração em kanji, como no Cyber-Arch (z e x continuam com o nome)
        "format": "{icon}",
        "format-icons": {
            "1": "一", "2": "二", "3": "三", "4": "四", "5": "五",
            "6": "六", "7": "七", "8": "八", "9": "九", "10": "十",
            "z": "z", "x": "x",
            "default": "·"
        }
    }
}
