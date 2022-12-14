FROM golang:1.19-alpine3.16 as builder

RUN mkdir /build
# Add build requirements for librdkafka
RUN apk add build-base

# Get dependencies
WORKDIR /build
ADD go.mod /build/go.mod
ADD go.sum /build/go.sum
RUN go mod download

RUN mkdir /build/cmd

# Only copy relevant packages to docker container
ADD ./cmd /build/cmd

# Build
RUN GOOS=linux go build -tags musl,kafka -a --mod=readonly -installsuffix cgo -ldflags "-s -w -X 'main.buildtime=$(date -u '+%Y-%m-%d %H:%M:%S')' -extldflags '-static'" -o mainFile ./cmd/message-broker-benchmark

# Add data
RUN mkdir /build/tests
ADD ./tests /build/tests

FROM alpine
COPY --from=builder /build /app/
WORKDIR /app
CMD ["./mainFile"]
