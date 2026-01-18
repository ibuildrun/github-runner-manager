# Changelog - AVYX Deploy

## [2.0.0] - 2026-01-17

### 🎉 Полная переработка системы деплоя

#### Добавлено
- ✅ Упрощенный workflow для деплоя через self-hosted runner
- ✅ Использование SFTP/lftp для надежной загрузки на shared hosting
- ✅ Автоматическое сохранение и восстановление `.env` между деплоями
- ✅ Раздельная сборка frontend и backend в отдельных jobs
- ✅ PowerShell скрипт `start.ps1` для быстрого запуска runner
- ✅ Batch файл `start-runner.bat` для запуска одним кликом
- ✅ Подробный `QUICK_START.md` с пошаговой инструкцией
- ✅ Обновленный `README.md` с полной документацией
- ✅ Установка `lftp` в Docker образ для SFTP деплоя

#### Изменено
- 🔄 Workflow теперь использует artifacts для передачи собранных файлов
- 🔄 Упрощена структура деплоя - убраны лишние fallback механизмы
- 🔄 Улучшены health checks с более детальной информацией
- 🔄 Telegram уведомления теперь показывают больше деталей

#### Удалено
- ❌ Удален старый `deploy-new.yml` workflow
- ❌ Убраны сложные SSH fallback механизмы
- ❌ Удалена зависимость от webhook деплоя

#### Исправлено
- 🐛 Исправлены проблемы с SSH подключением к REG.RU
- 🐛 Исправлена загрузка файлов на shared hosting
- 🐛 Исправлено сохранение `.env` между деплоями
- 🐛 Исправлены права доступа к директориям storage

### Структура деплоя

```
deploy/
├── start-runner.bat          # Быстрый запуск (Windows)
├── start.ps1                 # PowerShell скрипт запуска
├── QUICK_START.md            # Быстрый старт гайд
├── README.md                 # Полная документация
├── CHANGELOG.md              # Этот файл
├── docker-compose.yml        # Docker конфигурация
├── runner.Dockerfile         # Docker образ runner
├── runner-multi-entrypoint.sh # Entrypoint скрипт
└── .env.runner.example       # Пример конфигурации
```

### Требования

- Docker Desktop
- GitHub Personal Access Token (repo, workflow)
- GitHub Secrets:
  - `HOSTING_PASSWORD`
  - `TELEGRAM_BOT_TOKEN` (опционально)
  - `TELEGRAM_ADMIN_CHAT_ID` (опционально)

### Миграция с предыдущей версии

1. Остановите старый runner: `docker-compose down`
2. Обновите код: `git pull`
3. Пересоздайте runner: `.\start-runner.bat`
4. Проверьте статус на GitHub

---

## [1.0.0] - 2026-01-15

### Первая версия
- Базовый self-hosted runner
- Деплой через SSH/SCP
- Webhook fallback
- Telegram уведомления
