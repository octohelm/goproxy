FROM gcr.io/distroless/static-debian10:latest

ARG TARGETARCH
COPY ./bin/goproxy-linux-${TARGETARCH} /goproxy

ENTRYPOINT ["/goproxy"]