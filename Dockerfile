#checkov:skip=CKV_DOCKER_2: "Ensure that HEALTHCHECK instructions have been added to container images"
ARG UBUNTU_RELEASE="bullseye-slim"  # Using Debian slim
ARG TARGETPLATFORM

FROM debian:${UBUNTU_RELEASE} AS base

ARG DEBIAN_FRONTEND=noninteractive

# Essential packages only
ARG PKGS="\
ca-certificates \
curl \
wget \
git \
gnupg \
make \
openssh-client \
python3 \
python3-pip \
unzip \
zip \
dos2unix \
zsh \
bat \
vim \
jq \
nano \
"
ENV PYTHONIOENCODING=utf-8
ENV LANG=C.UTF-8

# Install base packages as root and clean up in one layer
USER root
RUN apt-get update && \
    apt-get install --no-install-recommends -y ${PKGS} && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*

# Add ubuntu user
ARG USER_ID="1001"
RUN adduser --disabled-password --gecos "" --shell /bin/zsh --uid ${USER_ID} ubuntu && \
    mkdir -p /home/ubuntu/.local/bin && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Install tools as root with cleanup
# hadolint
ARG HADOLINT_VERSION="v2.12.0"
RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "x86_64" || echo "arm64" ) && \
    curl -Lo /usr/local/bin/hadolint "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-${ARCH}" && \
    chmod +x /usr/local/bin/hadolint

# tfenv
COPY --chown=ubuntu:root ./.terraform-version /opt/.terraform-version
RUN git clone --depth 1 https://github.com/tfutils/tfenv.git /opt/tfenv && \
    ln -s /opt/tfenv/bin/tfenv /usr/local/bin && \
    ln -s /opt/tfenv/bin/terraform /usr/local/bin && \
    mkdir -p /opt/tfenv/versions && \
    dos2unix /opt/.terraform-version && \
    tfenv install && \
    chown -R ubuntu:root /opt/tfenv && \
    rm -rf /opt/tfenv/.git

# tfsec
ARG TFSEC_VERSION="1.28.6"
RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
    curl -Lo /usr/local/bin/tfsec "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCH}" && \
    chmod +x /usr/local/bin/tfsec

# trivy
ARG TRIVY_VERSION="0.18.3"
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v${TRIVY_VERSION}

# tflint
ARG TFLINT_VERSION="0.51.1"
RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
    curl -Lo /tmp/tflint.zip "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip" && \
    unzip /tmp/tflint.zip -d /usr/local/bin && \
    rm -f /tmp/tflint.zip

# tflint azurerm plugin
ARG TFLINT_AZURERM_PLUGIN="0.12.0"
RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
    mkdir -p /home/ubuntu/.tflint.d/plugins && \
    curl -Lo /tmp/tflint-ruleset-azurerm.zip "https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/v${TFLINT_AZURERM_PLUGIN}/tflint-ruleset-azurerm_linux_${ARCH}.zip" && \
    unzip /tmp/tflint-ruleset-azurerm.zip -d /home/ubuntu/.tflint.d/plugins && \
    chown -R ubuntu:ubuntu /home/ubuntu/.tflint.d && \
    rm -f /tmp/tflint-ruleset-azurerm.zip

# terraform-docs
ARG TERRAFORM_DOCS_VERSION="0.18.0"
RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
    curl -Lo /tmp/terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${ARCH}.tar.gz" && \
    tar -xzf /tmp/terraform-docs.tar.gz -C /usr/local/bin terraform-docs && \
    chmod +x /usr/local/bin/terraform-docs && \
    rm -f /tmp/terraform-docs.tar.gz

# aws cli
RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "x86_64" || echo "aarch64" ) && \
    curl -Lo "/tmp/awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" && \
    unzip -qq /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

# Install Python tools as ubuntu user
USER ubuntu
ENV PATH="$PATH:/home/ubuntu/.local/bin"
RUN pip3 install --no-cache-dir --user \
    azure-cli \
    checkov \
    pre-commit==3.6.0

# MOTD (copy as root for correct permissions)
USER root
COPY --chown=root:root ./.devcontainer/etc/update-motd.d/00-header /etc/update-motd.d/00-header
RUN chmod +x /etc/update-motd.d/00-header

# Final setup as ubuntu
USER ubuntu
WORKDIR /app
# Final setup as ubuntu
USER ubuntu
WORKDIR /app
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
RUN zsh -c "source /home/ubuntu/.zshrc && \
    # omz theme set cloud && \
    sleep 5 && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-/home/ubuntu/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-/home/ubuntu/.oh-my-zsh/custom}/plugins/you-should-use && \
    git clone https://github.com/fdellwing/zsh-bat.git ${ZSH_CUSTOM:-/home/ubuntu/.oh-my-zsh/custom}/plugins/zsh-bat && \
    git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-/home/ubuntu/.oh-my-zsh/custom}/plugins/zsh-autocomplete"

# Copy custom .zshrc
COPY --chown=ubuntu:ubuntu ./script/.zshrc /home/ubuntu/.zshrc

################################################################################################################

# #checkov:skip=CKV_DOCKER_2: "Ensure that HEALTHCHECK instructions have been added to container images"
# ARG UBUNTU_RELEASE="bullseye-slim"  # Switch to Debian slim
# ARG TARGETPLATFORM

# FROM debian:${UBUNTU_RELEASE} AS base

# ARG DEBIAN_FRONTEND=noninteractive

# # Essential packages only
# ARG PKGS="\
# ca-certificates \
# curl \
# wget \
# git \
# gnupg \
# make \
# openssh-client \
# python3 \
# python3-pip \
# unzip \
# zip \
# dos2unix \
# zsh \
# bat \
# vim \
# jq \
# nano \
# "
# ENV PYTHONIOENCODING=utf-8
# ENV LANG=C.UTF-8

# # Install base packages and clean up in one layer
# RUN apt-get update && \
#     apt-get install --no-install-recommends -y ${PKGS} && \
#     apt-get autoremove --purge -y && \
#     rm -rf /var/lib/apt/lists/*

# # Add user
# ARG USER_ID="1001"
# RUN adduser --disabled-password --gecos "" --shell /bin/bash --uid ${USER_ID} ubuntu

# # Install tools with cleanup
# # hadolint
# ARG HADOLINT_VERSION="v2.12.0"
# RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "x86_64" || echo "arm64" ) && \
#     curl -Lo /usr/local/bin/hadolint "https://github.com/hadolint/hadolint/releases/download/${HADOLINT_VERSION}/hadolint-Linux-${ARCH}" && \
#     chmod +x /usr/local/bin/hadolint

# # tfenv
# COPY --chown=ubuntu ./.terraform-version /opt/.terraform-version
# RUN git clone --depth 1 https://github.com/tfutils/tfenv.git /opt/tfenv && \
#     ln -s /opt/tfenv/bin/tfenv /usr/local/bin && \
#     ln -s /opt/tfenv/bin/terraform /usr/local/bin && \
#     mkdir -p /opt/tfenv/versions && \
#     dos2unix /opt/.terraform-version && \
#     tfenv install && \
#     chown -R ubuntu:root /opt/tfenv && \
#     rm -rf /opt/tfenv/.git

# # # tgenv
# # COPY --chown=ubuntu ./.terragrunt-version /opt/.terragrunt-version
# # RUN git clone --depth 1 https://github.com/cunymatthieu/tgenv.git /opt/tgenv && \
# #     ln -s /opt/tgenv/bin/tgenv /usr/local/bin && \
# #     ln -s /opt/tgenv/bin/terragrunt /usr/local/bin && \
# #     mkdir -p /opt/tgenv/versions && \
# #     dos2unix /opt/.terragrunt-version && \
# #     TGENV_ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
# #     TGENV_ARCH=${TGENV_ARCH} tgenv install && \
# #     chown -R ubuntu:root /opt/tgenv && \
# #     rm -rf /opt/tgenv/.git

# # tfsec
# ARG TFSEC_VERSION="1.28.6"
# RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
#     curl -Lo /usr/local/bin/tfsec "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCH}" && \
#     chmod +x /usr/local/bin/tfsec

# # trivy
# ARG TRIVY_VERSION="0.18.3"
# RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v${TRIVY_VERSION}

# # tflint
# ARG TFLINT_VERSION="0.51.1"
# RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
#     curl -Lo /tmp/tflint.zip "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCH}.zip" && \
#     unzip /tmp/tflint.zip -d /usr/local/bin && \
#     rm -f /tmp/tflint.zip

# # tflint azurerm plugin
# ARG TFLINT_AZURERM_PLUGIN="0.12.0"
# RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
#     mkdir -p /home/ubuntu/.tflint.d/plugins && \
#     curl -Lo /tmp/tflint-ruleset-azurerm.zip "https://github.com/terraform-linters/tflint-ruleset-azurerm/releases/download/v${TFLINT_AZURERM_PLUGIN}/tflint-ruleset-azurerm_linux_${ARCH}.zip" && \
#     unzip /tmp/tflint-ruleset-azurerm.zip -d /home/ubuntu/.tflint.d/plugins && \
#     chown -R ubuntu:ubuntu /home/ubuntu/.tflint.d && \
#     rm -f /tmp/tflint-ruleset-azurerm.zip

# # terraform-docs
# ARG TERRAFORM_DOCS_VERSION="0.18.0"
# RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "amd64" || echo "arm64" ) && \
#     curl -Lo /tmp/terraform-docs.tar.gz "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${ARCH}.tar.gz" && \
#     tar -xzf /tmp/terraform-docs.tar.gz -C /usr/local/bin terraform-docs && \
#     chmod +x /usr/local/bin/terraform-docs && \
#     rm -f /tmp/terraform-docs.tar.gz

# # aws cli
# RUN ARCH=$( [ "$TARGETPLATFORM" = "linux/amd64" ] && echo "x86_64" || echo "aarch64" ) && \
#     curl -Lo "/tmp/awscliv2.zip" "https://awscli.amazonaws.com/awscli-exe-linux-${ARCH}.zip" && \
#     unzip -qq /tmp/awscliv2.zip -d /tmp && \
#     /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update && \
#     rm -rf /tmp/aws /tmp/awscliv2.zip

# # Install Python tools as ubuntu user
# USER ubuntu
# ENV PATH="$PATH:/home/ubuntu/.local/bin"
# RUN pip3 install --no-cache-dir --user \
#     azure-cli \
#     checkov \
#     pre-commit==3.6.0

# # motd
# COPY ./.devcontainer/etc/update-motd.d/00-header /etc/update-motd.d/00-header

# # # cleanup
# # RUN apt autoremove --purge -y && \
# #     find /opt /usr/lib -name __pycache__ -print0 | xargs --null rm -rf && \
# #     rm -rf /var/lib/apt/lists/*

# # Final setup
# WORKDIR /app

# RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
#     && omz theme set cloud \
#     && sleep 5 \
#     && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-/home/ubuntu/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
#     && git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-/home/ubuntu/.oh-my-zsh/custom}/plugins/you-should-use \
#     && git clone https://github.com/fdellwing/zsh-bat.git ${ZSH_CUSTOM:-/home/ubuntu/.oh-my-zsh/custom}/plugins/zsh-bat \
#     && git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git ${ZSH_CUSTOM:-/home/ubuntu/.oh-my-zsh/custom}/plugins/zsh-autocomplete 

# COPY ./script/.zshrc /home/ubuntu/.zshrc