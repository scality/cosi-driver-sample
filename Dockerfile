# syntax = docker/dockerfile:1-experimental

FROM --platform=${BUILDPLATFORM} docker.io/golang:1.16.3-buster AS base
ARG BUILDPLATFORM
WORKDIR /usr/src/cosi-provisioner-sample
COPY go.mod go.sum ./
RUN go mod download

FROM base AS build
ARG TARGETOS
ARG TARGETARCH
RUN --mount=target=. \
    CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build \
        -mod=readonly \
        -ldflags '-s -w -extldflags -static' \
        -o /out/cosi-provisioner-sample \
	./cmd/cosi-provisioner-sample/

FROM base AS test
ARG BUILDOS
ARG BUILDARCH
RUN --mount=target=. \
    CGO_ENABLED=0 \
    GOOS=${BUILDOS} \
    GOARCH=${BUILDARCH} \
    go build \
        -mod=readonly \
        -ldflags '-s -w -extldflags -static' \
	-o /out/cosi-provisioner-sample \
	./cmd/cosi-provisioner-sample \
	&& \
    rm -f /out/cosi-provisioner-sample
ENTRYPOINT ["go", "test", "-mod=readonly", "-v", "./..."]

# gcr.io/distroless/static:nonroot
FROM --platform=${TARGETPLATFORM} gcr.io/distroless/static@sha256:cd784033c94dd30546456f35de8e128390ae15c48cbee5eb7e3306857ec17631 as bin
ARG TARGETPLATFORM
COPY --from=build /out/cosi-provisioner-sample /
ENTRYPOINT ["/cosi-provisioner-sample"]