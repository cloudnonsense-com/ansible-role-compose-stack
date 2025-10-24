FROM debian:bookworm-slim

# Install dependencies for GitHub Actions runner
RUN apt-get update && apt-get install -y \
    bash \
    procps \
    curl \
    wget \
    jq \
    less \
    vim-tiny \
    nano \
    git \
    tar \
    gzip \
    unzip \
    ca-certificates \
    nodejs \
    openssh-client \
    sshpass \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    gnupg \
    s3cmd \
    awscli \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --break-system-packages \
    yq \
    ansible-core==2.17.7 \
    ansible==10.7.0

# Install Terraform from HashiCorp's official repository
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main" > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y terraform \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /actions-runner

# Download and extract the latest GitHub Actions runner
RUN RUNNER_VERSION=$(curl -s https://api.github.com/repos/actions/runner/releases/latest | jq -r '.tag_name' | sed 's/v//') \
    && curl -o actions-runner-linux-x64.tar.gz -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
    && tar xzf actions-runner-linux-x64.tar.gz \
    && rm actions-runner-linux-x64.tar.gz

# Set environment variable to allow running as root
ENV RUNNER_ALLOW_RUNASROOT=1

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]
