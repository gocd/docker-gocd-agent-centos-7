# Copyright 2022 Thoughtworks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/gocd.
# Please file any issues or PRs at https://github.com/gocd/gocd
###############################################################################################

FROM curlimages/curl:latest as gocd-agent-unzip
USER root
ARG UID=1000
RUN curl --fail --location --silent --show-error "https://download.gocd.org/binaries/22.3.0-15301/generic/go-agent-22.3.0-15301.zip" > /tmp/go-agent-22.3.0-15301.zip && \
    unzip /tmp/go-agent-22.3.0-15301.zip -d / && \
    mv /go-agent-22.3.0 /go-agent && \
    chown -R ${UID}:0 /go-agent && \
    chmod -R g=u /go-agent

FROM docker.io/centos:7

LABEL gocd.version="22.3.0" \
  description="GoCD agent based on docker.io/centos:7" \
  maintainer="GoCD Team <go-cd-dev@googlegroups.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="22.3.0-15301" \
  gocd.git.sha="9d23ed19a9ea46eaf7f18bd16671ae0569871f53"

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-amd64 /usr/local/sbin/tini

# force encoding
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"
ENV BASH_ENV="/opt/rh/rh-git227/enable"
ENV ENV="/opt/rh/rh-git227/enable"

ARG UID=1000
ARG GID=1000

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
# add user to root group for GoCD to work on openshift
  useradd -l -u ${UID} -g root -d /home/go -m go && \
    yum install --assumeyes centos-release-scl-rh && \
  yum update -y && \
  yum upgrade -y && \
  yum install -y rh-git227 mercurial subversion openssh-clients bash unzip procps sysvinit-tools coreutils curl && \
  cp /opt/rh/rh-git227/enable /etc/profile.d/rh-git227.sh && \
  yum clean all && \
  rm -rf /var/cache/yum && \
  curl --fail --location --silent --show-error 'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.5%2B8/OpenJDK17U-jre_x64_linux_hotspot_17.0.5_8.tar.gz' --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /go-agent /docker-entrypoint.d /go /godata

ADD docker-entrypoint.sh /


COPY --from=gocd-agent-unzip /go-agent /go-agent
# ensure that logs are printed to console output
COPY --chown=go:root agent-bootstrapper-logback-include.xml agent-launcher-logback-include.xml agent-logback-include.xml /go-agent/config/

RUN chown -R go:root /docker-entrypoint.d /go /godata /docker-entrypoint.sh && \
    chmod -R g=u /docker-entrypoint.d /go /godata /docker-entrypoint.sh


ENTRYPOINT ["/docker-entrypoint.sh"]

USER go
