FROM node:22-slim

LABEL maintainer="musicnerd"
LABEL description="Claude Code development environment with gh CLI and Playwright support"

# System deps: git, curl, bash, vim, psql, python, Playwright/Chromium requirements
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    bash \
    vim \
    jq \
    postgresql-client \
    python3 \
    python3-pip \
    python-is-python3 \
    libnss3 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libxkbcommon0 \
    libgbm1 \
    libasound2 \
    libxrandr2 \
    libxfixes3 \
    libxcomposite1 \
    libxdamage1 \
    libpango-1.0-0 \
    libcairo2 \
    libatspi2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# Build args
ARG DOCKER_USER=dev
ARG WORKSPACE_DIR=workspace
ARG GIT_USER_NAME="Your Name"
ARG GIT_USER_EMAIL="you@example.com"

# Create non-root user
RUN useradd -m -s /bin/bash ${DOCKER_USER}

# Set up workspace and claude config dir with correct ownership
RUN mkdir -p /${WORKSPACE_DIR} && chown ${DOCKER_USER}:${DOCKER_USER} /${WORKSPACE_DIR} && \
    mkdir -p /home/${DOCKER_USER}/.claude && chown -R ${DOCKER_USER}:${DOCKER_USER} /home/${DOCKER_USER}/.claude

# Switch to non-root user
USER ${DOCKER_USER}
WORKDIR /home/${DOCKER_USER}

# Install Claude Code via native installer
RUN curl -fsSL https://claude.ai/install.sh | bash

# Add Claude Code to PATH
ENV PATH="/home/${DOCKER_USER}/.local/bin:${PATH}"

# Shell customization (PATH for interactive shells, aliases, profile)
RUN { \
      echo "export PATH=\"/home/${DOCKER_USER}/.local/bin:\$PATH\""; \
      echo 'alias ll="ls -la"'; \
      echo 'alias h="history"'; \
      echo 'alias clauded="claude --dangerously-skip-permissions"'; \
    } >> /home/${DOCKER_USER}/.bashrc && \
    echo 'source ~/.bashrc' >> /home/${DOCKER_USER}/.bash_profile

# Git config
RUN git config --global user.name "${GIT_USER_NAME}" && \
    git config --global user.email "${GIT_USER_EMAIL}" && \
    git config --global credential.helper "gh auth git-credential"

WORKDIR /${WORKSPACE_DIR}

HEALTHCHECK --interval=60s --timeout=5s --retries=3 \
  CMD claude --version || exit 1

CMD ["bash"]
