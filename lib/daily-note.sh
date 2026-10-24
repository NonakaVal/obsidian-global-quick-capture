#!/usr/bin/env bash

LOG_TYPES=(
    "🧭 Intenção"
    "✅ Nova Tarefa"
    "🌱 Motivação"
    "💬 Gratidão"
    "😴 Even"
    "💀 Puts"
    "⭐ Algo bom"
    "💩 Cagada"
    "❓ wtf?"
)

log_emoji() {
    case "$1" in
        "🧭 Intenção") printf '🧭' ;;
        "✅ Nova Tarefa") printf '✅' ;;
        "🌱 Motivação") printf '🌱' ;;
        "💬 Gratidão") printf '💬' ;;
        "😴 Even") printf '😴' ;;
        "💀 Puts") printf '💀' ;;
        "⭐ Algo bom") printf '⭐' ;;
        "💩 Cagada") printf '💩' ;;
        "❓ wtf?") printf '❓' ;;
        *) return 1 ;;
    esac
}

today_date() {
    date '+%Y-%m-%d'
}

daily_note_file() {
    printf '%s/%s.md' "$(daily_notes_path)" "$(today_date)"
}

choose_mood() {
    local moods choice
    moods="$(printf '🙂 – Neutral\n😄 – Happy\n😐 – Meh\n😞 – Sad\n😠 – Frustrated\nDigitar humor personalizado')"
    choice="$(printf '%s\n' "$moods" | rofi_menu -p 'Humor do dia')" || return 1
    [[ -z "$choice" ]] && return 1

    if [[ "$choice" == "Digitar humor personalizado" ]]; then
        choice="$(rofi_menu -p 'Humor personalizado')" || return 1
    fi
    [[ -n "$choice" ]] || return 1
    printf '%s' "$choice"
}

render_daily_template() {
    local mood="$1" date_value="$2" time_value="$3" previous next week content
    previous="$(date -d "$date_value -1 day" '+%Y-%m-%d')"
    next="$(date -d "$date_value +1 day" '+%Y-%m-%d')"
    week="$(date -d "$date_value" '+%G Week %V')"
    content="$(cat "$DAILY_NOTE_TEMPLATE")"
    content="${content//\{\{DATE\}\}/$date_value}"
    content="${content//\{\{TIME\}\}/$time_value}"
    content="${content//\{\{PREVIOUS_DATE\}\}/$previous}"
    content="${content//\{\{NEXT_DATE\}\}/$next}"
    content="${content//\{\{WEEK\}\}/$week}"
    content="${content//\{\{MOOD\}\}/$mood}"
    content="${content//\{\{DAILY_QUOTE\}\}/}"
    printf '%s\n' "$content"
}

create_daily_note() {
    local file="$1" mood="$2" dir date_value time_value rendered
    dir="$(dirname "$file")"
    date_value="$(today_date)"
    time_value="$(date '+%H:%M')"

    [[ -f "$DAILY_NOTE_TEMPLATE" ]] || {
        notify "Template da nota diária não encontrado: $DAILY_NOTE_TEMPLATE"
        return 1
    }
    mkdir -p "$dir"
    rendered="$(render_daily_template "$mood" "$date_value" "$time_value")"
    (umask 077; set -o noclobber; printf '%s' "$rendered" > "$file") 2>/dev/null || {
        [[ -f "$file" ]] && return 0
        notify "Não foi possível criar a nota diária: $file"
        return 1
    }
}

append_capture_log() {
    local file="$1" line="$2" temp
    [[ -f "$file" ]] || return 1
    temp="$(mktemp "${file}.sendlog.XXXXXX")" || return 1

    if ! SENDLOG_ENTRY="$line" awk -v header='# Capture' '
        {
            lines[NR] = $0
            if (!section && $0 ~ /^[[:space:]]*#[[:space:]]+Capture[[:space:]]*$/) section = NR
        }
        END {
            if (!section) {
                for (i = 1; i <= NR; i++) print lines[i]
                if (NR && lines[NR] != "") print ""
                print header
                print ENVIRON["SENDLOG_ENTRY"]
                exit
            }

            end = NR + 1
            for (i = section + 1; i <= NR; i++) {
                if (lines[i] ~ /^#+[[:space:]]/) {
                    end = i
                    break
                }
            }

            insert = end - 1
            while (insert > section && lines[insert] ~ /^[[:space:]]*$/) insert--
            if (insert < section) insert = section

            for (i = 1; i <= NR; i++) {
                print lines[i]
                if (i == insert) print ENVIRON["SENDLOG_ENTRY"]
            }
        }
    ' "$file" > "$temp"; then
        rm -f -- "$temp"
        notify "Não foi possível atualizar a nota diária: $file"
        return 1
    fi

    chmod --reference="$file" "$temp" 2>/dev/null || true
    mv -- "$temp" "$file" || {
        rm -f -- "$temp"
        notify "Não foi possível gravar a nota diária: $file"
        return 1
    }
}

add_log() {
    local selected emoji value date_value time_value line file mood
    selected="$(printf '%s\n' "${LOG_TYPES[@]}" | rofi_menu -p 'Que tipo de capture?')" || return 0
    [[ -n "$selected" ]] || return 0
    emoji="$(log_emoji "$selected")" || return 0

    value="$(rofi_menu -p "$emoji ...")" || return 0
    value="${value//$'\n'/ }"
    value="${value//$'\r'/}"
    [[ -n "${value//[[:space:]]/}" ]] || return 0

    file="$(daily_note_file)"
    if [[ ! -f "$file" ]]; then
        mood="$(choose_mood)" || return 0
        create_daily_note "$file" "$mood" || return 1
    fi

    date_value="$(today_date)"
    time_value="$(date '+%H:%M')"
    if [[ "$selected" == "✅ Nova Tarefa" ]]; then
        line="- [ ] ✅ $value - $time_value \\ [[$date_value]]"
    else
        line="- $emoji $value - $time_value \\ [[$date_value]]"
    fi

    append_capture_log "$file" "$line" || return 1
    notify "$emoji Registro salvo na daily $date_value"
}

open_daily_note() {
    local file mood vault_path relative_file uri
    file="$(daily_note_file)"
    if [[ ! -f "$file" ]]; then
        mood="$(choose_mood)" || return 0
        create_daily_note "$file" "$mood" || return 1
    fi

    vault_path="$(cd "$VAULT_DIR" && pwd -P)" || {
        notify "Vault não encontrada: $VAULT_DIR"
        return 1
    }
    file="$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")"
    case "$file" in
        "$vault_path"/*) relative_file="${file#"$vault_path"/}" ;;
        *)
            notify "A nota diária precisa estar dentro da Vault para abrir no Obsidian."
            return 1
            ;;
    esac

    uri="obsidian://open?vault=$(url_encode "$OBSIDIAN_VAULT_NAME")&file=$(url_encode "$relative_file")"
    if ! command -v xdg-open >/dev/null 2>&1; then
        notify "xdg-open não encontrado; não foi possível abrir o Obsidian."
        return 1
    fi
    xdg-open "$uri" >/dev/null 2>&1 &
}

url_encode() {
    local input="$1" output="" char hex i
    local LC_ALL=C
    for ((i = 0; i < ${#input}; i++)); do
        char="${input:i:1}"
        case "$char" in
            [a-zA-Z0-9.~_-]) output+="$char" ;;
            *) printf -v hex '%%%02X' "'$char"; output+="$hex" ;;
        esac
    done
    printf '%s' "$output"
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "sendlog" "$1" 2>/dev/null || printf 'sendlog: %s\n' "$1" >&2
    else
        printf 'sendlog: %s\n' "$1" >&2
    fi
}
