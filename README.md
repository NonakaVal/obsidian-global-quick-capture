# SendLog

`sendlog` é um menu global para registrar capturas na nota diária do Obsidian. Ele usa Rofi e altera diretamente o Markdown, sem depender de o Obsidian ou o Templater estarem abertos.

## Funcionalidades

- **Adicionar log**: oferece os mesmos tipos e emojis de `S-DailyloG.md`; solicita o texto e acrescenta uma linha ao final da seção `# Capture`, antes do próximo cabeçalho.
- **Abrir nota diária no Obsidian**: abre a nota de hoje pelo protocolo `obsidian://`; se ela ainda não existir, pede o humor e cria a nota primeiro.
- **Configurações**: permite editar os caminhos da Vault, das notas diárias e do template, o nome da Vault no Obsidian e a largura da janela do Rofi.

Os registros preservam o formato do template:

```text
- 🧭 texto - HH:mm \ [[AAAA-MM-DD]]
- [ ] ✅ tarefa - HH:mm \ [[AAAA-MM-DD]]
```

Os nove tipos são 🧭 Intenção, ✅ Nova Tarefa, 🌱 Motivação, 💬 Gratidão, 😴 Even, 💀 Puts, ⭐ Algo bom, 💩 Cagada e ❓ wtf?.

Quando cria uma nota, SendLog apresenta os humores do template (`🙂 – Neutral`, `😄 – Happy`, `😐 – Meh`, `😞 – Sad`, `😠 – Frustrated`) e gera a estrutura equivalente com metadados, links para os dias anterior e seguinte e as seções `Capture`, `Events` e `Caderno`. A função de cotação diária do Templater não é executada: o fluxo funciona sem o plugin e deixa o espaço de cotação vazio.

## Instalação manual

Requer Bash 4+, Rofi e `xdg-open` (fornecido por `xdg-utils`). Instale essas dependências pelo gerenciador de pacotes da sua distribuição, se necessário, e execute:

```bash
./install.sh
```

Por padrão, o instalador cria o comando global em `/usr/local/bin/sendlog`, usando `sudo` se necessário. Para instalar sem privilégios de administrador:

```bash
INSTALL_PREFIX="$HOME/.local" ./install.sh
```

O instalador não instala pacotes do sistema. Execute `sendlog` após a instalação; a configuração inicial fica em `~/.config/sendlog/`.

## Configuração

O padrão é a Vault `~/Documentos/Notepad` e a pasta `Calendar & Review/Daily Notes` dentro dela. As opções podem ser alteradas no menu **Configurações** ou no arquivo:

```text
~/.config/sendlog/config
```

O template independente, editável e baseado em `B-Daily Note Template.md` fica em:

```text
~/.config/sendlog/daily-note-template.md
```

Ele usa os campos `{{DATE}}`, `{{TIME}}`, `{{PREVIOUS_DATE}}`, `{{NEXT_DATE}}`, `{{WEEK}}`, `{{MOOD}}` e `{{DAILY_QUOTE}}`. O template do Templater não é executado como JavaScript.
# obsidian-global-quick-capture
