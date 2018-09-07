#!/bin/sh
PATHISO="/var/lib/vz/template/iso/"
inotifywait -m -e create,modify,close,move --format '%w%f %e %T' --timefmt '%Y-%m-%d %H:%M:%S' "${PATHISO}" > /var/log/check_ova_file.log