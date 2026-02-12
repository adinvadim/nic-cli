---
name: nic-ru
description: Управляй DNS-записями NIC.RU (RU-CENTER) через CLI nic-dns: проверяй зоны и записи, добавляй/удаляй записи, делай commit/rollback и помогай с DNS-01/почтовыми настройками. Используй, когда пользователь просит изменить DNS у доменов на NIC.RU или диагностировать проблемы с зонами/записями.
metadata: {"openclaw":{"emoji":"🌐","homepage":"https://www.nic.ru/help/upload/file/API_DNS-hosting.pdf","requires":{"bins":["python3"]}}}
---

# NIC.RU DNS CLI (nic-dns)

Используй CLI из этого skill:
- `{baseDir}/scripts/nic-dns`
- `{baseDir}/scripts/auth.sh`

Если `nic-dns` не в PATH, запускай через абсолютный путь: `{baseDir}/scripts/nic-dns ...`.

## Быстрый рабочий поток

1. Проверь, что есть доступ к учётным данным в `~/.openclaw/workspace/.secrets/nic-ru-credentials` или через env.
2. Обнови токен: `nic-dns auth`.
3. Проверь текущие записи: `nic-dns records <zone>`.
4. Выполни изменение (`add`/`delete`/`update`).
5. Обязательно зафиксируй: `nic-dns commit <zone>`.
6. Повтори `records` и убедись, что запись появилась/исчезла.

## Команды

```bash
nic-dns auth
nic-dns zones
nic-dns records <zone>
nic-dns add <zone> <TYPE> <name> <value> [ttl]
nic-dns delete <zone> <record_id>
nic-dns update <zone> <record_id> <value> [--ttl N]
nic-dns commit <zone>
nic-dns rollback <zone>
```

## Шаблоны изменений

```bash
# A / root
nic-dns add example.ru A @ 1.2.3.4 3600

# CNAME
nic-dns add example.ru CNAME www app.example.com 3600

# TXT (SPF / верификация)
nic-dns add example.ru TXT @ "v=spf1 include:_spf.google.com ~all"

# MX
nic-dns add example.ru MX @ "10 mx.yandex.net"

# DNS-01
nic-dns add example.ru TXT _acme-challenge "<challenge-token>"
nic-dns commit example.ru
```

## Правила безопасности

- Никогда не печатай реальные логины/пароли/токены в ответ пользователю.
- Никогда не коммить `~/.openclaw/workspace/.secrets/*`.
- Перед публикацией репозитория проверяй tracked-файлы на секреты.

## Диагностика

- `Token expired` → `nic-dns auth`.
- `Zone not found` → `nic-dns zones`, затем проверь service/домен.
- API 401/403 → проверь OAuth credentials и права приложения.
- Изменение «не видно» → проверь, что был `commit`, и учитывай TTL/кэш DNS.
