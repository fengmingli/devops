FROM lifengming/base:1.0.0

LABEL maintainer=lifengming666@gmail.com
LABEL description="java runtime"

USER root

# arthas
COPY --chown=root:root --from=hengyunabc/arthas:latest /opt/arthas /opt/arthas

RUN apk update && apk upgrade && apk add openjdk11

USER root
