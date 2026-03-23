FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG USERNAME=devuser
ARG USER_UID=1000
ARG USER_GID=1000
ARG NODE_MAJOR=22
ARG NPM_VERSION=10.9.2
ARG GO_VERSION=1.24.1
ARG TERRAFORM_VERSION=1.11.1
ARG OPENTOFU_VERSION=1.9.0
ARG KUBECTL_VERSION=v1.32.3
ARG HELM_VERSION=v3.17.1
ARG YQ_VERSION=v4.44.6
ARG GOLANGCI_LINT_VERSION=v1.64.5
ARG ESLINT_VERSION=9.22.0
ARG RUFF_VERSION=0.11.0
ARG BLACK_VERSION=25.1.0
ARG UV_VERSION=0.6.6

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV TZ=Etc/UTC
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PATH="/usr/local/go/bin:/home/${USERNAME}/.local/bin:${PATH}"

# Base OS packages and common shell/build utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    coreutils \
    curl \
    file \
    git \
    gnupg \
    jq \
    less \
    make \
    openssh-client \
    openssl \
    python3 \
    python3-pip \
    python3-venv \
    software-properties-common \
    tar \
    unzip \
    vim \
    wget \
    xz-utils \
    zip \
    build-essential \
    openssh-server \
    postgresql-client \
    mysql-client \
    && mkdir -p /var/run/sshd \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && npm install -g npm@${NPM_VERSION} \
    && rm -rf /var/lib/apt/lists/*

# Go toolchain
RUN arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) go_arch='amd64' ;; \
        arm64) go_arch='arm64' ;; \
        *) echo "Unsupported architecture: ${arch}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${go_arch}.tar.gz" -o /tmp/go.tgz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tgz \
    && rm -f /tmp/go.tgz

# AWS CLI v2
RUN arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) aws_arch='x86_64' ;; \
        arm64) aws_arch='aarch64' ;; \
        *) echo "Unsupported architecture: ${arch}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${aws_arch}.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscliv2.zip

# Terraform
RUN arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) tf_arch='amd64' ;; \
        arm64) tf_arch='arm64' ;; \
        *) echo "Unsupported architecture: ${arch}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${tf_arch}.zip" -o /tmp/terraform.zip \
    && unzip -q /tmp/terraform.zip -d /usr/local/bin \
    && chmod +x /usr/local/bin/terraform \
    && rm -f /tmp/terraform.zip

# OpenTofu
RUN arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) tofu_arch='amd64' ;; \
        arm64) tofu_arch='arm64' ;; \
        *) echo "Unsupported architecture: ${arch}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${tofu_arch}.tar.gz" -o /tmp/tofu.tar.gz \
    && tar -xzf /tmp/tofu.tar.gz -C /tmp \
    && mv /tmp/tofu /usr/local/bin/tofu \
    && chmod +x /usr/local/bin/tofu \
    && rm -rf /tmp/tofu.tar.gz /tmp/CHANGELOG.md /tmp/LICENSE /tmp/README.md

# kubectl
RUN arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) k_arch='amd64' ;; \
        arm64) k_arch='arm64' ;; \
        *) echo "Unsupported architecture: ${arch}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${k_arch}/kubectl" -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# Helm
RUN arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) helm_arch='amd64' ;; \
        arm64) helm_arch='arm64' ;; \
        *) echo "Unsupported architecture: ${arch}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${helm_arch}.tar.gz" -o /tmp/helm.tar.gz \
    && tar -xzf /tmp/helm.tar.gz -C /tmp \
    && mv "/tmp/linux-${helm_arch}/helm" /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm \
    && rm -rf /tmp/helm.tar.gz "/tmp/linux-${helm_arch}"

# yq
RUN arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) yq_arch='amd64' ;; \
        arm64) yq_arch='arm64' ;; \
        *) echo "Unsupported architecture: ${arch}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${yq_arch}" -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# AWS Session Manager plugin
RUN arch="$(dpkg --print-architecture)" \
    && case "${arch}" in \
        amd64) ssm_url="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" ;; \
        arm64) ssm_url="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb" ;; \
        *) echo "Unsupported architecture: ${arch}"; exit 1 ;; \
       esac \
    && curl -fsSL "${ssm_url}" -o /tmp/session-manager-plugin.deb \
    && dpkg -i /tmp/session-manager-plugin.deb \
    && rm -f /tmp/session-manager-plugin.deb

# Linters — Python (Ruff, Black)
RUN pip3 install --no-cache-dir --break-system-packages ruff==${RUFF_VERSION} black==${BLACK_VERSION}

# uv (Python package manager)
RUN curl -fsSL https://astral.sh/uv/${UV_VERSION}/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# Newman (Postman CLI)
RUN npm install -g newman

# Linters — Node.js (ESLint)
RUN npm install -g eslint@${ESLINT_VERSION}

# Linters — Go (golangci-lint)
RUN curl -fsSL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh \
    | sh -s -- -b /usr/local/bin ${GOLANGCI_LINT_VERSION}

# Create non-root user (rename existing ubuntu:1000 user if present)
RUN if id -u ${USER_UID} >/dev/null 2>&1; then \
        existing_user=$(getent passwd ${USER_UID} | cut -d: -f1); \
        usermod -l ${USERNAME} -d /home/${USERNAME} -m "$existing_user"; \
        groupmod -n ${USERNAME} "$(getent group ${USER_GID} | cut -d: -f1)"; \
    else \
        groupadd --gid ${USER_GID} ${USERNAME}; \
        useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME}; \
    fi \
    && usermod -s /bin/bash ${USERNAME} \
    && mkdir -p /workspace \
    && chown -R ${USERNAME}:${USERNAME} /workspace /home/${USERNAME}

# Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash

# Copy helper scripts
COPY scripts/verify-tools.sh /usr/local/bin/verify-tools
RUN chmod +x /usr/local/bin/verify-tools

USER ${USERNAME}
WORKDIR /workspace

CMD ["/bin/bash"]
