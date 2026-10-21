-- Bordas das janelas no tema {{ theme_title }} (gerado pelo theme-set a partir de
-- ~/.config/theme/templates/hyprland.lua.tpl: edite o template, não este arquivo)
hl.config({
    general = {
        col = {
            active_border   = {{ hypr_gradient hyprland_active_border active }},
            inactive_border = {{ hypr_gradient hyprland_inactive_border rgba(595959aa) }},
        },
    },
})
