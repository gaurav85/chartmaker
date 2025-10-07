FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# Install dependencies
RUN apt-get update && apt-get install -y \
    nodejs \
    npm \
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
    libgdal-dev \
    libssl-dev \
    gdal-bin \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

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

# Copy chartmaker files
COPY . .

# Install npm dependencies
RUN npm install

# Install Python dependencies for mbutil (FIXED LINE)
RUN pip3 install pillow requests

# Create necessary directories
RUN mkdir -p workarea chartcache public/charts

# Set permissions
RUN chmod +x mergetiles.pl mb-util

# Default command
CMD ["node", "make.js"]