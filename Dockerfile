FROM debian:unstable AS base

# install packages
RUN apt-get update \
 && apt-get install -y \
    asciinema \
    cmake \ 
    curl \
    fzf \
    gettext \
    git \
    gcc \
    libevent-dev \
    man \
    make \
    ninja-build \
    ncurses-dev \
    python3 \
    python3-pip \
    python3-venv \
    ranger \
    tmux \
    unzip \
    wget \
    zsh \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Set LC_ALL to enable non-ascii symbols in tmux
# https://stackoverflow.com/questions/28405902/how-to-set-the-locale-inside-a-debian-ubuntu-docker-container
ENV LC_ALL C.utf8
ENV TERM screen-256color

WORKDIR /tmp/
ARG DEST=/usr/local/bin

# Compile latest nvim from source
RUN git clone https://github.com/neovim/neovim
RUN cd neovim && \ 
    make CMAKE_BUILD_TYPE=RelWithDebInfo && \
    cd build && \ 
    cpack -G DEB && \ 
    dpkg -i nvim-linux64.deb
RUN rm -rf neovim 

# Set up non-root user
ARG USERNAME=user
ARG UID=1000
RUN adduser \
  --uid $UID \
  --quiet \
  --disabled-password \
  --shell /bin/zsh \
  --home /home/$USERNAME \
  --gecos "Dev User" \
  $USERNAME

RUN chown $USERNAME:$USERNAME /tmp/

USER $USERNAME
WORKDIR /home/$USERNAME

# Install oh-my-zsh
RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh plugins
RUN git clone \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    .oh-my-zsh/custom/plugins/zsh-syntax-highlighting
RUN git clone \
    https://github.com/zsh-users/zsh-autosuggestions.git \
    .oh-my-zsh/custom/plugins/zsh-autosuggestions
RUN git clone --depth=1 \
    https://github.com/romkatv/powerlevel10k.git \
    .oh-my-zsh/custom/themes/powerlevel10k

# Set up dotfiles
RUN git clone https://github.com/ceedee666/devenv-dotfiles.git
RUN mv devenv-dotfiles/.config .
RUN mv devenv-dotfiles/.gitconfig .
RUN mv devenv-dotfiles/.gitignore .
RUN mv devenv-dotfiles/.p10k.zsh .
RUN mv devenv-dotfiles/.scripts .
RUN mv devenv-dotfiles/.zprofile .
RUN mv devenv-dotfiles/.zshrc .

# Install tmux plugin manager
RUN git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm/

# Install Vim plugins
RUN nvim --headless "+Lazy! sync" +qa

# Add python install path
ENV PATH "$PATH:/home/user/.local/bin"

# Off we go - based on tmux, the terminal multiplexer
CMD ["tmux", "-u", "new", "-s", "main"]
