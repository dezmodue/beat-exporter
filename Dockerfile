FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.20 as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app/
ADD . .

RUN export LDFLAGS="-s -X github.com/prometheus/common/version.Version=${GITVERSION} \
-X github.com/prometheus/common/version.Revision=${GITREVISION} \
-X github.com/prometheus/common/version.Branch=master \
-X github.com/prometheus/common/version.BuildDate=${TIME}"

RUN GO111MODULE=on CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -ldflags "${LDFLAGS}" -tags 'netgo static_build' -a -o beat-exporter main.go

FROM --platform=${TARGETPLATFORM:-linux/amd64} scratch
WORKDIR /app/
COPY --from=builder /app/beat-exporter /bin/beat-exporter
ENTRYPOINT ["/bin/beat-exporter"]
# Use buildx to build the multiarch image
# docker buildx build --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64 --tag dezmodue/beat-exporter:0.4.0 .