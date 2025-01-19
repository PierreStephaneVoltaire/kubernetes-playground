FROM hashicorp/terraform:light
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    git \
    openssl \
    python3 \
    py3-pip && \
    pip install --no-cache-dir awscli && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

WORKDIR /terraform

COPY . .
RUN terraform init  -backend-config=".\.config\state.config"
ENTRYPOINT ["terraform plan"]
