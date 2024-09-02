# Étape 1 : Construction de l'application React
# Utiliser Debian 12 comme image de base
FROM debian:latest AS build

# Installer Node.js et npm
RUN apt-get update && apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Définir le répertoire de travail à l'intérieur du conteneur
WORKDIR /app

# Copier les fichiers package.json et package-lock.json dans le conteneur
COPY package*.json ./

# Installer les dépendances de l'application
RUN npm install

# Copier le reste des fichiers de l'application dans le conteneur
COPY . .

# Construire l'application React
RUN npm run build

# Étape 2 : Image finale avec Apache pour servir les fichiers construits
# Utiliser Debian 12 comme image de base
FROM debian:latest

# Installer Apache
RUN apt-get update && apt-get install -y \
    apache2 \
    apache2-utils \
    openssl \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN a2enmod ssl \
    && a2enmod proxy \
    && a2enmod proxy_http \
    && a2enmod headers \
    && a2enmod rewrite
# Copier les fichiers construits depuis l'étape précédente
COPY --from=build /app/build /var/www/html
COPY ./apache/apache.conf /etc/apache2/sites-available/000-default.conf

# Exposer le port 80 pour accéder à l'application via HTTP
EXPOSE 80 443

# Commande pour démarrer Apache en mode foreground
CMD ["apachectl", "-D", "FOREGROUND"]
