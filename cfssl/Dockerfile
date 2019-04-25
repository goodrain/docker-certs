FROM alpine:3.5

RUN apk --no-cache add tzdata bash

ENV TZ Asia/Shanghai

ADD bin/ /usr/bin/
ADD config /etc/cfssl
ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]