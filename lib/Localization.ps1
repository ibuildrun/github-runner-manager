# Localization Module
# Provides multi-language support for the application

# Global variable to store current language
$script:CurrentLanguage = "en"

# Translation dictionary
$script:Translations = @{
    "en" = @{
        # Menu
        "menu_title" = "Runner Manager"
        "menu_subtitle" = "Advanced Infrastructure Suite"
        "menu_platform" = "Platform"
        "menu_instance" = "Instance"
        "menu_repository" = "Repository"
        "menu_group" = "Group"
        "menu_project" = "Project"
        "menu_target" = "Target"
        "menu_not_configured" = "Not configured"
        "menu_token" = "Token"
        "menu_configured" = "Configured"
        "menu_not_set" = "Not set"
        "menu_telegram" = "Telegram"
        "menu_enabled" = "Enabled"
        "menu_disabled" = "Disabled"
        "menu_users" = "users"
        "menu_docker_runners" = "Docker Runners"
        "menu_containers" = "containers"
        "menu_local_runners" = "Local Runners"
        "menu_active_runner" = "Active Runner"
        "menu_path" = "Path"
        
        # Common
        "invalid_option" = "Invalid option. Please try again."
        "press_enter" = "Press Enter to continue"
        "goodbye" = "Thank you for using Octopus Runner Manager!"
        "cancelled" = "Cancelled"
        "error" = "Error"
        "success" = "Success"
        "warning" = "Warning"
        "yes" = "yes"
        "no" = "no"
        
        # Platform
        "platform_github" = "GitHub Actions"
        "platform_gitlab" = "GitLab CI/CD"
        "platform_selection_title" = "Platform Selection"
        "platform_select_prompt" = "Select platform:"
        "platform_invalid" = "Invalid selection"
        
        # Target Type
        "target_type_title" = "Target Type Selection"
        "target_type_prompt" = "Select target type:"
        "target_type_project" = "Project (single repository)"
        "target_type_group" = "Group (multiple projects)"
        
        # Token Configuration
        "token_config_title" = "{0} Token Configuration"
        "token_config_help_github" = "Required permissions:"
        "token_config_perm_repo" = "repo (Full control of private repositories)"
        "token_config_perm_workflow" = "workflow (Update GitHub Action workflows)"
        "token_config_perm_api" = "api (Full API access)"
        "token_config_create_github" = "Create token at: https://github.com/settings/tokens"
        "token_config_create_gitlab" = "Create token at: {0}/-/profile/personal_access_tokens"
        "token_config_create_gitlab_self" = "For self-hosted: https://your-gitlab.com/-/profile/personal_access_tokens"
        "token_current" = "Current token"
        "token_update" = "Update token? (y/n)"
        "token_enter" = "Enter your {0} token"
        "token_saved" = "Token saved successfully"
        
        # Token Storage
        "token_storage_question" = "How would you like to store the token?"
        "token_storage_env" = "Environment Variable (persistent, survives restarts)"
        "token_storage_file" = "Encrypted File (stored in config file)"
        "token_storage_session" = "Session Only (temporary, lost on exit)"
        
        # Repository Selection
        "repo_selection_title" = "{0} Selection"
        "repo_token_not_configured" = "{0} token not configured"
        "repo_configure_token_first" = "Please configure your token first (Option 1)"
        "repo_fetching" = "Fetching {0}..."
        "repo_projects" = "projects"
        "repo_groups" = "groups"
        "repo_repositories" = "repositories"
        "repo_none_found" = "No {0} found"
        "repo_search_prompt" = "Search {0} (enter part of name):"
        "repo_search" = "Search"
        "repo_no_match" = "No {0} matching '{1}'"
        "repo_found" = "Found {0} {1}"
        "repo_select_prompt" = "Select {0} (1-{1})"
        "repo_set_to" = "{0} set to: {1}"
        "repo_error_fetching" = "Error fetching {0}: {1}"
        
        # Runner Status
        "status_title" = "Runner Status"
        "status_repository" = "Repository"
        "status_token" = "Token"
        "status_installation" = "Installation"
        "status_installed_at" = "Installed at {0}"
        "status_not_installed" = "Not installed"
        "status_autostart" = "Auto-Start"
        "status_process" = "Process"
        "status_running_pid" = "Running (PID: {0})"
        "status_not_running" = "Not running"
        
        # Multi-Runner
        "multirunner_title" = "Multi-Runner Management"
        "multirunner_local_runners" = "Local Runners"
        "multirunner_no_runners" = "No local runners configured"
        "multirunner_tip" = "Tip: Use option 1 to add a new runner"
        "multirunner_add" = "Add new runner"
        "multirunner_select" = "Select active runner"
        "multirunner_remove" = "Remove runner"
        "multirunner_back" = "Back to main menu"
        "multirunner_add_title" = "Add New Local Runner"
        "multirunner_enter_name" = "Enter runner name (e.g., 'Main Runner', 'Backup Runner'):"
        "multirunner_name" = "Name"
        "multirunner_name_empty" = "Runner name cannot be empty"
        "multirunner_enter_path" = "Enter runner installation path:"
        "multirunner_example" = "Example"
        "multirunner_path" = "Path"
        "multirunner_using_default" = "Using default path: {0}"
        "multirunner_path_exists" = "Warning: Path already exists. Runner may already be installed."
        "multirunner_continue" = "Continue anyway? (y/n)"
        "multirunner_current_repo" = "Current repository: {0}"
        "multirunner_use_current" = "Use current repository? (y/n)"
        "multirunner_enter_repo" = "Enter repository (owner/repo):"
        "multirunner_repo_empty" = "Repository cannot be empty"
        "multirunner_added" = "Runner added successfully!"
        "multirunner_runner_id" = "Runner ID: {0}"
        "multirunner_next_steps" = "Next steps:"
        "multirunner_step_select" = "Select this runner as active (option 2)"
        "multirunner_step_install" = "Install the runner (option 5 in main menu)"
        "multirunner_select_title" = "Select Active Runner"
        "multirunner_no_runners_add" = "No runners configured. Add a runner first."
        "multirunner_cancel" = "Cancel"
        "multirunner_invalid_selection" = "Invalid selection"
        "multirunner_active_set" = "Active runner set to: {0}"
        "multirunner_remove_title" = "Remove Local Runner"
        "multirunner_remove_warning" = "Warning: This will remove runner configuration"
        "multirunner_remove_files_kept" = "Runner files in {0} will NOT be deleted"
        "multirunner_confirm" = "Are you sure? (yes/no)"
        "multirunner_removed" = "Runner removed from configuration"
        
        # Docker
        "docker_title" = "Docker Container Management"
        "docker_not_installed" = "Docker is not installed or not in PATH"
        "docker_install_prompt" = "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
        "docker_not_running" = "Docker daemon is not running"
        "docker_start_prompt" = "Please start Docker Desktop and try again"
        "docker_checking" = "Checking Docker status..."
        "docker_available" = "Docker is available"
    }
    
    "ru" = @{
        # Меню
        "menu_title" = "Менеджер Runner'ов"
        "menu_subtitle" = "Продвинутый набор инфраструктуры"
        "menu_platform" = "Платформа"
        "menu_instance" = "Инстанс"
        "menu_repository" = "Репозиторий"
        "menu_group" = "Группа"
        "menu_project" = "Проект"
        "menu_target" = "Цель"
        "menu_not_configured" = "Не настроено"
        "menu_token" = "Токен"
        "menu_configured" = "Настроен"
        "menu_not_set" = "Не установлен"
        "menu_telegram" = "Telegram"
        "menu_enabled" = "Включен"
        "menu_disabled" = "Отключен"
        "menu_users" = "пользователей"
        "menu_docker_runners" = "Docker Runner'ы"
        "menu_containers" = "контейнеров"
        "menu_local_runners" = "Локальные Runner'ы"
        "menu_active_runner" = "Активный Runner"
        "menu_path" = "Путь"
        
        # Общее
        "invalid_option" = "Неверная опция. Попробуйте снова."
        "press_enter" = "Нажмите Enter для продолжения"
        "goodbye" = "Спасибо за использование Octopus Runner Manager!"
        "cancelled" = "Отменено"
        "error" = "Ошибка"
        "success" = "Успешно"
        "warning" = "Предупреждение"
        "yes" = "да"
        "no" = "нет"
        
        # Платформа
        "platform_github" = "GitHub Actions"
        "platform_gitlab" = "GitLab CI/CD"
        "platform_selection_title" = "Выбор платформы"
        "platform_select_prompt" = "Выберите платформу:"
        "platform_invalid" = "Неверный выбор"
        
        # Тип цели
        "target_type_title" = "Выбор типа цели"
        "target_type_prompt" = "Выберите тип цели:"
        "target_type_project" = "Проект (один репозиторий)"
        "target_type_group" = "Группа (несколько проектов)"
        
        # Настройка токена
        "token_config_title" = "Настройка токена {0}"
        "token_config_help_github" = "Требуемые разрешения:"
        "token_config_perm_repo" = "repo (Полный контроль приватных репозиториев)"
        "token_config_perm_workflow" = "workflow (Обновление GitHub Action workflows)"
        "token_config_perm_api" = "api (Полный доступ к API)"
        "token_config_create_github" = "Создать токен: https://github.com/settings/tokens"
        "token_config_create_gitlab" = "Создать токен: {0}/-/profile/personal_access_tokens"
        "token_config_create_gitlab_self" = "Для self-hosted: https://your-gitlab.com/-/profile/personal_access_tokens"
        "token_current" = "Текущий токен"
        "token_update" = "Обновить токен? (y/n)"
        "token_enter" = "Введите ваш {0} токен"
        "token_saved" = "Токен успешно сохранен"
        
        # Хранение токена
        "token_storage_question" = "Как вы хотите сохранить токен?"
        "token_storage_env" = "Переменная окружения (постоянно, сохраняется после перезагрузки)"
        "token_storage_file" = "Зашифрованный файл (хранится в конфиге)"
        "token_storage_session" = "Только сессия (временно, теряется при выходе)"
        
        # Выбор репозитория
        "repo_selection_title" = "Выбор {0}"
        "repo_token_not_configured" = "Токен {0} не настроен"
        "repo_configure_token_first" = "Пожалуйста, сначала настройте токен (Опция 1)"
        "repo_fetching" = "Загрузка {0}..."
        "repo_projects" = "проектов"
        "repo_groups" = "групп"
        "repo_repositories" = "репозиториев"
        "repo_none_found" = "{0} не найдено"
        "repo_search_prompt" = "Поиск {0} (введите часть названия):"
        "repo_search" = "Поиск"
        "repo_no_match" = "Нет {0} соответствующих '{1}'"
        "repo_found" = "Найдено {0} {1}"
        "repo_select_prompt" = "Выберите {0} (1-{1})"
        "repo_set_to" = "{0} установлен на: {1}"
        "repo_error_fetching" = "Ошибка загрузки {0}: {1}"
        
        # Статус Runner'а
        "status_title" = "Статус Runner'а"
        "status_repository" = "Репозиторий"
        "status_token" = "Токен"
        "status_installation" = "Установка"
        "status_installed_at" = "Установлен в {0}"
        "status_not_installed" = "Не установлен"
        "status_autostart" = "Автозапуск"
        "status_process" = "Процесс"
        "status_running_pid" = "Запущен (PID: {0})"
        "status_not_running" = "Не запущен"
        
        # Мульти-Runner
        "multirunner_title" = "Управление несколькими Runner'ами"
        "multirunner_local_runners" = "Локальные Runner'ы"
        "multirunner_no_runners" = "Локальные runner'ы не настроены"
        "multirunner_tip" = "Совет: Используйте опцию 1 для добавления нового runner'а"
        "multirunner_add" = "Добавить новый runner"
        "multirunner_select" = "Выбрать активный runner"
        "multirunner_remove" = "Удалить runner"
        "multirunner_back" = "Назад в главное меню"
        "multirunner_add_title" = "Добавить новый локальный Runner"
        "multirunner_enter_name" = "Введите имя runner'а (например, 'Основной Runner', 'Резервный Runner'):"
        "multirunner_name" = "Имя"
        "multirunner_name_empty" = "Имя runner'а не может быть пустым"
        "multirunner_enter_path" = "Введите путь установки runner'а:"
        "multirunner_example" = "Пример"
        "multirunner_path" = "Путь"
        "multirunner_using_default" = "Используется путь по умолчанию: {0}"
        "multirunner_path_exists" = "Предупреждение: Путь уже существует. Runner может быть уже установлен."
        "multirunner_continue" = "Продолжить в любом случае? (y/n)"
        "multirunner_current_repo" = "Текущий репозиторий: {0}"
        "multirunner_use_current" = "Использовать текущий репозиторий? (y/n)"
        "multirunner_enter_repo" = "Введите репозиторий (owner/repo):"
        "multirunner_repo_empty" = "Репозиторий не может быть пустым"
        "multirunner_added" = "Runner успешно добавлен!"
        "multirunner_runner_id" = "ID Runner'а: {0}"
        "multirunner_next_steps" = "Следующие шаги:"
        "multirunner_step_select" = "Выберите этот runner как активный (опция 2)"
        "multirunner_step_install" = "Установите runner (опция 5 в главном меню)"
        "multirunner_select_title" = "Выбрать активный Runner"
        "multirunner_no_runners_add" = "Runner'ы не настроены. Сначала добавьте runner."
        "multirunner_cancel" = "Отмена"
        "multirunner_invalid_selection" = "Неверный выбор"
        "multirunner_active_set" = "Активный runner установлен на: {0}"
        "multirunner_remove_title" = "Удалить локальный Runner"
        "multirunner_remove_warning" = "Предупреждение: Это удалит конфигурацию runner'а"
        "multirunner_remove_files_kept" = "Файлы runner'а в {0} НЕ будут удалены"
        "multirunner_confirm" = "Вы уверены? (yes/no)"
        "multirunner_removed" = "Runner удален из конфигурации"
        
        # Docker
        "docker_title" = "Управление Docker контейнерами"
        "docker_not_installed" = "Docker не установлен или не в PATH"
        "docker_install_prompt" = "Пожалуйста, установите Docker Desktop: https://www.docker.com/products/docker-desktop"
        "docker_not_running" = "Docker daemon не запущен"
        "docker_start_prompt" = "Пожалуйста, запустите Docker Desktop и попробуйте снова"
        "docker_checking" = "Проверка статуса Docker..."
        "docker_available" = "Docker доступен"
    }
}

function Get-Translation {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$false)]
        [string]$Param1 = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Param2 = ""
    )
    
    $lang = $script:CurrentLanguage
    
    if ($script:Translations.ContainsKey($lang) -and $script:Translations[$lang].ContainsKey($Key)) {
        $text = $script:Translations[$lang][$Key]
        if ($Param1 -or $Param2) {
            return $text -f $Param1, $Param2
        }
        return $text
    }
    
    # Fallback to English
    if ($script:Translations["en"].ContainsKey($Key)) {
        $text = $script:Translations["en"][$Key]
        if ($Param1 -or $Param2) {
            return $text -f $Param1, $Param2
        }
        return $text
    }
    
    # Return key if not found
    return $Key
}

function Set-Language {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("en", "ru")]
        [string]$Language
    )
    
    $script:CurrentLanguage = $Language
}

function Get-CurrentLanguage {
    return $script:CurrentLanguage
}

function Get-AvailableLanguages {
    return @("en", "ru")
}

# Alias for shorter usage
Set-Alias -Name L -Value Get-Translation -Scope Global


# Additional translations for menu items
$script:Translations["en"]["menu_configuration"] = "Configuration"
$script:Translations["en"]["menu_configure_token"] = "Configure {0} Token"
$script:Translations["en"]["menu_select_repository"] = "Select Repository"
$script:Translations["en"]["menu_select_project_group"] = "Select Project/Group"
$script:Translations["en"]["menu_configure_secrets"] = "Configure GitHub Secrets (Auto)"
$script:Translations["en"]["menu_configure_instance"] = "Configure Instance URL"
$script:Translations["en"]["menu_switch_platform"] = "Switch Platform (GitHub / GitLab)"
$script:Translations["en"]["menu_runner_management"] = "Runner Management"
$script:Translations["en"]["menu_install_runner"] = "Install Runner"
$script:Translations["en"]["menu_start_runner"] = "Start Runner"
$script:Translations["en"]["menu_stop_runner"] = "Stop Runner"
$script:Translations["en"]["menu_check_status"] = "Check Status"
$script:Translations["en"]["menu_view_logs"] = "View Logs"
$script:Translations["en"]["menu_view_active_runners"] = "View Active Runners"
$script:Translations["en"]["menu_autostart"] = "Auto-Start"
$script:Translations["en"]["menu_enable_autostart"] = "Enable Auto-Start (on boot)"
$script:Translations["en"]["menu_disable_autostart"] = "Disable Auto-Start"
$script:Translations["en"]["menu_advanced"] = "Advanced"
$script:Translations["en"]["menu_uninstall_runner"] = "Uninstall Runner"
$script:Translations["en"]["menu_clear_config"] = "Clear Configuration"
$script:Translations["en"]["menu_infrastructure"] = "Infrastructure Suite"
$script:Translations["en"]["menu_telegram"] = "Telegram Notifications"
$script:Translations["en"]["menu_docker"] = "Docker Container Management"
$script:Translations["en"]["menu_multirunner"] = "Multi-Runner Management"
$script:Translations["en"]["menu_help"] = "Help and Quick Start Guide"
$script:Translations["en"]["menu_language"] = "Language / Язык"
$script:Translations["en"]["menu_exit"] = "Exit"
$script:Translations["en"]["menu_select_option"] = "Select option"

$script:Translations["ru"]["menu_configuration"] = "Конфигурация"
$script:Translations["ru"]["menu_configure_token"] = "Настроить токен {0}"
$script:Translations["ru"]["menu_select_repository"] = "Выбрать репозиторий"
$script:Translations["ru"]["menu_select_project_group"] = "Выбрать проект/группу"
$script:Translations["ru"]["menu_configure_secrets"] = "Настроить GitHub Secrets (Авто)"
$script:Translations["ru"]["menu_configure_instance"] = "Настроить URL инстанса"
$script:Translations["ru"]["menu_switch_platform"] = "Сменить платформу (GitHub / GitLab)"
$script:Translations["ru"]["menu_runner_management"] = "Управление Runner'ами"
$script:Translations["ru"]["menu_install_runner"] = "Установить Runner"
$script:Translations["ru"]["menu_start_runner"] = "Запустить Runner"
$script:Translations["ru"]["menu_stop_runner"] = "Остановить Runner"
$script:Translations["ru"]["menu_check_status"] = "Проверить статус"
$script:Translations["ru"]["menu_view_logs"] = "Просмотр логов"
$script:Translations["ru"]["menu_view_active_runners"] = "Просмотр активных Runner'ов"
$script:Translations["ru"]["menu_autostart"] = "Автозапуск"
$script:Translations["ru"]["menu_enable_autostart"] = "Включить автозапуск (при загрузке)"
$script:Translations["ru"]["menu_disable_autostart"] = "Отключить автозапуск"
$script:Translations["ru"]["menu_advanced"] = "Дополнительно"
$script:Translations["ru"]["menu_uninstall_runner"] = "Удалить Runner"
$script:Translations["ru"]["menu_clear_config"] = "Очистить конфигурацию"
$script:Translations["ru"]["menu_infrastructure"] = "Инфраструктурный набор"
$script:Translations["ru"]["menu_telegram"] = "Telegram уведомления"
$script:Translations["ru"]["menu_docker"] = "Управление Docker контейнерами"
$script:Translations["ru"]["menu_multirunner"] = "Управление несколькими Runner'ами"
$script:Translations["ru"]["menu_help"] = "Справка и быстрый старт"
$script:Translations["ru"]["menu_language"] = "Язык / Language"
$script:Translations["ru"]["menu_exit"] = "Выход"
$script:Translations["ru"]["menu_select_option"] = "Выберите опцию"


# Banner and status translations
$script:Translations["en"]["banner_title"] = "OCTOPUS RUNNER MANAGER"
$script:Translations["en"]["banner_subtitle"] = "Advanced CI/CD Infrastructure Suite"
$script:Translations["en"]["banner_powered"] = "Powered by"

$script:Translations["ru"]["banner_title"] = "OCTOPUS RUNNER MANAGER"
$script:Translations["ru"]["banner_subtitle"] = "Продвинутый набор CI/CD инфраструктуры"
$script:Translations["ru"]["banner_powered"] = "Разработано"

# Status display translations
$script:Translations["en"]["status_platform"] = "Platform"
$script:Translations["en"]["status_instance"] = "Instance"
$script:Translations["en"]["status_repository"] = "Repository"
$script:Translations["en"]["status_token"] = "Token"
$script:Translations["en"]["status_telegram"] = "Telegram"
$script:Translations["en"]["status_docker"] = "Docker"
$script:Translations["en"]["status_local_runners"] = "Local Runners"
$script:Translations["en"]["status_active_runner"] = "Active Runner"
$script:Translations["en"]["status_path"] = "Path"
$script:Translations["en"]["status_configured"] = "Configured"
$script:Translations["en"]["status_not_configured"] = "Not configured"
$script:Translations["en"]["status_enabled"] = "Enabled"
$script:Translations["en"]["status_disabled"] = "Disabled"
$script:Translations["en"]["status_containers"] = "container(s)"
$script:Translations["en"]["status_runners_configured"] = "configured"

$script:Translations["ru"]["status_platform"] = "Платформа"
$script:Translations["ru"]["status_instance"] = "Инстанс"
$script:Translations["ru"]["status_repository"] = "Репозиторий"
$script:Translations["ru"]["status_token"] = "Токен"
$script:Translations["ru"]["status_telegram"] = "Telegram"
$script:Translations["ru"]["status_docker"] = "Docker"
$script:Translations["ru"]["status_local_runners"] = "Локальные Runner'ы"
$script:Translations["ru"]["status_active_runner"] = "Активный Runner"
$script:Translations["ru"]["status_path"] = "Путь"
$script:Translations["ru"]["status_configured"] = "Настроен"
$script:Translations["ru"]["status_not_configured"] = "Не настроено"
$script:Translations["ru"]["status_enabled"] = "Включен"
$script:Translations["ru"]["status_disabled"] = "Отключен"
$script:Translations["ru"]["status_containers"] = "контейнер(ов)"
$script:Translations["ru"]["status_runners_configured"] = "настроено"


# Exit messages
$script:Translations["en"]["goodbye_message"] = "Thank you for using Octopus Runner Manager!"
$script:Translations["en"]["goodbye_powered"] = "Powered by"

$script:Translations["ru"]["goodbye_message"] = "Спасибо за использование Octopus Runner Manager!"
$script:Translations["ru"]["goodbye_powered"] = "Разработано"
