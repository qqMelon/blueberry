#!/usr/bin/env bash

VERBOSE="${VERBOSE:-1}"

function _log {
  level=$1
  shift

  namespace="$(basename "$(dirname "${BASH_SOURCE[2]}")")"
  if [ "${namespace}" = "." ]; then
      namespace=main
  fi

  >&2 printf "%-5s %s/${FUNCNAME[2]:-main} - %s\n" "$level" "${namespace}" "$*"
}
function info {
  if (( "${VERBOSE}" >= "1" )); then
    _log INFO "$*"
  fi
}

function runContainers {
  docker compose up --build -d
  docker compose exec aduneo-zone1 bash -c 'echo -e $(getent hosts nginx_zone1 | cut -d" " -f1)\\\tkeycloak1.zone1.example.com\\\tkeycloak1.ext.example.com\\\tkeycloak2.ext.example.com\\\taduneo.zone1.example.com >> /etc/hosts'
  docker compose exec -u root keycloak1 bash -c 'echo -e $(getent hosts nginx_zone1 | cut -d" " -f1)\\\tkeycloak1.zone1.example.com\\\tkeycloak2.ext.example.com\\\taduneo.zone1.example.com >> /etc/hosts'
  docker compose exec aduneo-zone2 bash -c 'echo -e $(getent hosts nginx_zone2 | cut -d" " -f1)\\\tkeycloak1.ext.example.com\\\tkeycloak2.zone2.example.com\\\tkeycloak2.ext.example.com\\\taduneo.zone2.example.com >> /etc/hosts'
  docker compose exec -u root keycloak2 bash -c 'echo -e $(getent hosts nginx_zone2 | cut -d" " -f1)\\\tkeycloak1.ext.example.com\\\tkeycloak2.zone2.example.com >> /etc/hosts'
}

if [ "$(docker compose ps -q | wc -l)" -gt 0 ]; then
  info "Some containers are running .. Restart POCSSO containers"
  docker compose down
  runContainers
else
  info "No containers are running .. Starting POCSSO containers .."
  runContainers
fi
