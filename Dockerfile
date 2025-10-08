FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# Install Node.js 20 LTS from NodeSource
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update

# Install all dependencies including Node.js 20
RUN apt-get install -y \
    nodejs \
    sqlite3 \
    python3 \
    python3-pip \
    perl \
    cpanminus \
    pngquant \
    imagemagick \
    unzip \
    build-essential \
    libgdal-dev \
    libssl-dev \
    gdal-bin=3.11* \
    && rm -rf /var/lib/apt/lists/*

# Verify Node.js version
RUN node --version && npm --version

# Install Perl dependencies
# RUN cpanm --notest \
#     strict \
#     warnings \
#     autodie \
#     Carp \
#     Modern::Perl \
#     Params::Validate \
#     File::Slurp \
#     File::Copy

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

# Create necessary directories
RUN mkdir -p workarea chartcache public/charts

# Set permissions for executables
RUN chmod +x mergetiles.pl && \
    chmod +x mbutil/mb-util && \
    ln -s /chartmaker/mbutil/mb-util /usr/local/bin/mb-util

# Make script executable and run it
RUN chmod +x ./perlinstall.sh && ./perlinstall.sh

# Default command
CMD ["node", "make.js"]