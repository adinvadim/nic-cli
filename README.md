# NIC.RU DNS Skill for OpenClaw

Управление DNS-записями через REST API NIC.RU (RU-CENTER).

## Установка

### 1. Добавьте skill в OpenClaw

```bash
# Skill уже находится в
~/.openclaw/workspace/skills/nic-ru/

# Или клонируйте из репозитория
git clone https://github.com/adinvadim-dev/openclaw-nic-ru-skill.git \
    ~/.openclaw/workspace/skills/nic-ru
```

### 2. Сделайте скрипт исполняемым и добавьте в PATH

```bash
chmod +x ~/.openclaw/workspace/skills/nic-ru/scripts/nic-dns
chmod +x ~/.openclaw/workspace/skills/nic-ru/scripts/auth.sh

# Добавьте в ~/.zshrc или ~/.bashrc:
export PATH="$PATH:$HOME/.openclaw/workspace/skills/nic-ru/scripts"
```

### 3. Установите зависимости

```bash
pip install requests
```

### 4. Получите OAuth2 credentials

1. Войдите в [личный кабинет NIC.RU](https://www.nic.ru/manager/)
2. Перейдите в раздел [OAuth приложения](https://www.nic.ru/manager/oauth.cgi)
3. Создайте новое приложение или используйте существующее
4. Скопируйте `App Login` и `App Password`

### 5. Настройте авторизацию

```bash
# Вариант 1: Интерактивная настройка
./auth.sh setup

# Вариант 2: Ручное создание файла
cat > ~/.openclaw/workspace/.secrets/nic-ru-credentials <<EOF
NIC_APP_LOGIN=your_oauth_app_login
NIC_APP_PASSWORD=your_oauth_app_password  
NIC_USERNAME=your_nic_ru_login
NIC_PASSWORD=your_nic_ru_password
EOF
chmod 600 ~/.openclaw/workspace/.secrets/nic-ru-credentials

# Получите токен
nic-dns auth
```

## Использование

### Список зон

```bash
nic-dns zones
nic-dns zones --json
```

### Записи в зоне

```bash
nic-dns records example.ru
nic-dns records example.ru --json
```

### Добавление записей

```bash
# A-запись
nic-dns add example.ru A www 1.2.3.4
nic-dns add example.ru A @ 1.2.3.4 3600

# AAAA (IPv6)
nic-dns add example.ru AAAA www 2001:db8::1

# CNAME
nic-dns add example.ru CNAME blog www.example.ru

# MX (формат: "priority exchange")
nic-dns add example.ru MX @ "10 mail.example.ru"

# TXT
nic-dns add example.ru TXT @ "v=spf1 include:_spf.google.com ~all"

# NS
nic-dns add example.ru NS @ ns1.example.ru

# Wildcard
nic-dns add example.ru A "*" 1.2.3.4
```

### Удаление записей

```bash
# Сначала найди ID записи
nic-dns records example.ru

# Удали по ID
nic-dns delete example.ru 123456
```

### Обновление записей

```bash
nic-dns update example.ru 123456 5.6.7.8
nic-dns update example.ru 123456 5.6.7.8 --ttl 7200
```

### Применение изменений

**Важно!** Изменения не применяются автоматически. Нужен commit:

```bash
nic-dns commit example.ru
```

### Откат изменений

```bash
nic-dns rollback example.ru
```

## API Reference

### Endpoints

| Метод | Endpoint | Описание |
|-------|----------|----------|
| GET | `/services/` | Список DNS-услуг |
| GET | `/services/{service}/zones/{zone}/records` | Записи зоны |
| PUT | `/services/{service}/zones/{zone}/records` | Добавить запись |
| DELETE | `/services/{service}/zones/{zone}/records/{id}` | Удалить запись |
| POST | `/services/{service}/zones/{zone}/commit` | Применить изменения |
| POST | `/services/{service}/zones/{zone}/rollback` | Откатить изменения |

### Типы записей

- `A` — IPv4 адрес
- `AAAA` — IPv6 адрес  
- `CNAME` — каноническое имя (алиас)
- `MX` — почтовый сервер
- `TXT` — текстовая запись (SPF, DKIM, верификация)
- `NS` — сервер имён
- `SRV` — сервис

### Формат ответа

API возвращает XML. Скрипт парсит и выводит в удобном формате.

## Типичные сценарии

### Настройка сайта

```bash
# A-записи для домена
nic-dns add mysite.ru A @ 203.0.113.50
nic-dns add mysite.ru A www 203.0.113.50
nic-dns commit mysite.ru
```

### Настройка почты (Yandex 360)

```bash
nic-dns add mysite.ru MX @ "10 mx.yandex.net"
nic-dns add mysite.ru TXT @ "v=spf1 redirect=_spf.yandex.net"
nic-dns commit mysite.ru
```

### Let's Encrypt DNS-01 Challenge

```bash
# Добавь challenge
nic-dns add mysite.ru TXT _acme-challenge "challenge_token_here"
nic-dns commit mysite.ru

# После верификации — удали
nic-dns records mysite.ru | grep _acme-challenge
nic-dns delete mysite.ru <record-id>
nic-dns commit mysite.ru
```

### Wildcard SSL

```bash
nic-dns add mysite.ru TXT "_acme-challenge" "dns_challenge_token"
nic-dns commit mysite.ru
```

## Устранение проблем

### Token expired
```bash
nic-dns auth
```

### Permission denied
Проверьте что у OAuth приложения есть scope для DNS API.

### Zone not found
```bash
nic-dns zones  # Посмотрите доступные зоны
```

### Invalid credentials
```bash
# Проверьте файл credentials
cat ~/.openclaw/workspace/.secrets/nic-ru-credentials

# Пересоздайте
./auth.sh setup
```

## Безопасность

- Credentials хранятся в `~/.openclaw/workspace/.secrets/` с правами `600`
- Токен автоматически обновляется при истечении
- Не коммитьте credentials в git

## Ссылки

- [NIC.RU API Documentation (PDF)](https://www.nic.ru/help/upload/file/API_DNS-hosting.pdf)
- [NIC.RU Help: API DNS-хостинга](https://www.nic.ru/help/api-dns-hostinga_3643.html)
- [OAuth Applications](https://www.nic.ru/manager/oauth.cgi)

## License

MIT
