#!/usr/bin/env bash

set -euo pipefail

NEXUS_URL="http://localhost:8081"
USER="admin"


PASS_FILE="/opt/sonatype-work/nexus3/admin.password"
if [[ -f "$PASS_FILE" ]]; then
    PASS=$(sudo cat "$PASS_FILE" | tr -d '[:space:]')
    echo "→ Используем начальный пароль из файла"
else
    echo "Начальный пароль не найден → укажи текущий пароль администратора:"
    PASS="admin123"  
fi

echo "Ждём запуска Nexus (30сек)"
sleep 30

echo "Создаём APT proxy (jammy)..."

curl -u "${USER}:${PASS}" -X POST \
  "${NEXUS_URL}/service/rest/v1/repositories/apt/proxy" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "apt-proxy",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true
    },
    "cleanup": null,
    "proxy": {
      "remoteUrl": "http://archive.ubuntu.com/ubuntu/",
      "contentMaxAge": 1440,
      "metadataMaxAge": 1440
    },
    "negativeCache": {
      "enabled": true,
      "timeToLive": 1440
    },
    "httpClient": {
      "blocked": false,
      "autoBlock": true
    },
    "apt": {
      "distribution": "jammy",
      "flat": false
    }
  }'

echo -e "\nСоздаём PyPI proxy..."

curl -u "${USER}:${PASS}" -X POST \
  "${NEXUS_URL}/service/rest/v1/repositories/pypi/proxy" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "pypi-proxy",
    "online": true,
    "storage": {
      "blobStoreName": "default",
      "strictContentTypeValidation": true
    },
    "cleanup": null,
    "proxy": {
      "remoteUrl": "https://pypi.org/",
      "contentMaxAge": 1440,
      "metadataMaxAge": 1440
    },
    "negativeCache": {
      "enabled": true,
      "timeToLive": 1440
    },
    "httpClient": {
      "blocked": false,
      "autoBlock": true
    }
  }'

echo -e "\nПроверка (должны появиться apt-proxy и pypi-proxy):"
curl -s -u "${USER}:${PASS}" "${NEXUS_URL}/service/rest/v1/repositories" \
  | grep -E 'name|format|type|url' || echo "curl не сработал — проверь пароль"

echo -e "\nГотово. Репозитории созданы.\n"

