# syntax=docker/dockerfile:1

# Build Image
FROM golang:1.25.4-alpine3.22 AS builder

WORKDIR /build

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN go build -o fritzbox_exporter . \
    && mkdir /app \
    && mv fritzbox_exporter /app

WORKDIR /app

# Copy metrics configuration files
COPY metrics.json metrics-lua.json /app/

# Runtime Image
FROM alpine:3.22 as runtime-image

ARG REPO=CSchoch/fritzbox_exporter

LABEL org.opencontainers.image.source https://github.com/${REPO}

ENV USERNAME username
ENV PASSWORD password
ENV GATEWAY_URL http://fritz.box:49000
ENV GATEWAY_LUAURL http://fritz.box
ENV LISTEN_ADDRESS 0.0.0.0:9042

RUN mkdir /app \
    && addgroup -S -g 1000 fritzbox \
    && adduser -S -u 1000 -G fritzbox fritzbox \
    && chown -R fritzbox:fritzbox /app

WORKDIR /app

COPY --chown=fritzbox:fritzbox --from=builder /app /app

EXPOSE 9042

ENTRYPOINT [ "sh", "-c", "/app/fritzbox_exporter" ]
CMD [ "-username", "${USERNAME}", "-password", "${PASSWORD}", "-gateway-url", "${GATEWAY_URL}", "-gateway-luaurl", "${GATEWAY_LUAURL}", "-listen-address", "${LISTEN_ADDRESS}" ]
