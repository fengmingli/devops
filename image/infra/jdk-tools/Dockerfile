FROM registry.access.redhat.com/ubi8/ubi-minimal:latest

LABEL maintainer=lifengming666@gmail.com
LABEL version="1.0.0"
LABEL type="redhat"
LABEL description="jdk tools"

ARG JAVA_VERSION=11
ARG TARGETPLATFORM

USER root

RUN microdnf update \
    && microdnf install java-${JAVA_VERSION}-openjdk-devel openssl procps shadow-utils \
    && microdnf clean all \
    && cp -R /usr/lib/jvm/jre-11/bin /opt/java-tools \
    && cd /opt/java-tools \
    && rm -f alt-java  java  jjs  keytool  pack200  rmid  rmiregistry  unpack200

