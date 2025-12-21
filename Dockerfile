# Dockerfile - Jenkins with Packer, Terraform, AWS CLI
FROM jenkins/jenkins:lts

USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    git \
    awscli \
    python3 \
    python3-pip \
    python3-venv \
    docker.io \
    jq \
    build-essential \
    libssl-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Packer 1.10.0
RUN curl -Lo /tmp/packer.zip https://releases.hashicorp.com/packer/1.10.0/packer_1.10.0_linux_amd64.zip \
    && unzip /tmp/packer.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/packer \
    && rm /tmp/packer.zip

# Install Terraform 1.7.0
RUN curl -Lo /tmp/terraform.zip https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm /tmp/terraform.zip

# Install tfsec (security scanner for Terraform)
RUN curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Install checkov (policy-as-code scanner)
# Create virtual environment for checkov to avoid system package conflicts
RUN python3 -m venv /opt/checkov-venv \
    && /opt/checkov-venv/bin/pip install --upgrade pip \
    && /opt/checkov-venv/bin/pip install checkov \
    && ln -s /opt/checkov-venv/bin/checkov /usr/local/bin/checkov

# Add jenkins user to docker group
RUN usermod -aG docker jenkins

# Verify installations
RUN packer version && \
    terraform version && \
    aws --version && \
    tfsec --version && \
    checkov --version && \
    echo "All tools installed successfully!"

USER jenkins