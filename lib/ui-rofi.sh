#!/usr/bin/env bash

rofi_menu() {
    if ! command -v rofi >/dev/null 2>&1; then
        printf 'sendlog: rofi não encontrado.\n' >&2
        return 127
    fi

    local theme_args=()
    if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/rofi/simple-tokyonight.rasi" ]]; then
        theme_args+=(-theme "${XDG_CONFIG_HOME:-$HOME/.config}/rofi/simple-tokyonight.rasi")
    fi
    local theme_str="window { width: ${ROFI_WINDOW_WIDTH}; }"
    if [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]; then
        rofi -dmenu -i -normal-window "${theme_args[@]}" -theme-str "$theme_str" "$@"
    else
        rofi -dmenu -i "${theme_args[@]}" -theme-str "$theme_str" "$@"
    fi
}

open_settings() {
    while true; do
        local choice
        choice="$(printf 'Vault: %s\nPasta das notas diárias: %s\nTemplate da nota diária: %s\nNome da Vault no Obsidian: %s\nLargura do Rofi: %s\nAbrir arquivo de configuração\nVoltar' \
            "$VAULT_DIR" "$DAILY_NOTES_DIR" "$DAILY_NOTE_TEMPLATE" "$OBSIDIAN_VAULT_NAME" "$ROFI_WINDOW_WIDTH" \
            | rofi_menu -p 'Configuracoes')" || return 0

        case "$choice" in
            "Vault:"*)
                VAULT_DIR="$(setting_input "$VAULT_DIR" 'Caminho da Vault')" || continue
                VAULT_DIR="$(normalize_path "$VAULT_DIR" "$HOME")"
                OBSIDIAN_VAULT_NAME="$(basename "$VAULT_DIR")"
                save_config
                ;;
            "Pasta das notas diárias:"*)
                DAILY_NOTES_DIR="$(setting_input "$DAILY_NOTES_DIR" 'Pasta relativa à Vault')" || continue
                save_config
                ;;
            "Template da nota diária:"*)
                DAILY_NOTE_TEMPLATE="$(setting_input "$DAILY_NOTE_TEMPLATE" 'Caminho do template')" || continue
                DAILY_NOTE_TEMPLATE="$(normalize_path "$DAILY_NOTE_TEMPLATE" "$VAULT_DIR")"
                save_config
                ;;
            "Nome da Vault no Obsidian:"*)
                OBSIDIAN_VAULT_NAME="$(setting_input "$OBSIDIAN_VAULT_NAME" 'Nome da Vault no Obsidian')" || continue
                save_config
                ;;
            "Largura do Rofi:"*)
                local width
                width="$(setting_input "$ROFI_WINDOW_WIDTH" 'Largura (ex.: 510px)')" || continue
                width="${width//[[:space:]]/}"
                [[ "$width" =~ ^[0-9]+$ ]] && width="${width}px"
                if [[ "$width" =~ ^[0-9]+(px|%)$ ]]; then
                    ROFI_WINDOW_WIDTH="$width"
                    save_config
                else
                    notify "Largura inválida. Use um número em px ou %."
                fi
                ;;
            "Abrir arquivo de configuração")
                if command -v xdg-open >/dev/null 2>&1; then
                    xdg-open "$CONFIG_FILE" >/dev/null 2>&1 &
                else
                    notify "xdg-open não encontrado."
                fi
                ;;
            "Voltar"|"") return 0 ;;
        esac
    done
}

setting_input() {
    local current="$1" prompt="$2"
    printf '%s\n' "$current" | rofi_menu -p "$prompt"
}
