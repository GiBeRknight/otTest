# OTRS / Znuny Community — Docker Setup

Znuny — это открытый форк OTRS Community Edition, активно поддерживаемый сообществом.

---

## Быстрый старт

### 1. Скопировать и заполнить `.env`

```bash
cp .env.example .env
# Отредактировать .env: задать пароли БД и почтовые реквизиты
```

> **Важно:** `.env` добавлен в `.gitignore` — его содержимое никогда не попадает в репозиторий.

### 2. Запустить контейнеры

```bash
docker compose up -d
```

Дождаться, пока оба контейнера перейдут в состояние `healthy`:

```bash
docker compose ps
```

### 3. Первоначальная настройка (веб-установщик)

Открыть в браузере: **http://localhost:8080/otrs/installer.pl**

Пройти мастер установки:
- Database: `otrs` / пароль из `.env`
- Admin email: `k.zubritskyi@audentes.it`
- Организация: `Audentes`

### 4. Настроить почту одной командой

```bash
./scripts/setup-email.sh
```

Скрипт автоматически настроит:
- **Исходящую почту** — SMTP Google Workspace (`smtp.gmail.com:587`, STARTTLS)
- **Входящую почту** — IMAPS Google Workspace (`imap.gmail.com:993`)

---

## Параметры email (Google Workspace)

| Параметр       | Значение                    |
|----------------|-----------------------------|
| IMAP хост      | `imap.gmail.com`            |
| IMAP порт      | `993` (SSL/TLS)             |
| SMTP хост      | `smtp.gmail.com`            |
| SMTP порт      | `587` (STARTTLS)            |
| Логин          | `k.zubritskyi@audentes.it`  |
| Пароль         | App Password из Google      |

> App Password генерируется в: Google Account → Безопасность → Двухэтапная аутентификация → Пароли приложений

---

## Структура файлов

```
.
├── docker-compose.yml          # Znuny + MariaDB
├── .env                        # Реальные credentials (gitignored)
├── .env.example                # Шаблон переменных
├── .gitignore
├── config/
│   └── mysql.cnf               # Оптимизация MariaDB для OTRS
└── scripts/
    └── setup-email.sh          # Автонастройка почты после установки
```

---

## Полезные команды

```bash
# Просмотр логов Znuny
docker compose logs -f znuny

# Просмотр логов БД
docker compose logs -f db

# Остановить всё
docker compose down

# Остановить и удалить данные (осторожно!)
docker compose down -v

# Войти в контейнер Znuny
docker exec -it otrs-app bash

# Проверить почтовые аккаунты
docker exec otrs-app perl /opt/otrs/bin/otrs.Console.pl Admin::MailAccount::List
```

---

## Ссылки после запуска

| Ресурс         | URL                                                |
|----------------|----------------------------------------------------|
| Агентский интерфейс | http://localhost:8080/otrs/index.pl           |
| Пользовательский портал | http://localhost:8080/otrs/customer.pl   |
| Панель администратора | http://localhost:8080/otrs/index.pl?Action=Admin |
| Настройки почты | http://localhost:8080/otrs/index.pl?Action=AdminMailAccount |

---

## Требования

- Docker 20.10+
- Docker Compose v2+
- Порт 8080 свободен (или изменить `HTTP_PORT` в `.env`)
