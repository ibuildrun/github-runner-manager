#!/bin/bash
set -e

echo "=== GitHub Actions Universal Runner ==="

# Исправление прав на Docker socket
if [ -S /var/run/docker.sock ]; then
    echo "Fixing Docker socket permissions..."
    sudo chmod 666 /var/run/docker.sock || true
fi

# Проверка обязательных переменных
if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN environment variable is required"
    exit 1
fi

# Получение списка всех репозиториев пользователя
echo "Fetching all repositories..."
REPOS=$(curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
    "https://api.github.com/user/repos?per_page=100&affiliation=owner" | \
    jq -r '.[].full_name')

if [ -z "$REPOS" ]; then
    echo "Error: No repositories found or invalid token"
    exit 1
fi

REPO_COUNT=$(echo "$REPOS" | wc -l)
echo "Found $REPO_COUNT repositories:"
echo "$REPOS"

# Создание лейблов для всех репозиториев
LABELS="docker,linux,self-hosted,universal"
for repo in $REPOS; do
    REPO_NAME=$(echo $repo | cut -d'/' -f2)
    LABELS="${LABELS},${REPO_NAME}"
done

echo ""
echo "Labels: $LABELS"
echo ""

# Регистрация раннера на первом репозитории (avyx или первый в списке)
TARGET_REPO=$(echo "$REPOS" | grep "avyx" | head -n 1)
if [ -z "$TARGET_REPO" ]; then
    TARGET_REPO=$(echo "$REPOS" | head -n 1)
fi

echo "Registering runner on: $TARGET_REPO"

# Получение токена для регистрации
RUNNER_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${TARGET_REPO}/actions/runners/registration-token" \
    | jq -r .token)

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" == "null" ]; then
    echo "Error: Failed to get runner registration token"
    exit 1
fi

# Настройка раннера
echo "Configuring runner..."
./config.sh \
    --url "https://github.com/${TARGET_REPO}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME:-universal-docker-runner}" \
    --labels "$LABELS" \
    --work "${RUNNER_WORKDIR:-_work}" \
    --unattended \
    --replace

# Cleanup при остановке
cleanup() {
    echo "Removing runner..."
    ./config.sh remove --token "${RUNNER_TOKEN}" 2>/dev/null || true
}
trap cleanup EXIT SIGTERM SIGINT

# Вывод информации о окружении
echo ""
echo "=== Environment Info ==="
echo "Node.js: $(node --version)"
echo "npm: $(npm --version)"
echo "PHP: $(php --version | head -n 1)"
echo "Composer: $(composer --version)"
echo ""

# Запуск раннера
echo "Starting runner..."
echo "Runner is ready to accept jobs from all repositories!"
./run.sh
