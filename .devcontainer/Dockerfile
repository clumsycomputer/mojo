FROM mcr.microsoft.com/devcontainers/base:ubuntu
USER vscode
WORKDIR /home/vscode
ENV MODULAR_HOME=/home/vscode/.modular
ENV MOJO_PATH="$MODULAR_HOME/pkg/packages.modular.com_nightly_mojo"
ENV PATH="$MOJO_PATH/bin:$PATH"
RUN sudo apt-get update
RUN sudo apt-get install -y llvm
RUN sudo apt-get install -y lldb
RUN sudo mv /usr/bin/FileCheck-14 /usr/bin/FileCheck
RUN curl -s https://get.modular.com | sh -
RUN modular auth test
RUN modular install nightly/mojo
RUN python3 -m pip install lit
