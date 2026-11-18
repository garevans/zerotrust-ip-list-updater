# Release 1.3. /app/update.sh is mode 0755 and /app/data is mode 0777 so the
# container can run as a non-root user (for example user: "1000:999").
# The default user is still root.
# Alpine 3.24 is the current supported stable release.
# Its ca-certificates-bundle 20261020 drops eMudhra emSign ECC Root CA - G3,
# which Alpine 3.19 (release 1.1) still trusted. emSign Root CA - G1 remains
# in the upstream bundle and is left in place.
FROM alpine:3.24

RUN apk add --no-cache curl bash

WORKDIR /app
COPY update.sh /app/update.sh

# Absolute mode, not `chmod +x`. The published 1.2 image left update.sh at
# 0771 (world-executable, not world-readable). Bash has to read the script,
# so a non-root user failed with "Permission denied". 0755 keeps root working.
RUN chmod 755 /app/update.sh

# Any uid the orchestrator sets must be able to create last_ip.txt. A mounted
# volume replaces this directory and keeps its own ownership. Root can still
# write a mode 0777 directory.
RUN mkdir -p /app/data && chmod 777 /app/data

CMD ["/app/update.sh"]
