FROM mcr.microsoft.com/devcontainers/base:ubuntu
USER vscode
WORKDIR /home/vscode
ENV MODULAR_HOME=/home/vscode/.modular
ENV MOJO_PATH="$MODULAR_HOME/pkg/packages.modular.com_nightly_mojo"
ENV PATH="$MOJO_PATH/bin:$PATH"
RUN sudo apt-get update
RUN sudo apt-get install -y clang
RUN curl -s https://get.modular.com | sh -
RUN modular auth --help
RUN modular install nightly/mojo
