FROM mcr.microsoft.com/devcontainers/base:ubuntu
USER vscode
WORKDIR /home/vscode
ENV MODULAR_HOME=/home/vscode/.modular
ENV MOJO_PATH="$MODULAR_HOME/pkg/packages.modular.com_nightly_mojo"
ENV PATH="$MOJO_PATH/bin:$PATH"
RUN sudo apt-get update
RUN sudo apt-get install -y lsb-release wget software-properties-common gnupg python3-pip
RUN wget https://raw.githubusercontent.com/modularml/mojo/nightly/stdlib/scripts/install-build-tools-linux.sh
RUN chmod +x ./install-build-tools-linux.sh
RUN sudo ./install-build-tools-linux.sh
RUN curl -s https://get.modular.com | sh -
RUN modular auth test
RUN modular install nightly/mojo
