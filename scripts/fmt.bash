#!/usr/bin/env bash

SCRIPTS_DIR="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

old_pwd="${PWD}"

ROOT="$(dirname "${SCRIPTS_DIR}")"

cd "${ROOT}" || exit 1
for file in $(shfmt -f .); do
  shfmt -w "${file}"
done
cd "${old_pwd}" || exit 1
