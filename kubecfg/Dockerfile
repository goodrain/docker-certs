FROM debian:buster-slim

MAINTAINER ysicing

ENV TZ=Asia/Shanghai

# curl
RUN apt update && apt install -y --no-install-recommends curl openssl ca-certificates\
        && rm -rf /var/lib/apt/lists/*

ADD kubectl /usr/bin/kubectl

COPY run.sh /run.sh

RUN mkdir /k8s

WORKDIR /k8s

RUN chmod +x /run.sh /usr/bin/kubectl

ENTRYPOINT [ "/run.sh" ]