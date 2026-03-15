FROM debian:trixie-slim

ARG TZ

ARG USERNAME=sophie
ARG NVM_VERSION=0.40.4
ARG CLAUDE_CODE_VERSION=latest
ARG EAS_CLI_VERSION=latest

# Install basic development tools and iptables/ipset
RUN apt-get update && apt-get install -y --no-install-recommends \
  less \
  git \
  procps \
  sudo \
  fzf \
  zsh \
  man-db \
  unzip \
  gnupg2 \
  gh \
  iptables \
  ipset \
  iproute2 \
  dnsutils \
  aggregate \
  jq \
  nano \
  vim \
  build-essential \
  ca-certificates \
  curl \
  wget \
  locales \
  fontconfig \
  && apt-get clean && rm -rf /var/lib/apt/lists/* \
  && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ARG LANG=en_US.UTF-8
ARG LC_ALL=en_US.UTF-8
ENV LANG=${LANG}
ENV LC_ALL=${LC_ALL}

# Install Nerd Font for powerline/starship glyphs
RUN mkdir -p /usr/local/share/fonts && \
  curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz \
  | tar -xJ -C /usr/local/share/fonts && \
  fc-cache -f

# Install zsh plugins
RUN git clone https://github.com/zsh-users/zsh-autosuggestions /usr/local/share/zsh-autosuggestions && \
  git clone https://github.com/zsh-users/zsh-syntax-highlighting /usr/local/share/zsh-syntax-highlighting && \
  git clone https://github.com/marlonrichert/zsh-autocomplete /usr/local/share/zsh-autocomplete

# Create user and group
RUN groupadd --gid 1000 ${USERNAME} && \
  useradd --uid 1000 --gid ${USERNAME} --shell /bin/zsh --create-home ${USERNAME}

# Set HOME so tools install to sophie's home dir instead of /root
ENV HOME=/home/${USERNAME}

# Install Starship prompt
RUN curl -sS https://starship.rs/install.sh | sh -s -- -y

# Copy starship config
COPY starship.toml /home/${USERNAME}/.config/starship.toml

# Install nvm and Node.js
ENV NVM_DIR=/home/${USERNAME}/.nvm
RUN mkdir -p $NVM_DIR && \
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash && \
  . "$NVM_DIR/nvm.sh" && \
  nvm install --lts && \
  nvm alias default lts/* && \
  NODE_PATH="$NVM_DIR/versions/node/$(nvm version)/bin" && \
  ln -s "$NODE_PATH/node" /usr/local/bin/node && \
  ln -s "$NODE_PATH/npm" /usr/local/bin/npm && \
  ln -s "$NODE_PATH/npx" /usr/local/bin/npx

# Install Bun
RUN curl -fsSL https://bun.sh/install | bash

# Install Go
ARG GO_VERSION=1.24.1
RUN mkdir -p /home/${USERNAME}/.local/go && \
  ARCH=$(dpkg --print-architecture) && \
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" | tar -C /home/${USERNAME}/.local -xz && \
  chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.local/go && \
  ln -s /home/${USERNAME}/.local/go/bin/go /usr/local/bin/go && \
  ln -s /home/${USERNAME}/.local/go/bin/gofmt /usr/local/bin/gofmt
ENV GOROOT=/home/${USERNAME}/.local/go
ENV GOPATH=/home/${USERNAME}/go

# Install Rust/Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly

# Install zoxide, eza via cargo
RUN . "/home/${USERNAME}/.cargo/env" && \
  cargo install zoxide eza

# Install git-delta
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  sudo dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"


# Configure vim with syntax highlighting
RUN echo "syntax on" > /home/${USERNAME}/.vimrc && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.vimrc

# Install Claude
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} eas-cli@${EAS_CLI_VERSION}

# Fix home directory ownership
RUN mkdir -p /home/${USERNAME}/.claude /home/${USERNAME}/.claude-karaconnect && \
  chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/.local /home/${USERNAME}/.nvm /home/${USERNAME}/.bun /home/${USERNAME}/.cargo  /home/${USERNAME}/.npm  /home/${USERNAME}/.rustup /home/${USERNAME}/.claude  /home/${USERNAME}/.claude-karaconnect

# Copy and set up firewall script
COPY init-firewall.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "${USERNAME} ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/${USERNAME}-firewall && \
  chmod 0440 /etc/sudoers.d/${USERNAME}-firewall
USER ${USERNAME}
