# Cores dos apps KDE (Dolphin etc.) no tema {{ theme_title }}, gerado pelo theme-set a partir de
# ~/.config/theme/templates/kdeglobals.tpl: edite o template, não este arquivo.
# ~/.config/kdeglobals é um link para cá.

[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,111,110
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

[Colors:Button]
BackgroundAlternate={{ mix_rgb lighter_background foreground 8% }}
BackgroundNormal={{ lighter_background_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
ForegroundActive={{ active_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundPositive={{ green_rgb }}
ForegroundVisited={{ magenta_rgb }}

[Colors:Complementary]
BackgroundAlternate={{ dark_background_rgb }}
BackgroundNormal={{ darker_background_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
ForegroundActive={{ active_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundPositive={{ green_rgb }}
ForegroundVisited={{ magenta_rgb }}

[Colors:Header]
BackgroundAlternate={{ mix_rgb dark_background foreground 5% }}
BackgroundNormal={{ dark_background_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
ForegroundActive={{ active_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundPositive={{ green_rgb }}
ForegroundVisited={{ magenta_rgb }}

[Colors:Header][Inactive]
BackgroundAlternate={{ mix_rgb dark_background foreground 5% }}
BackgroundNormal={{ dark_background_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
ForegroundActive={{ active_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundPositive={{ green_rgb }}
ForegroundVisited={{ magenta_rgb }}

[Colors:Selection]
BackgroundAlternate={{ mix_rgb accent background 40% }}
BackgroundNormal={{ accent_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
ForegroundActive={{ background_rgb }}
ForegroundInactive={{ mix_rgb background accent 35% }}
ForegroundLink={{ background_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundNormal={{ background_rgb }}
ForegroundPositive={{ green_rgb }}
ForegroundVisited={{ magenta_rgb }}

[Colors:Tooltip]
BackgroundAlternate={{ background_rgb }}
BackgroundNormal={{ lighter_background_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
ForegroundActive={{ active_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundPositive={{ green_rgb }}
ForegroundVisited={{ magenta_rgb }}

[Colors:View]
BackgroundAlternate={{ mix_rgb dark_background foreground 4% }}
BackgroundNormal={{ dark_background_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
ForegroundActive={{ active_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundPositive={{ green_rgb }}
ForegroundVisited={{ magenta_rgb }}

[Colors:Window]
BackgroundAlternate={{ mix_rgb background foreground 5% }}
BackgroundNormal={{ background_rgb }}
DecorationFocus={{ accent_rgb }}
DecorationHover={{ accent_rgb }}
ForegroundActive={{ active_rgb }}
ForegroundInactive={{ dark_foreground_rgb }}
ForegroundLink={{ blue_rgb }}
ForegroundNegative={{ red_rgb }}
ForegroundNeutral={{ yellow_rgb }}
ForegroundNormal={{ foreground_rgb }}
ForegroundPositive={{ green_rgb }}
ForegroundVisited={{ magenta_rgb }}

[General]
ColorScheme=TemaDoSistema
Name={{ theme_title }}
shadeSortColumn=true

[Icons]
Theme={{ by_mode breeze-dark breeze }}

[KDE]
contrast=4
widgetStyle=Breeze

[UiSettings]
# Sem isto o Dolphin cai no Breeze claro. O esquema é este mesmo arquivo:
# ~/.local/share/color-schemes/TemaDoSistema.colors é um link para cá
ColorScheme=TemaDoSistema

[WM]
activeBackground={{ background_rgb }}
activeBlend={{ foreground_rgb }}
activeForeground={{ foreground_rgb }}
inactiveBackground={{ dark_background_rgb }}
inactiveBlend={{ dark_foreground_rgb }}
inactiveForeground={{ dark_foreground_rgb }}
