# Usamos la imagen oficial de PHP 8.1 CON Apache (Todo en uno)
FROM php:8.1-apache

# 1. Instalar dependencias del sistema (AÑADIMOS libmagickwand-dev para imagick)
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libicu-dev \
    default-mysql-client \
    libmagickwand-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 2. Instalar extensiones de PHP (AÑADIMOS imagick)
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip intl
RUN pecl install imagick && docker-php-ext-enable imagick

# 3. Activar mod_rewrite de Apache (Vital para las rutas de Laravel)
RUN a2enmod rewrite

# 4. Configurar el DocumentRoot de Apache para que apunte a /public
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 5. Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. Establecer directorio de trabajo
WORKDIR /var/www/html

# 7. Copiar los archivos del proyecto al contenedor
COPY . .

# 8. Instalar dependencias de PHP
RUN composer install --no-interaction --optimize-autoloader --no-dev --ignore-platform-reqs

# 9. Ajustar permisos
RUN chown -R www-data:www-data storage bootstrap/cache
RUN chmod -R 775 storage bootstrap/cache

# 10. Exponer el puerto 80 (el estándar de Apache)
EXPOSE 80

# 11. Comando de arranque
CMD php artisan config:cache && php artisan route:cache && php artisan view:cache && apache2-foreground
