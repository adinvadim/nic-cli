# NIC.RU DNS Skill

Управление DNS-записями через API NIC.RU (RU-CENTER).

## Требования

- Python 3.8+
- Аккаунт NIC.RU с услугой DNS-хостинга
- OAuth2 credentials (APP_LOGIN, APP_PASSWORD)

## Авторизация

Перед использованием нужно получить токен:

```bash
# Установи credentials
export NIC_APP_LOGIN="your_app_login"
export NIC_APP_PASSWORD="your_app_password"
export NIC_USERNAME="your_nic_username"
export NIC_PASSWORD="your_nic_password"

# Или сохрани в файл
cat > ~/.openclaw/workspace/.secrets/nic-ru-credentials <<EOF
NIC_APP_LOGIN=your_app_login
NIC_APP_PASSWORD=your_app_password
NIC_USERNAME=your_nic_username
NIC_PASSWORD=your_nic_password
EOF

# Получи токен
nic-dns auth
```

## Команды

### Список зон
```bash
nic-dns zones
```

### Список записей в зоне
```bash
nic-dns records example.ru
```

### Добавить запись
```bash
# A запись
nic-dns add example.ru A www 1.2.3.4 3600

# CNAME
nic-dns add example.ru CNAME blog www.example.ru 3600

# TXT (для верификации)
nic-dns add example.ru TXT @ "v=spf1 include:_spf.google.com ~all"

# MX
nic-dns add example.ru MX @ "10 mail.example.ru"

# Wildcard
nic-dns add example.ru A "*" 1.2.3.4
```

### Удалить запись
```bash
nic-dns delete example.ru 12345
```

### Обновить запись
```bash
nic-dns update example.ru 12345 5.6.7.8
```

### Применить изменения (commit)
```bash
nic-dns commit example.ru
```

## Типичные сценарии

### Добавить A-запись для сервера
```bash
nic-dns add mysite.ru A @ 203.0.113.50
nic-dns add mysite.ru A www 203.0.113.50
nic-dns commit mysite.ru
```

### Настроить почту (MX + SPF)
```bash
nic-dns add mysite.ru MX @ "10 mx.yandex.net"
nic-dns add mysite.ru TXT @ "v=spf1 redirect=_spf.yandex.net"
nic-dns commit mysite.ru
```

### Верификация домена (Let's Encrypt DNS-01)
```bash
nic-dns add mysite.ru TXT _acme-challenge "токен_от_certbot"
nic-dns commit mysite.ru
# После верификации удалить
nic-dns records mysite.ru | grep _acme-challenge
nic-dns delete mysite.ru <record-id>
nic-dns commit mysite.ru
```

### Wildcard SSL
```bash
nic-dns add mysite.ru TXT "_acme-challenge" "dns-challenge-token"
nic-dns commit mysite.ru
```

## Важно

1. **Commit обязателен** — изменения применяются только после `nic-dns commit <zone>`
2. **TTL по умолчанию** — 3600 секунд (1 час)
3. **@ означает корень** — запись для самого домена без поддомена
4. **Токен живет 1 час** — после истечения нужен `nic-dns auth`

## Устранение проблем

### "Token expired"
```bash
nic-dns auth
```

### "Zone not found"
Проверь список доступных зон:
```bash
nic-dns zones
```

### "Permission denied"
Убедись что OAuth credentials правильные и у приложения есть права на DNS API.
