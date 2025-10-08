FROM node:20-bullseye

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# Add UbuntuGIS PPA for latest GDAL
RUN apt-get update && apt-get install -y \
    software-properties-common \
    gnupg \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install GDAL 3.8+ from UbuntuGIS
RUN echo "deb http://ppa.launchpadcontent.net/ubuntugis/ubuntugis-unstable/ubuntu jammy main" > /etc/apt/sources.list.d/ubuntugis.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 6B827C12C2D425E227EDCA75089EBE08314DF160 \
    || wget -qO- https://qgis.org/downloads/qgis-2021.gpg.key | apt-key add -

# Install all dependencies with updated GDAL
RUN apt-get update && apt-get install -y \
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
    gdal-bin=3.8* \
    libgdal-dev \
    python3-gdal \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Verify GDAL version (should be 3.8+)
RUN gdalinfo --version

# Install Perl dependencies
RUN cpanm --notest \
    strict \
    warnings \
    autodie \
    Carp \
    Modern::Perl \
    Params::Validate \
    File::Slurp \
    File::Copy

# Set working directory
WORKDIR /chartmaker

# Copy package files first for better caching
COPY package*.json ./

# Install npm dependencies
RUN npm install

# Copy rest of chartmaker files
COPY . .

# Install Python dependencies for mbutil
RUN pip3 install pillow requests

# Create necessary directories with proper permissions
RUN mkdir -p workarea chartcache public/charts && \
    chmod -R 777 workarea chartcache public

# Set permissions for executables
RUN chmod +x mergetiles.pl && \
    chmod +x mbutil/mb-util && \
    ln -s /chartmaker/mbutil/mb-util /usr/local/bin/mb-util

# Run as non-root user for better file permissions
RUN useradd -m -u 1001 chartmaker && \
    chown -R chartmaker:chartmaker /chartmaker

USER chartmaker

# Default command
CMD ["node", "make.js"]