#!/bin/bash

# Define os caminhos para o escopo do usuário
USER_SYSTEMD_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
SERVICE_NAME="nordvpn-kamikaze.service"
SERVICE_PATH="$USER_SYSTEMD_DIR/$SERVICE_NAME"

echo "[*] Preparando a missão kamikaze para o D-Bus do NordVPN..."

# Cria o diretório de serviços do usuário caso o Arch ainda não o tenha criado
mkdir -p "$USER_SYSTEMD_DIR"

# Injeta a configuração do serviço usando um HereDoc
cat << 'EOF' > "$SERVICE_PATH"
[Unit]
Description=NordVPN D-Bus Tray Fix (Self-Destructing)
After=default.target

[Service]
Type=oneshot
# O script inline faz 3 coisas:
# 1. Loop aguardando o daemon do NordVPN responder (evita falha por race condition no boot)
# 2. Executa o comando de mitigação (desliga o tray)
# 3. Se tiver sucesso (&&), desabilita o serviço, deleta o arquivo e limpa a memória do systemd
ExecStart=/usr/bin/bash -c 'until nordvpn status >/dev/null 2>&1; do sleep 2; done; nordvpn set tray off && systemctl --user disable nordvpn-kamikaze.service && rm -f %h/.config/systemd/user/nordvpn-kamikaze.service && systemctl --user daemon-reload'

[Install]
WantedBy=default.target
EOF

echo "[*] Arquivo do serviço gerado em: $SERVICE_PATH"

# Recarrega o systemd do usuário para reconhecer o novo arquivo
systemctl --user daemon-reload

# Habilita o serviço para rodar no próximo login/boot
systemctl --user enable "$SERVICE_NAME"

echo "[+] Sucesso! O serviço '$SERVICE_NAME' está armado."
echo "[+] No seu próximo login/boot, ele irá desligar o tray e apagar todos os seus próprios rastros."
