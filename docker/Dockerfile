FROM golang:1.19 as build_sales-api
ENV CGO_ENABLED 0
ARG BUILD_REF

COPY ../service/main.go /service/
COPY ../service/go.mod /service/

WORKDIR /service
RUN go build -ldflags "-X main.build=${BUILD_REF}"

FROM alpine:3.14
ARG BUILD_DATE
ARG BUILD_REF
COPY --from=build_sales-api /service /service-video
WORKDIR /service 
CMD ["./service"] 

