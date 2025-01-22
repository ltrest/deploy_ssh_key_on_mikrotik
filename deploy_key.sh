#!/bin/bash

# Запрашиваем имя пользователя для подключения по SSH
read -p "Введите имя пользователя для подключения по SSH: " SSH_USER

# Запрашиваем пароль для подключения по SSH
read -s -p "Введите пароль для подключения по SSH: " SSH_PASSWORD
echo

# Путь к файлу со списком IP-адресов
IP_LIST_FILE="device_ip.txt"

# Пользователь, которого нужно создать на удаленной системе
REMOTE_USER="ansi"
REMOTE_PASSWORD="SuperHeavyPass9399@#292&929@992101923039812309"

# Локальный путь к публичному ключу
LOCAL_PUBLIC_KEY="/root/.ssh/id_rsa.pub"

# Название удаленного файла
REMOTE_PUBLIC_KEY="id_rsa.pub"

# Проверяем, существует ли файл со списком IP
if [[ ! -f "$IP_LIST_FILE" ]]; then
    echo "Файл со списком IP-адресов $IP_LIST_FILE не найден!"
    exit 1
fi

# Проверяем, существует ли публичный ключ
if [[ ! -f "$LOCAL_PUBLIC_KEY" ]]; then
    echo "Файл публичного ключа $LOCAL_PUBLIC_KEY не найден!"
    exit 1
fi

# Опции SSH для автоматического добавления в known_hosts
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Цикл по каждому IP-адресу из файла
while IFS= read -r IP; do
    echo "Обрабатывается IP: $IP"

    # Добавляем пользователя на удаленном сервере, используя sshpass
    sshpass -p "$SSH_PASSWORD" ssh $SSH_OPTIONS "${SSH_USER}@${IP}" "/user/add name=${REMOTE_USER} password=${REMOTE_PASSWORD} group=full comment=ansible"
    if [[ $? -ne 0 ]]; then
        echo "Ошибка при создании пользователя на $IP"
        continue
    fi

    # Пауза в 2 секунды
    sleep 2

    # Копируем публичный ключ на удаленный сервер
    sshpass -p "$SSH_PASSWORD" scp $SSH_OPTIONS "$LOCAL_PUBLIC_KEY" "${SSH_USER}@${IP}:$REMOTE_PUBLIC_KEY"
    if [[ $? -ne 0 ]]; then
        echo "Ошибка при копировании публичного ключа на $IP"
        continue
    fi

    # Пауза в 2 секунды
    sleep 2

    # Выполняем команду на удаленном сервере для импорта ключа
    sshpass -p "$SSH_PASSWORD" ssh $SSH_OPTIONS "${SSH_USER}@${IP}" "/user/ssh-keys import user=${REMOTE_USER} public-key-file=${REMOTE_PUBLIC_KEY}"
    if [[ $? -ne 0 ]]; then
        echo "Ошибка при выполнении команды импорта ключа на $IP"
        continue
    fi

    echo "Обработка $IP завершена."
done < "$IP_LIST_FILE"

echo "Скрипт завершен."