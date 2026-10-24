#!/usr/bin/env bash

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/sendlog"
CONFIG_FILE="$CONFIG_DIR/config"
TEMPLATE_FILE="$CONFIG_DIR/daily-note-template.md"

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    fi

    VAULT_DIR="${VAULT_DIR:-$HOME/Documentos/Notepad}"
    DAILY_NOTES_DIR="${DAILY_NOTES_DIR:-Calendar & Review/Daily Notes}"
    OBSIDIAN_VAULT_NAME="${OBSIDIAN_VAULT_NAME:-$(basename "$VAULT_DIR")}"
    ROFI_WINDOW_WIDTH="${ROFI_WINDOW_WIDTH:-510px}"
    DAILY_NOTE_TEMPLATE="${DAILY_NOTE_TEMPLATE:-$TEMPLATE_FILE}"
    VAULT_DIR="$(normalize_path "$VAULT_DIR" "$HOME")"
    DAILY_NOTE_TEMPLATE="$(normalize_path "$DAILY_NOTE_TEMPLATE" "$VAULT_DIR")"
    export VAULT_DIR DAILY_NOTES_DIR OBSIDIAN_VAULT_NAME ROFI_WINDOW_WIDTH DAILY_NOTE_TEMPLATE
}

ensure_app_files() {
    mkdir -p "$CONFIG_DIR"
    if [[ ! -f "$CONFIG_FILE" ]]; then
        save_config
    fi
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        create_default_template
    fi
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    {
        printf '# SendLog configuration\n'
        printf 'VAULT_DIR=%q\n' "$VAULT_DIR"
        printf 'DAILY_NOTES_DIR=%q\n' "$DAILY_NOTES_DIR"
        printf 'DAILY_NOTE_TEMPLATE=%q\n' "$DAILY_NOTE_TEMPLATE"
        printf 'OBSIDIAN_VAULT_NAME=%q\n' "$OBSIDIAN_VAULT_NAME"
        printf 'ROFI_WINDOW_WIDTH=%q\n' "$ROFI_WINDOW_WIDTH"
    } > "$CONFIG_FILE"
    export VAULT_DIR DAILY_NOTES_DIR OBSIDIAN_VAULT_NAME ROFI_WINDOW_WIDTH DAILY_NOTE_TEMPLATE
}

create_default_template() {
    cat > "$TEMPLATE_FILE" <<'TEMPLATE'
---
dateCreated: {{DATE}} @ {{TIME}}
tags:
  - calendar/dailynote
week: '[[{{WEEK}}]]'
daily-mood: "{{MOOD}}"
---
[[{{PREVIOUS_DATE}}|↶ Previous Day]] | [[{{NEXT_DATE}}|Following Day ↷]]

# {{DATE}}’s Note

// Daily quote
{{DAILY_QUOTE}}






---



# Capture


# Events

# Caderno
TEMPLATE
}

expand_path() {
    local path="$1"
    path="${path//\$\{HOME\}/$HOME}"
    path="${path//\$HOME/$HOME}"
    case "$path" in
        "~") path="$HOME" ;;
        "~/"*) path="$HOME/${path:2}" ;;
    esac
    printf '%s' "$path"
}

normalize_path() {
    local path base
    path="$(expand_path "$1")"
    base="$2"
    [[ "$path" == /* ]] || path="$base/$path"
    printf '%s' "$path"
}

daily_notes_path() {
    local dir
    dir="$(expand_path "$DAILY_NOTES_DIR")"
    if [[ "$dir" != /* ]]; then
        dir="$VAULT_DIR/$dir"
    fi
    printf '%s' "$dir"
}
