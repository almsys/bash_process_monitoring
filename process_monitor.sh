#!/bin/bash

# Конфигурационный файл
CONFIG_FILE="/etc/process_monitor.conf"

# Значения по умолчанию
DEFAULT_CHECK_INTERVAL=60
DEFAULT_RESTART_DELAY=2

# Загрузка конфигурации
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo "Warning: Config file $CONFIG_FILE not found. Using defaults."
    fi
    
    # Установка значений по умолчанию, если не указаны в конфиге
    TELEGRAM_API_TOKEN="${TELEGRAM_API_TOKEN:-}"
    CHAT_ID="${CHAT_ID:-}"
    CHECK_INTERVAL="${CHECK_INTERVAL:-$DEFAULT_CHECK_INTERVAL}"
    RESTART_DELAY="${RESTART_DELAY:-$DEFAULT_RESTART_DELAY}"
    HOSTNAME="${HOSTNAME:-$(hostname)}"
}

# Проверка наличия Telegram настроек
check_telegram_config() {
    if [ -z "$TELEGRAM_API_TOKEN" ] || [ -z "$CHAT_ID" ]; then
        echo "Error: TELEGRAM_API_TOKEN and CHAT_ID must be set in $CONFIG_FILE"
        exit 1
    fi
}

# Отправка уведомления в Telegram
send_telegram_notification() {
    local message="$1"
    local full_message="[${HOSTNAME}] $message"
    
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_API_TOKEN}/sendMessage" \
        -d "chat_id=${CHAT_ID}" \
        -d "text=${full_message}" \
        -d "parse_mode=HTML" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Notification sent: $message"
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to send notification: $message"
    fi
}

# Проверка статуса сервиса
check_service_status() {
    systemctl is-active --quiet "$1"
}

# Проверка существования сервиса
check_service_exists() {
    systemctl list-unit-files | grep -q "^$1.service"
}

# Перезапуск сервиса
restart_service() {
    local service="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Attempting to restart $service..."
    
    systemctl restart "$service"
    sleep "$RESTART_DELAY"
    
    if check_service_status "$service"; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Successfully restarted $service"
        return 0
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to restart $service"
        return 1
    fi
}

# Основная функция мониторинга
monitor_services() {
    local services=("$@")
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting monitoring for: ${services[*]}"
    send_telegram_notification "🟢 Monitoring started for: ${services[*]}"
    
    while true; do
        for service in "${services[@]}"; do
            if check_service_exists "$service"; then
                if ! check_service_status "$service"; then
                    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Service $service is DOWN"
                    send_telegram_notification "⚠️ Service <b>$service</b> is not running. Attempting restart..."
                    
                    if restart_service "$service"; then
                        send_telegram_notification "✅ Service <b>$service</b> successfully restarted"
                    else
                        send_telegram_notification "❌ Service <b>$service</b> restart FAILED"
                    fi
                fi
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️ Service $service does not exist"
                send_telegram_notification "⚠️ Service <b>$service</b> does not exist on this system"
                # Удаляем несуществующий сервис из списка мониторинга
                services=("${services[@]/$service}")
            fi
        done
        
        sleep "$CHECK_INTERVAL"
    done
}

# Показать использование
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] <service1> [service2] [service3] ...

Options:
    -c, --config FILE    Use custom config file (default: /etc/process_monitor.conf)
    -h, --help          Show this help message

Examples:
    $0 nginx
    $0 nginx mysql redis
    $0 --config /path/to/config.conf nginx

Config file format ($CONFIG_FILE):
    TELEGRAM_API_TOKEN="your_bot_token"
    CHAT_ID="your_chat_id"
    CHECK_INTERVAL=60
    RESTART_DELAY=2
    HOSTNAME="custom-hostname"
EOF
}

# Обработка аргументов командной строки
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                SERVICES+=("$1")
                shift
                ;;
        esac
    done
}

# Проверка прав root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Error: This script must be run as root"
        exit 1
    fi
}

# Главная функция
main() {
    local SERVICES=()
    
    parse_arguments "$@"
    
    if [ ${#SERVICES[@]} -eq 0 ]; then
        echo "Error: No services specified"
        show_usage
        exit 1
    fi
    
    check_root
    load_config
    check_telegram_config
    
    monitor_services "${SERVICES[@]}"
}

# Запуск скрипта
main "$@"
