############################################
# Stage 1 — Builder (OpenTofu + Terragrunt)
############################################
FROM alpine:latest AS builder

ARG OPENTOFU_VERSION=1.11.5
ARG TARGETARCH=amd64
ARG TERRAGRUNT_VERSION=0.99.2

RUN apk add --no-cache \
    curl \
    unzip \
    gnupg \
    ca-certificates \
    openssl \
    bash \
    python3 \
    py3-pip \
    gnupg \
    gnupg-keyboxd

WORKDIR /tmp

############################################
# Install OpenTofu with full verification
############################################
RUN set -eux && \
    BASE_URL="https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}" && \
    CHECKSUMS="tofu_${OPENTOFU_VERSION}_SHA256SUMS" && \
    GPGSIG="${CHECKSUMS}.gpgsig" && \
    BINARY="tofu_${OPENTOFU_VERSION}_linux_${TARGETARCH}.zip" && \
    \
    curl -fsSL https://get.opentofu.org/opentofu.asc | gpg --import && \
    \
    curl -fLO "${BASE_URL}/${BINARY}" && \
    curl -fLO "${BASE_URL}/${CHECKSUMS}" && \
    curl -fLO "${BASE_URL}/${GPGSIG}" && \
    \
    gpg --verify "${GPGSIG}" "${CHECKSUMS}" && \
    grep "${BINARY}" "${CHECKSUMS}" > checksum.txt && \
    sha256sum -c checksum.txt && \
    \
    unzip "${BINARY}" && \
    chmod +x tofu && \
    \
    rm -f "${BINARY}" "${CHECKSUMS}" "${GPGSIG}" checksum.txt

############################################
# Install Terragrunt
############################################
RUN set -eux && \
    FILE="terragrunt_linux_${TARGETARCH}" && \
    BASE_URL="https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}" && \
    \
    curl -fLO "${BASE_URL}/${FILE}" && \
    curl -fLO "${BASE_URL}/SHA256SUMS" && \
    curl -fLO "${BASE_URL}/SHA256SUMS.gpgsig" && \
    curl -fsSL https://gruntwork.io/.well-known/pgp-key.txt | gpg --import && \
    gpg --verify SHA256SUMS.gpgsig SHA256SUMS && \
    grep " ${FILE}$" SHA256SUMS > tg_checksum.txt && \
    sha256sum -c tg_checksum.txt && \
    chmod +x "${FILE}" && \
    mv "${FILE}" terragrunt && \
    \
    rm -f SHA256SUMS tg_checksum.txt

############################################
# Stage 2 — Final Runtime
############################################
FROM alpine:latest

#RUN echo "https://awscli.amazonaws.com/alpine/latest" >> /etc/apk/repositories
RUN apk add --no-cache \
        bash \
        git \
        openssh-client \
        curl \
        jq \
        python3 \
        aws-cli-v2 \
        aws-session-manager-plugin

# Create non-root user
RUN addgroup -S pipeline && adduser -S pipeline -G pipeline

WORKDIR /workspace

# Copy OpenTofu
COPY --from=builder /tmp/tofu /usr/local/bin/tofu

# Terraform compatibility symlink
RUN ln -s /usr/local/bin/tofu /usr/local/bin/terraform

# Copy Terragrunt
COPY --from=builder /tmp/terragrunt /usr/local/bin/terragrunt

RUN chown -R pipeline:pipeline /workspace

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER pipeline

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD []
