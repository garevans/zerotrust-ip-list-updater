# Release 1.2. Alpine 3.24 is the current supported stable release.
# Its ca-certificates-bundle 20261020 drops eMudhra emSign ECC Root CA - G3,
# which Alpine 3.19 (release 1.1) still trusted. emSign Root CA - G1 remains
# in the upstream bundle and is left in place.
FROM alpine:3.24

RUN apk add --no-cache curl bash

WORKDIR /app
COPY update.sh /app/update.sh

RUN chmod +x /app/update.sh

RUN mkdir -p /app/data

CMD ["/app/update.sh"]
