# GitHub Actions Self-Hosted Runner для AVYX
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Установка всех зависимостей включая PHP 8.1 и инструменты для деплоя
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    unzip \
    zip \
    ca-certificates \
    gnupg \
    sudo \
    docker.io \
    mysql-client \
    sshpass \
    openssh-client \
    rsync \
    lftp \
    php8.1-cli \
    php8.1-mysql \
    php8.1-sqlite3 \
    php8.1-mbstring \
    php8.1-xml \
    php8.1-curl \
    php8.1-zip \
    php8.1-bcmath \
    php8.1-gd \
    php8.1-intl \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя для раннера
RUN useradd -m -s /bin/bash runner && \
    usermod -aG sudo runner && \
    usermod -aG docker runner && \
    echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Установка Node.js 20 + npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    rm -rf /var/lib/apt/lists/*

# Создание npm кэш директории с правильными правами
RUN mkdir -p /home/runner/.npm && \
    chown -R runner:runner /home/runner/.npm

# Установка Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Переключение на пользователя runner
USER runner
WORKDIR /home/runner

# Скачивание GitHub Actions Runner
RUN curl -o actions-runner-linux-x64-2.331.0.tar.gz -L \
    https://github.com/actions/runner/releases/download/v2.331.0/actions-runner-linux-x64-2.331.0.tar.gz && \
    tar xzf actions-runner-linux-x64-2.331.0.tar.gz && \
    rm actions-runner-linux-x64-2.331.0.tar.gz

# Копирование entrypoint скрипта
COPY --chown=runner:runner runner-multi-entrypoint.sh /home/runner/entrypoint.sh
RUN chmod +x /home/runner/entrypoint.sh

# Проверка версий
RUN node --version && \
    npm --version && \
    php --version && \
    composer --version && \
    lftp --version

ENTRYPOINT ["/home/runner/entrypoint.sh"]
