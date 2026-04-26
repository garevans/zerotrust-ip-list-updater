FROM alpine:3.19

RUN apk add --no-cache curl bash

WORKDIR /app
COPY update.sh /app/update.sh

RUN chmod +x /app/update.sh

RUN mkdir -p /app/data

CMD ["/app/update.sh"]
