FROM alpine:3.14

LABEL maintainer=lifengming666@gmail.com
LABEL description="mini runtime environment"

#WORKDIR /opt/application
#
#ARG USER=root
#ARG GROUP=root
#ARG UID=1001
#ARG GID=1001

RUN apk update  \
    && apk upgrade \
    && apk add --no-cache ca-certificates tzdata \
    && update-ca-certificates \
    && rm -rf /var/cache/apk/* \
    && ln -snf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone \
    && apk del tzdata

#RUN addgroup -g ${GID} -S ${GROUP} \
#    && adduser \
#    --disabled-password \
#    --gecos "" \
#    --home "$(pwd)" \
#    --ingroup ${GROUP} \
#    --no-create-home \
#    --uid ${UID} \
#    ${USER} \
#    && chown ${USER}:${GROUP} -R "$(pwd)"
#
#USER ${USER}
