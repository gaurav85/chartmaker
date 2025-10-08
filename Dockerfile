FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# Install Node.js 20 LTS
RUN apt-get update && apt-get install -y ca-certificates curl gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Install all dependencies (Ubuntu 24.04 has GDAL 3.8.4 by default)
RUN apt-get update && apt-get install -y \
    nodejs \
    sqlite3 \
    python3 \
    python3-pip \
    perl \
    cpanminus \
    pngquant \
    imagemagick \
    curl \
    unzip \
    build-essential \
    gdal-bin \
    libgdal-dev \
    python3-gdal \
    && rm -rf /var/lib/apt/lists/*

# Verify versions
RUN node --version && gdalinfo --version

# Install Perl dependencies
RUN cpanm --notest strict warnings autodie Carp Modern::Perl Params::Validate File::Slurp File::Copy

WORKDIR /chartmaker

COPY package*.json ./
RUN npm install

COPY . .

RUN pip3 install --break-system-packages pillow requests

# Create directories with proper permissions
RUN mkdir -p workarea chartcache public/charts && \
    chmod -R 777 workarea chartcache public

RUN chmod +x mergetiles.pl mbutil/mb-util && \
    ln -s /chartmaker/mbutil/mb-util /usr/local/bin/mb-util

# Run as non-root user
RUN useradd -m -u 1001 chartmaker && \
    chown -R chartmaker:chartmaker /chartmaker

USER chartmaker

CMD ["node", "make.js"]