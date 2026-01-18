# AVYX Deployment Setup

Автоматический деплой на REG.RU через GitHub Actions Self-Hosted Runner.

## Быстрый старт

```powershell
# Запуск runner одной командой
cd deploy
.\start.ps1
```

## Что это

Self-hosted GitHub Actions runner для автоматического деплоя AVYX на production сервер REG.RU.

### Что включено

- **Node.js 20** + npm для сборки frontend
- **PHP 8.1** + Composer для backend
- **lftp** для надежной загрузки на shared hosting
- **sshpass** для выполнения команд на сервере
- Автоматическая сборка и деплой при push в `main`

## Установка

### 1. Создай GitHub Token

https://github.com/settings/tokens/new

Права: `repo`, `workflow`

⚠️ Используй **Classic Token**, не Fine-grained!

### 2. Настрой конфигурацию

```powershell
cd deploy

# Создай .env.runner из примера
Copy-Item .env.runner.example .env.runner

# Отредактируй и вставь свой токен
notepad .env.runner
```

Вставь свой GitHub token:
```env
GITHUB_TOKEN=ghp_твой_токен_здесь
```

### 3. Настрой GitHub Secrets

Добавь в Settings → Secrets and variables → Actions:

- `HOSTING_PASSWORD`: `ugz3Xb847tUsK1Os`
- `TELEGRAM_BOT_TOKEN`: токен бота для уведомлений
- `TELEGRAM_ADMIN_CHAT_ID`: ID чата для уведомлений

### 4. Запусти runner

```powershell
# Первый запуск
cd deploy
docker-compose up -d --build

# Проверь логи
docker logs -f universal-runner
```

Должно быть:
```
Runner successfully added
Runner connection is good
Listening for Jobs
```

### 5. Проверь на GitHub

https://github.com/ibuildrun/avyx/settings/actions/runners

Должен быть runner со статусом "Idle" 🟢

## Как работает деплой

1. **Push в main** → автоматически запускается workflow
2. **Build Frontend**: собирается React приложение
3. **Prepare Backend**: устанавливаются Composer зависимости
4. **Deploy**: загрузка на REG.RU через SFTP
5. **Post-deploy**: запуск Laravel команд (migrate, cache)
6. **Health Check**: проверка доступности сайта
7. **Telegram**: уведомление о результате

## Управление

```powershell
cd deploy

# Просмотр логов
docker logs -f universal-runner

# Перезапуск
docker-compose restart

# Остановка
docker-compose down

# Обновление после изменений
docker-compose down
docker-compose up -d --build
```

## Ручной деплой

Можно запустить деплой вручную:

1. Открой https://github.com/ibuildrun/avyx/actions/workflows/deploy.yml
2. Нажми "Run workflow"
3. Выбери ветку `main`
4. Нажми "Run workflow"

## Структура на сервере

```
/var/www/u3370847/data/www/avyx.ibuildrun.ru/
├── backend/           # Laravel API
│   ├── app/
│   ├── public/
│   └── .env          # Конфигурация (сохраняется при деплое)
├── public/           # React frontend (собранный)
│   ├── index.html
│   └── assets/
└── shared/           # Общие файлы
    └── .env          # Бэкап .env
```

## Первая настройка .env на сервере

После первого деплоя нужно настроить `.env`:

```bash
# Подключись по SSH
ssh u3370847@server297.hosting.reg.ru

# Перейди в директорию
cd /var/www/u3370847/data/www/avyx.ibuildrun.ru/backend

# Отредактируй .env
nano .env
```

Основные параметры:
```env
APP_KEY=base64:... # Сгенерируй: php artisan key:generate
DB_DATABASE=u3370847_avyx
DB_USERNAME=u3370847_avyx
DB_PASSWORD=твой_пароль_от_БД
TELEGRAM_BOT_TOKEN=твой_токен_бота
```

После сохранения:
```bash
/opt/php/8.3/bin/php artisan config:cache
/opt/php/8.3/bin/php artisan migrate
```

## Автозапуск при старте Windows

Docker Desktop автоматически запускает контейнеры с `restart: unless-stopped`.

Или создай ярлык `start-runner.bat`:
```batch
@echo off
cd %~dp0
docker-compose up -d
pause
```

И добавь в автозагрузку: Win+R → `shell:startup`

## Troubleshooting

### Runner не подключается

```powershell
# Проверь логи
docker logs universal-runner

# Пересоздай runner
docker-compose down
docker-compose up -d --build
```

### Деплой падает с ошибкой SSH

Проверь что в GitHub Secrets добавлен `HOSTING_PASSWORD`.

### Frontend не обновляется

Очисти кэш браузера (Ctrl+Shift+R) или проверь что файлы загрузились на сервер.

### API возвращает 500

Проверь логи Laravel:
```bash
ssh u3370847@server297.hosting.reg.ru
tail -f /var/www/u3370847/data/www/avyx.ibuildrun.ru/backend/storage/logs/laravel.log
```

## Полезные ссылки

- **Production**: https://avyx.ibuildrun.ru
- **API Health**: https://avyx.ibuildrun.ru/api/v1/health
- **GitHub Actions**: https://github.com/ibuildrun/avyx/actions
- **REG.RU Panel**: https://server297.hosting.reg.ru:1500/

## Готово!

Теперь каждый push в `main` автоматически деплоится на production! 🚀
