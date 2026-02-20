#!/usr/bin/env bash

set -euo pipefail

NEXUS_IP="192.168.1.200"
NEXUS_PORT="8081"
REPO_NAME="apt-proxy"

echo "Настраиваем APT для использования Nexus proxy (${NEXUS_IP}:${NEXUS_PORT})"

sudo tee /etc/apt/sources.list > /dev/null <<EOF
# Оригинальные репозитории отключены — всё идёт через Nexus
# deb http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse

deb [trusted=yes] http://${NEXUS_IP}:${NEXUS_PORT}/repository/${REPO_NAME} jammy main restricted universe multiverse
deb [trusted=yes] http://${NEXUS_IP}:${NEXUS_PORT}/repository/${REPO_NAME} jammy-updates main restricted universe multiverse
deb [trusted=yes] http://${NEXUS_IP}:${NEXUS_PORT}/repository/${REPO_NAME} jammy-security main restricted universe multiverse
EOF

# Опционально: отключаем src-репозитории, если не нужны
sudo rm -f /etc/apt/sources.list.d/*.list 2>/dev/null || true

echo "Обновляем списки пакетов..."
sudo apt update

echo "Готово. Теперь apt использует Nexus как прокси для Ubuntu пакетов."
