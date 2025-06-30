#!/usr/bin/env bash

set -euo pipefail

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

TAR_GZ_FILE_EXT=".tar.gz"

curl_opts=${curl_opts:-}

get_ext() {
  local version url ext
  version="$1"

  ext=""
  url="$(get_download_url "$version" "$ext")"
  if curl -s --fail -I "${url}" >/dev/null; then
    printf '%s' "${ext}"
  else
    ext=".gz"
    url="$(get_download_url "$version" "$ext")"
    if curl -s --fail -I "${url}" >/dev/null; then
      printf '%s' "${ext}"
    else
      ext="${TAR_GZ_FILE_EXT}"
      url="$(get_download_url "$version" "$ext")"
      if curl -s --fail -I "${url}" >/dev/null; then
        printf '%s' "${ext}"
      else
        fail "Cannot determine ext to download"
      fi
    fi
  fi
}

download_release() {
  local version filepath url
  version="$1"
  filepath="$2"
  ext="${3}"

  # TODO: Adapt the release URL convention for lefthook
  url="$(get_download_url "$version" "$ext")"

  echo "* Downloading $TOOL_NAME release $version... from ${url}"
  curl "${curl_opts[@]}" -o "$filepath" -C - "$url" || fail "Could not download $url"
}

extract_as_needed() {
  local version release_file download_path
  version="${1}"
  release_file="${2}"
  download_path="${3}"

  case "${ext}" in
  "${TAR_GZ_FILE_EXT}")
    handle_downloaded_release_tar "${release_file}" "${download_path}"
    ;;
  "gz")
    handle_downloaded_release_not_tar "${release_file}" "${download_path}" true
    ;;
  "")
    handle_downloaded_release_not_tar "${release_file}" "${download_path}" false
    ;;
  esac
}

handle_downloaded_release_tar() {
  local release_file, download_path
  release_file="${1}"
  download_path="${2}"

  tar -xzf "$release_file" -C "$download_path" --strip-components=1 || fail "Could not extract $release_file"
}

handle_downloaded_release_not_tar() {
  local release_file="${1}"
  local install_path="${2}"
  local extract=${3:-false}

  if [ "${extract}" = "true" ]; then
    gunzip "$release_file" || fail "Could not extract $release_file"
  fi

  mkdir -p "${install_path}"
  mv "${release_file}" "${install_path}/lefthook"
  chmod +x "${install_path}/lefthook"
}

rm_release_file_as_needed() {
  local release_file ext
  release_file="${1}"
  ext="${2}"
  if [ "${ext}" = "${TAR_GZ_FILE_EXT}" ]; then
    rm "${release_file}"
  fi
}

get_arch() {
  local -r uname_arch="$(uname)"
  if [ "${uname_arch}" = "Darwin" ]; then
    echo "MacOS"
  else
    echo "${uname_arch}"
  fi
}

get_bit_arch() {
  uname -m
}

release_file_name() {
  local version="${1}"
  local ext="${2:-}"
  local bit_arch arch first second third
  bit_arch="$(get_bit_arch)"
  arch="$(get_arch)"
  if [ "${arch}" = "MacOS" ] && [ "${bit_arch}" = "arm64" ]; then
    first="$(echo "${version}" | cut -d'.' -f1)"
    second="$(echo "${version}" | cut -d'.' -f2)"
    third="$(echo "${version}" | cut -d'.' -f3)"
    if [ "${first}" = "0" ]; then
      if ((second < 7)); then
        fail_unsupported_version "${version}" "${arch}" "${bit_arch}"
      fi
      if [ "${second}" = "7" ] && ((third <= 3)); then
        fail_unsupported_version "${version}" "${arch}" "${bit_arch}"
      fi
    fi
  fi
  echo "${TOOL_NAME}_${version}_$(get_arch)_$(get_bit_arch)${ext}"
}

fail_unsupported_version() {
  local version="${1}"
  local arch="${2}"
  local bit_arch="${3}"
  fail "'${version}' is not supported no this architecture '${arch}-${bit_arch}'"
}

get_download_url() {
  local version="${1}"
  local ext="${2:-}"
  echo "$GH_REPO/releases/download/v${version}/$(release_file_name "${version}" "${ext}")"
}
