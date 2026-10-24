#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

source "$SCRIPT_DIR/lib/config.sh"
source "$SCRIPT_DIR/lib/daily-note.sh"
source "$SCRIPT_DIR/lib/ui-rofi.sh"

load_config
ensure_app_files

main_menu() {
    local choice
    choice="$(printf 'Adicionar log\nAbrir nota diaria no Obsidian\nConfiguracoes' | rofi_menu -p 'sendlog')" || return 0

    case "$choice" in
        "Adicionar log") add_log ;;
        "Abrir nota diaria no Obsidian") open_daily_note ;;
        "Configuracoes") open_settings ;;
    esac
}

case "${1:-}" in
    "")
        main_menu
        ;;
    --help|-h|help)
        printf 'Uso: sendlog\n'
        ;;
    *)
        printf 'Uso: %s [--help]\n' "${0##*/}" >&2
        exit 2
        ;;
esac
