# Инструкция по установке Process Monitor

## Быстрая установка

### 1. Установка скрипта

```bash
# Скопируйте скрипт
sudo cp process_monitor.sh /usr/local/bin/process_monitor
sudo chmod +x /usr/local/bin/process_monitor
```

### 2. Создание конфигурационного файла

```bash
# Создайте конфигурационный файл
sudo nano /etc/process_monitor.conf
```

Вставьте содержимое из `process_monitor.conf` и отредактируйте:
- `TELEGRAM_API_TOKEN` - токен вашего бота
- `CHAT_ID` - ID вашего чата
- `CHECK_INTERVAL` - интервал проверки (в секундах)

### 3. Установка systemd unit

```bash
# Скопируйте unit файл
sudo cp process-monitor@.service /etc/systemd/system/

# Перезагрузите systemd
sudo systemctl daemon-reload
```

## Использование

### Мониторинг одного сервиса

```bash
# Запуск
sudo systemctl start process-monitor@nginx.service

# Автозапуск
sudo systemctl enable process-monitor@nginx.service

# Проверка статуса
sudo systemctl status process-monitor@nginx.service
```

### Мониторинг нескольких сервисов

#### Вариант 1: Несколько unit'ов (рекомендуется для критичных сервисов)

```bash
# Каждый сервис - отдельный unit
sudo systemctl enable --now process-monitor@nginx.service
sudo systemctl enable --now process-monitor@mysql.service
sudo systemctl enable --now process-monitor@redis.service
```

#### Вариант 2: Один unit для всех сервисов

Создайте отдельный unit файл:

```bash
sudo nano /etc/systemd/system/process-monitor-all.service
```

```ini
[Unit]
Description=Process Monitor for Multiple Services
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/process_monitor nginx mysql redis
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

Затем:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now process-monitor-all.service
```

### Просмотр логов

```bash
# Логи конкретного сервиса
sudo journalctl -u process-monitor@nginx.service -f

# Логи всех мониторов
sudo journalctl -u 'process-monitor*' -f

# Последние 100 строк
sudo journalctl -u process-monitor@nginx.service -n 100
```

## Управление

### Остановка мониторинга

```bash
sudo systemctl stop process-monitor@nginx.service
```

### Отключение автозапуска

```bash
sudo systemctl disable process-monitor@nginx.service
```

### Перезапуск мониторинга

```bash
sudo systemctl restart process-monitor@nginx.service
```

## Примеры использования

### Мониторинг веб-стека

```bash
sudo systemctl enable --now process-monitor@nginx.service
sudo systemctl enable --now process-monitor@php-fpm.service
sudo systemctl enable --now process-monitor@mysql.service
```

### Мониторинг с кастомным конфигом

```bash
# Создайте отдельный конфиг
sudo nano /etc/process_monitor_prod.conf

# Запустите с указанием конфига
/usr/local/bin/process_monitor --config /etc/process_monitor_prod.conf nginx mysql
```

### Тестирование скрипта вручную

```bash
# Запуск в foreground режиме
sudo /usr/local/bin/process_monitor nginx

# С дебагом
sudo bash -x /usr/local/bin/process_monitor nginx
```

## Проверка работоспособности

### 1. Проверка конфигурации

```bash
# Проверьте, что конфиг корректный
sudo cat /etc/process_monitor.conf
```

### 2. Тест отправки уведомлений

Остановите сервис и проверьте, что придет уведомление:

```bash
sudo systemctl stop nginx
# Подождите до 60 секунд
# Проверьте Telegram - должно прийти уведомление
sudo systemctl start nginx
```

### 3. Проверка логов

```bash
sudo journalctl -u process-monitor@nginx.service --since "5 minutes ago"
```

## Troubleshooting

### Уведомления не приходят

```bash
# Проверьте curl
curl -X POST "https://api.telegram.org/bot<YOUR_TOKEN>/sendMessage" \
  -d "chat_id=<YOUR_CHAT_ID>&text=Test"

# Проверьте конфиг
sudo cat /etc/process_monitor.conf
```

### Сервис не запускается

```bash
# Смотрим ошибки
sudo journalctl -u process-monitor@nginx.service -n 50

# Проверяем права
ls -la /usr/local/bin/process_monitor
```

### Ложные срабатывания

Увеличьте `RESTART_DELAY` в конфиге:

```bash
sudo nano /etc/process_monitor.conf
# Установите RESTART_DELAY=5
```

## Дополнительные возможности

### Мониторинг с разными интервалами

Создайте отдельные конфиги для разных групп сервисов:

```bash
# Критичные сервисы (проверка каждые 30 секунд)
/etc/process_monitor_critical.conf
CHECK_INTERVAL=30

# Обычные сервисы (проверка каждые 5 минут)
/etc/process_monitor_normal.conf
CHECK_INTERVAL=300
```

### Мониторинг на нескольких серверах

Установите разные `HOSTNAME` в конфиге каждого сервера:

```bash
HOSTNAME="web-server-01"
HOSTNAME="db-server-01"
```

Это поможет определить, с какого сервера пришло уведомление.
