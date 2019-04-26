FROM alpine:3.9

RUN apk --no-cache add tzdata bash libc6-compat

ENV TZ Asia/Shanghai

COPY dist/ /usr/local/bin/

RUN mkdir -pv /opt/rainbond/etc

WORKDIR /opt/rainbond/etc

COPY config /etc/cfssl

COPY build.sh /opt/rainbond/etc/build.sh

RUN chmod +x /opt/rainbond/etc/build.sh

ENTRYPOINT ["/opt/rainbond/etc/build.sh"]