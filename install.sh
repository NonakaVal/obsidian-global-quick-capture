#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
APP_NAME="sendlog"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"
TARGET="${INSTALL_PREFIX}/bin/${APP_NAME}"
USER_TARGET="${HOME}/.local/bin/${APP_NAME}"

if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
    printf 'sendlog requer Bash 4 ou superior.\n' >&2
    exit 1
fi
if ! command -v rofi >/dev/null 2>&1; then
    printf 'Dependência ausente: rofi. Instale-a e execute install.sh novamente.\n' >&2
    exit 1
fi
if ! command -v xdg-open >/dev/null 2>&1; then
    printf 'Dependência ausente: xdg-open (pacote xdg-utils). Instale-a e execute install.sh novamente.\n' >&2
    exit 1
fi

chmod +x "$SCRIPT_DIR/sendlog.sh"

if [[ -w "$(dirname "$TARGET")" ]]; then
    ln -sfn "$SCRIPT_DIR/sendlog.sh" "$TARGET"
    printf 'Comando instalado: %s\n' "$TARGET"
else
    if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
        sudo mkdir -p "$(dirname "$TARGET")"
        sudo ln -sfn "$SCRIPT_DIR/sendlog.sh" "$TARGET"
        printf 'Comando instalado: %s\n' "$TARGET"
    else
        mkdir -p "$(dirname "$USER_TARGET")"
        ln -sfn "$SCRIPT_DIR/sendlog.sh" "$USER_TARGET"
        printf 'Comando instalado: %s\n' "$USER_TARGET"
        case ":$PATH:" in
            *":$HOME/.local/bin:"*) ;;
            *) printf 'Adicione ~/.local/bin ao PATH para usar sendlog.\n' >&2 ;;
        esac
    fi
fi

printf 'Na primeira execução, sendlog criará sua configuração em ~/.config/sendlog/.\n'
