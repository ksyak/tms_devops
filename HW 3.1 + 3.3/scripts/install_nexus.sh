#!/bin/bash
set -e

NEXUS_VERSION="3.70.1-02"
NEXUS_USER="nexus"
INSTALL_DIR="/opt"
NEXUS_DIR="$INSTALL_DIR/nexus"
DATA_DIR="/opt/sonatype-work"

echo "=== Установка Java 11 (требуется для Nexus 3.70.x с OrientDB) ==="
sudo apt update
sudo apt install -y openjdk-11-jdk wget net-tools curl

echo "=== Создание пользователя nexus ==="
sudo useradd -r -m -U -d "$DATA_DIR" -s /bin/false "$NEXUS_USER" || true

echo "=== Скачивание Nexus ==="
cd /tmp
wget --no-verbose "https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz"

echo "=== Распаковка Nexus ==="
sudo tar -xzf "nexus-${NEXUS_VERSION}-unix.tar.gz" -C "$INSTALL_DIR"
sudo mv "$INSTALL_DIR/nexus-${NEXUS_VERSION}" "$NEXUS_DIR"

echo "=== Фикс совместимости с Java 11: отключаем -Djava.endorsed.dirs ==="
VMOPTIONS_FILE="$NEXUS_DIR/bin/nexus.vmoptions"

if [ -f "$VMOPTIONS_FILE" ]; then
    # Делаем бэкап
    sudo cp "$VMOPTIONS_FILE" "$VMOPTIONS_FILE.bak.$(date +%Y%m%d-%H%M%S)"

    # Комментируем строку с которой все не работает
    sudo sed -i 's/^-Djava\.endorsed\.dirs=lib\/endorsed/# -Djava.endorsed.dirs=lib\/endorsed/' "$VMOPTIONS_FILE"

    # Проверка
    if grep -q "^-Djava.endorsed.dirs=lib/endorsed" "$VMOPTIONS_FILE"; then
        echo "ОШИБКА: не удалось закомментировать endorsed.dirs"
        grep endorsed "$VMOPTIONS_FILE"
        exit 1
    else
        echo "Фикс endorsed.dirs успешно применён"
    fi

    # Права 
    sudo chown "$NEXUS_USER:$NEXUS_USER" "$VMOPTIONS_FILE"
    sudo chmod 644 "$VMOPTIONS_FILE"
else
    echo "ВНИМАНИЕ: nexus.vmoptions не найден — фикс пропущен"
fi

echo "=== Установка прав на директории ==="
sudo chown -R "$NEXUS_USER:$NEXUS_USER" "$NEXUS_DIR"
sudo chown -R "$NEXUS_USER:$NEXUS_USER" "$DATA_DIR"

echo "run_as_user=\"$NEXUS_USER\"" | sudo tee "$NEXUS_DIR/bin/nexus.rc"

echo "=== Создание systemd-сервиса ==="
sudo tee /etc/systemd/system/nexus.service > /dev/null <<EOF
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=$NEXUS_USER
Group=$NEXUS_USER
Environment="JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64"
ExecStart=$NEXUS_DIR/bin/nexus start
ExecStop=$NEXUS_DIR/bin/nexus stop
Restart=on-abort
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target
EOF

echo "=== Перезагрузка конфигурации systemd и запуск Nexus ==="
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable nexus --now

echo "Ожидание запуска Nexus (до 3х мин)"
for i in {1..18}; do
    if curl -s -f -I http://localhost:8081/ >/dev/null 2>&1; then
        echo "Nexus успешно запущен!"
        break
    fi
    echo "Ещё не готов... попытка $i/18"
    sleep 10
done

if [ $i -eq 60 ]; then
    echo "Nexus не запустился за 3 мин"
    echo "Проверьте статус:   sudo systemctl status nexus -l"
    echo "Логи Nexus:        tail -n 100 $DATA_DIR/nexus3/log/nexus.log"
    echo "Логи JVM:          tail -n 50  $DATA_DIR/nexus3/log/jvm.log"
    echo "Журнал systemd:    sudo journalctl -u nexus -n 200 --no-pager"
    exit 1
fi

echo "========================================"
echo "Nexus установлен и запущен:"
echo "URL:          http://192.168.1.200:8081"
echo "Логин:        admin"
echo "Пароль:"

sudo cat "$DATA_DIR/nexus3/admin.password" 2>/dev/null || echo "Пароль не найден — смотрите логи"

echo "======================================"

