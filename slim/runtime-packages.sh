#!/usr/bin/env bash

# Prints the packages providing the shared libraries needed by the ELF files of a staging directory.
#
# The files of the packages given after the staging directory are copied into it instead of being listed,
# without their Qt plugins: their dependencies are then only the ones of the libraries actually linked.
#
# Usage: runtime-packages.sh STAGING_DIR [COPIED_PACKAGE...]

set -euo pipefail

STAGING=$1
shift
COPIED_PACKAGES=("$@")

for PACKAGE in "${COPIED_PACKAGES[@]}"; do
  dpkg -L "${PACKAGE}" | while read -r FILE; do
    if [[ -f ${FILE} && ${FILE} != /usr/share/doc/* && ${FILE} != */qt6/plugins/* ]]; then
      cp -a --parents "${FILE}" "${STAGING}"
    fi
  done
done

# ldd fails on the executable scripts
LIBRARIES=$(
  find "${STAGING}" -type f \( -name '*.so*' -o -perm -u+x \) -print0 \
    | { xargs -0 ldd 2>/dev/null || true; } \
    | awk '$2 == "=>" && $3 ~ /^\// {print $3}' \
    | sort -u
)

# the libraries built in the builder do not belong to any package
PACKAGES=$(
  for LIBRARY in ${LIBRARIES}; do
    dpkg -S "$(realpath "${LIBRARY}")" 2>/dev/null || dpkg -S "${LIBRARY}" 2>/dev/null || true
  done | sed -nE 's/^([^:, ]+)(:[a-z0-9]+)?: .*/\1/p' | sort -u
)

for PACKAGE in ${PACKAGES}; do
  if [[ " ${COPIED_PACKAGES[*]} " != *" ${PACKAGE} "* ]]; then
    echo "${PACKAGE}"
  fi
done
