FROM alpine:latest

RUN apk add --no-cache postgresql-client curl bash jq

COPY backup.sh /backup.sh
RUN chmod +x /backup.sh

CMD ["/backup.sh"]
