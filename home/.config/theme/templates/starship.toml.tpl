# Prompt do Starship no tema {{ theme_title }} (gerado pelo theme-set a partir de
# ~/.config/theme/templates/starship.toml.tpl: edite o template, não este arquivo).
# O .zshrc aponta STARSHIP_CONFIG para cá; o Starship relê a cada prompt.
"$schema" = "https://starship.rs/config-schema.json"

format = """
$directory$git_branch$git_status$nodejs$python$rust$golang$java$docker_context$cmd_duration
$character"""
add_newline = true
palette = "tema"

[character]
success_symbol = "[➤](bold accent)"
error_symbol = "[✗](bold alert)"
vimcmd_symbol = "[❮](bold active)"

[directory]
style = "bold yellow"
read_only = " "
read_only_style = "red"
truncation_length = 4
truncation_symbol = "…/"

[git_branch]
symbol = " "
style = "bold cyan"
format = "[$symbol$branch]($style) "

[git_status]
style = "bold red"
format = "([\\[$all_status$ahead_behind\\]]($style) )"

[cmd_duration]
min_time = 2000
style = "magenta"
format = "[ $duration]($style) "

[nodejs]
symbol = " "
style = "bold green"

[python]
symbol = " "
style = "bold yellow"

[rust]
symbol = "\U000F1617 "
style = "bold red"

[golang]
symbol = " "
style = "bold cyan"

[java]
symbol = " "
style = "bold red"

[docker_context]
symbol = " "
style = "bold cyan"

[palettes.tema]
accent = "{{ accent }}"
active = "{{ active }}"
alert = "{{ alert }}"
red = "{{ red }}"
green = "{{ green }}"
yellow = "{{ yellow }}"
cyan = "{{ cyan }}"
magenta = "{{ magenta }}"
