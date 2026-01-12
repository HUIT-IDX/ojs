FROM php:8.2-apache

# 1. Cài đặt các thư viện hệ thống (System Dependencies)
# Bước này cực kỳ quan trọng để các extension PHP có thể build được
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libzip-dev \
    libonig-dev \
    libicu-dev \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Cấu hình và cài đặt PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure intl \
    && docker-php-ext-install \
        bcmath \
        curl \
        dom \
        fileinfo \
        ftp \
        gd \
        intl \
        mbstring \
        mysqli \
        pdo_mysql \
        simplexml \
        xml \
        xmlwriter \
        zip

# 3. Cài đặt Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# 4. Cài đặt Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 5. Cấu hình Apache
RUN a2enmod rewrite

# 6. Thiết lập thư mục làm việc
WORKDIR /var/www/html

# 7. Copy mã nguồn (nên copy composer.json trước để tận dụng cache nếu muốn tối ưu, 
# nhưng copy toàn bộ như bạn cũng được)
COPY . .

# ... (các phần trên giữ nguyên)

# 8. Cài đặt Dependencies
# Cài đặt tại gốc nếu có composer.json
RUN if [ -f "composer.json" ]; then composer install --no-interaction --no-dev --optimize-autoloader; fi

# BẮT BUỘC: OJS 3.4+ yêu cầu cài đặt vendor trong lib/pkp
RUN if [ -d "lib/pkp" ]; then cd lib/pkp && composer install --no-interaction --no-dev --optimize-autoloader; fi

# Cài đặt JS và Build (Chỉ khi có package.json)
RUN if [ -f "package.json" ]; then npm install && npm run build; fi

# 9. Thiết lập quyền hạn (Permissions)
# Tạo thư mục files nếu chưa có để tránh lỗi chmod
RUN mkdir -p files public cache \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 777 /var/www/html/files \
    && chmod -R 777 /var/www/html/public \
    && chmod -R 777 /var/www/html/cache

EXPOSE 80