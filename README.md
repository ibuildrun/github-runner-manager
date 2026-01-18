# GitHub Runner Infrastructure Manager 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows)
[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED.svg)](https://www.docker.com/)
[![Telegram](https://img.shields.io/badge/Telegram-Bot-26A5E4.svg)](https://telegram.org/)

Комплексное решение для управления GitHub Actions self-hosted runners с поддержкой Docker контейнеров и Telegram уведомлений. Полноценный инфраструктурный комбайн для CI/CD.

> **🔒 SECURITY NOTICE:** Version 3.0.2+ removes all hardcoded credentials. If you're using an older version, please update immediately and rotate any exposed credentials.

## 🎯 Возможности

### Базовые функции
- **Поиск репозиториев** - Поиск и выбор через GitHub API
- **Гибкое хранение токенов** - Environment variable, config file или session only
- **Интерактивное меню** - Удобный интерфейс с категориями
- **Авто-запуск** - Запуск runner при старте Windows
- **Мониторинг статуса** - Информация о состоянии в реальном времени
- **Просмотр логов** - Просмотр логов прямо из меню

### 🐳 Docker контейнеры
- **Создание образов** - Автоматическая сборка Docker образов для runners
- **Управление контейнерами** - Запуск, остановка, удаление контейнеров
- **Массовое развертывание** - Запуск множества runners одной командой
- **Изоляция** - Каждый runner в отдельном контейнере
- **Масштабирование** - Легкое добавление новых runners

### 📱 Telegram уведомления
- **Множественные пользователи** - Уведомления для нескольких человек
- **Типы уведомлений** - Info, Success, Warning, Error
- **События** - Старт/стоп runners, развертывание контейнеров
- **Тестирование** - Проверка подключения к боту
- **Управление пользователями** - Добавление/удаление chat ID

## 🚀 Быстрый старт

### Требования

- Windows 10/11
- PowerShell 5.1+
- GitHub Personal Access Token (`repo`, `workflow`)
- Docker Desktop (опционально, для контейнеров)
- Telegram Bot Token (опционально, для уведомлений)

### Установка

```powershell
git clone https://github.com/yourusername/github-runner-infrastructure.git
cd github-runner-infrastructure
.\runner.ps1
```

### Базовая настройка

1. **Настроить GitHub Token** (Опция 1)
   - Создать токен: https://github.com/settings/tokens/new
   - Права: `repo`, `workflow`
   - Выбрать способ хранения

2. **Выбрать репозиторий** (Опция 2)
   - Поиск по вашим репозиториям
   - Выбор репозитория для runner

3. **Установить Runner** (Опция 5)
   - Скачивание и настройка
   - Регистрация в репозитории

4. **Запустить Runner** (Опция 6)
   - Запуск в фоновом режиме

## 📱 Настройка Telegram

### Создание бота

1. Найти @BotFather в Telegram
2. Отправить `/newbot`
3. Следовать инструкциям
4. Сохранить Bot Token

### Получение Chat ID

1. Написать сообщение вашему боту
2. Открыть: `https://api.telegram.org/bot<YOUR_BOT_TOKEN>/getUpdates`
3. Найти `"chat":{"id":123456789}`
4. Использовать это число как Chat ID

### Настройка в скрипте

1. Выбрать **Опция 14** в меню
2. Ввести Bot Token
3. Добавить Chat ID пользователей
4. Протестировать уведомления

## 🐳 Работа с Docker

### Установка Docker

1. Скачать Docker Desktop: https://www.docker.com/products/docker-desktop
2. Установить и запустить
3. Убедиться что Docker работает: `docker --version`

### Создание runner образа

```powershell
# В меню выбрать: 15 -> 1
# Или напрямую:
New-DockerRunnerImage -ImageTag "github-runner:latest"
```

### Запуск контейнера

```powershell
# В меню: 15 -> 2
# Указать имя runner или оставить пустым для авто-генерации
```

### Массовое развертывание

```powershell
# В меню: 15 -> 7
# Указать количество контейнеров (например, 5)
# Все контейнеры будут запущены автоматически
```

### Управление контейнерами

```powershell
# Список контейнеров
docker ps -a

# Остановка
docker stop <container_name>

# Удаление
docker rm <container_name>

# Логи
docker logs <container_name>
```

## 📋 Структура меню

### Configuration
- **1** - Configure GitHub Token
- **2** - Select Repository
- **3** - Configure GitHub Secrets (Auto)
- **4** - View Configured Secrets

### Runner Management
- **5** - Install Runner
- **6** - Start Runner
- **7** - Stop Runner
- **8** - Check Status
- **9** - View Logs

### Auto-Start
- **10** - Enable Auto-Start (on boot)
- **11** - Disable Auto-Start

### Advanced
- **12** - Uninstall Runner
- **13** - Clear Configuration

### Infrastructure Suite 🐳📱
- **14** - Telegram Notifications
- **15** - Docker Container Management

## 🏗️ Архитектура

```
github-runner-infrastructure/
├── runner.ps1                    # Главный скрипт
├── lib/                          # Модули
│   ├── Config.ps1                # Управление конфигурацией
│   ├── GitHub.ps1                # GitHub API
│   ├── UI.ps1                    # Интерфейс
│   ├── TokenManager.ps1          # Управление токенами
│   ├── RepositorySelector.ps1    # Выбор репозитория
│   ├── SecretsManager.ps1        # GitHub secrets
│   ├── RunnerInstaller.ps1       # Установка runner
│   ├── RunnerManager.ps1         # Управление процессами
│   ├── AutoStart.ps1             # Авто-запуск
│   ├── TelegramNotifier.ps1      # Telegram интеграция
│   └── DockerManager.ps1         # Docker управление
├── .runner-config.json           # Конфигурация (auto-generated)
├── README.md                     # Документация
├── CHANGELOG.md                  # История версий
└── LICENSE                       # MIT лицензия
```

## 🔧 Конфигурация

### Формат .runner-config.json

```json
{
  "Repository": "owner/repo-name",
  "TokenStorage": "Environment|File|None",
  "TokenEncrypted": "base64-encoded-token",
  "LastUpdated": "2026-01-17T...",
  "Telegram": {
    "BotToken": "123456:ABC-DEF...",
    "ChatIds": ["123456789", "987654321"],
    "Enabled": true
  },
  "DockerRunners": [
    {
      "ContainerId": "abc123...",
      "Repository": "owner/repo",
      "RunnerName": "docker-runner-1",
      "ImageTag": "github-runner:latest",
      "Created": "2026-01-17T...",
      "Status": "Running"
    }
  ]
}
```

## 🎯 Примеры использования

### Сценарий 1: Локальный runner

```powershell
.\runner.ps1
# 1 -> Настроить токен
# 2 -> Выбрать репозиторий
# 5 -> Установить runner
# 6 -> Запустить runner
# 10 -> Включить авто-запуск
```

### Сценарий 2: Docker runners с уведомлениями

```powershell
.\runner.ps1
# 1 -> Настроить токен
# 2 -> Выбрать репозиторий
# 14 -> Настроить Telegram
# 15 -> Docker Management
#   1 -> Создать образ
#   7 -> Массовое развертывание (5 контейнеров)
```

### Сценарий 3: Мониторинг инфраструктуры

```powershell
.\runner.ps1
# 8 -> Проверить статус
# 15 -> Docker Management
#   3 -> Список контейнеров
#   6 -> Просмотр логов
```

## 🔐 Безопасность

- Никогда не коммитьте `.runner-config.json` (уже в .gitignore)
- Environment variable безопаснее чем file storage
- Base64 это НЕ шифрование - используйте environment variable
- Регулярно обновляйте GitHub токены
- Используйте минимальные необходимые права для токенов
- Храните Telegram Bot Token в безопасности

## 🐛 Решение проблем

### Docker не запускается

```powershell
# Проверить установку
docker --version

# Проверить что Docker Desktop запущен
docker ps
```

### Telegram уведомления не приходят

1. Проверить Bot Token
2. Убедиться что написали боту первое сообщение
3. Проверить Chat ID через API
4. Протестировать через опцию 14 -> 4

### Runner показывает offline

1. Проверить процесс: `Get-Process -Name "Runner.Listener"`
2. Просмотреть логи: Опция 9
3. Перезапустить: Опция 7 -> Опция 6

## 📊 Производительность

### Рекомендации для Docker

- Используйте SSD для Docker volumes
- Минимум 2GB RAM на контейнер
- Проводное подключение для стабильности
- Мониторьте использование диска

### Масштабирование

- До 10 контейнеров на обычном ПК
- До 50+ на серверном железе
- Используйте Docker Swarm для кластеров
- Настройте load balancing для больших нагрузок

## 🤝 Вклад в проект

Приветствуются Pull Requests!

1. Fork репозитория
2. Создать feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit изменений (`git commit -m 'Add AmazingFeature'`)
4. Push в branch (`git push origin feature/AmazingFeature`)
5. Открыть Pull Request

## 📝 Лицензия

MIT License - см. [LICENSE](LICENSE)

## 🔗 Полезные ссылки

- [GitHub Token](https://github.com/settings/tokens/new)
- [GitHub Actions Docs](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [PowerShell Docs](https://docs.microsoft.com/en-us/powershell/)

## 🌟 Особенности

- ✅ Полностью на PowerShell - нет зависимостей
- ✅ Модульная архитектура - легко расширять
- ✅ Docker интеграция - современная контейнеризация
- ✅ Telegram боты - мгновенные уведомления
- ✅ Множественные пользователи - командная работа
- ✅ Массовое развертывание - быстрое масштабирование
- ✅ Open Source - MIT лицензия

---

Made with ❤️ for DevOps community
