FROM ubuntu:24.04

LABEL maintainer="Jason Harvey <alienth@gmail.com>"
ENV DEBIAN_FRONTEND noninteractive

RUN apt update \
    && apt install -y \
    curl \
    ca-certificates \
    && apt -y clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && rm -rf /var/tmp/*

RUN curl -L -o /usr/local/bin/kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && chmod 755 /usr/local/bin/kubectl

COPY backup.sh /

ENTRYPOINT ["/backup.sh"]
