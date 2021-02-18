# Copyright 2016 The Kubernetes Authors All rights reserved.
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

ARG GOVERSION=1.15
FROM golang:${GOVERSION} as builder
ARG GOARCH
ENV GOARCH=${GOARCH}
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update
RUN apt-get -y install libsystemd-dev
WORKDIR /go/src/k8s.io/node-problem-detector/
COPY . /go/src/k8s.io/node-problem-detector/

RUN make build-binaries

FROM k8s.gcr.io/build-image/debian-base:v2.1.3
MAINTAINER Random Liu <lantaol@google.com>
RUN clean-install util-linux libsystemd0 bash
RUN test -h /etc/localtime && rm -f /etc/localtime && cp /usr/share/zoneinfo/UTC /etc/localtime || true
COPY --from=builder /go/src/k8s.io/node-problem-detector/bin/node-problem-detector /
COPY --from=builder /go/src/k8s.io/node-problem-detector/bin/health-checker /home/kubernetes/bin/
COPY config /config
ENTRYPOINT ["/node-problem-detector", "--config.system-log-monitor=/config/kernel-monitor.json"]
