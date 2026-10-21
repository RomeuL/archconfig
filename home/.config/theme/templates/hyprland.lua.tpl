-- Visual das janelas no tema {{ theme_title }} (gerado pelo theme-set a partir de
-- ~/.config/theme/templates/hyprland.lua.tpl e do style.toml: edite esses, não este arquivo)
hl.config({
    general = {
        gaps_in     = {{ gaps_in }},
        gaps_out    = {{ gaps_out }},
        border_size = {{ border_size }},
        col = {
            active_border   = {{ hypr_gradient hyprland_active_border active }},
            inactive_border = {{ hypr_gradient hyprland_inactive_border rgba(595959aa) }},
        },
    },

    decoration = {
        rounding         = {{ rounding }},
        active_opacity   = {{ opacity_active }},
        inactive_opacity = {{ opacity_inactive }},

        blur = { enabled = {{ blur }} },

        shadow = {
            enabled      = {{ shadow }},
            range        = {{ shadow_range }},
            render_power = 3,
            sharp        = {{ shadow_sharp }},
            offset       = {{ shadow_offset }},
            color        = "{{ shadow_color }}",
        },

        glow = {
            enabled        = {{ glow }},
            range          = {{ glow_range }},
            color          = "{{ glow_color }}",
            color_inactive = "rgba(00000000)",
        },
    },

    animations = { enabled = {{ animations }} },
})
