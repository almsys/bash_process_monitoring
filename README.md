Простой скрипт для мониторинга процессов с оповещением Телеграм.
Данный скрипт мониторить сервис, и если он перестает работать, происходит рестарт с оповещеним в телеграм. 

Как использовать:
1. Скопируйте скрипт к себе на компьютер командой - git clone git@github.com:almsys/bash_process_monitoring.git
2. Скопируйте файл process_monitor в директорию /usr/local/bin/ -  cp bash_process_monitoring/process_monitor /usr/local/bin/
3. Дайте права на запуск - chmod +x /usr/local/bin/process_monito
4. Скопируйте systemd unit файл для запуска нашего bash скрипта - cp bash_process_monitoring/process_monitor.service /etc/systemd/system/process_monitor.service
5. Поменяйте внутри реквизиты телеграм бота и пропишите сервис который вы хотите мониторить
