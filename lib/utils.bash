#!/usr/bin/env bash

set -euo pipefail

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for lefthook.
GH_REPO="https://github.com/evilmartians/lefthook"
TOOL_NAME="lefthook"
TOOL_TEST="lefthook --version"

TAR_GZ_FILE_EXT=".tar.gz"

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if lefthook is not hosted on GitHub releases.
if [ -n "${GITHUB_API_TOKEN:-}" ]; then
  curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
  sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
    LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
  git ls-remote --tags --refs "$GH_REPO" |
    grep -o 'refs/tags/.*' | cut -d/ -f3- |
    sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
  # TODO: Adapt this. By default we simply list the tag names from GitHub releases.
  # Change this function if lefthook has other means of determining installable versions.
  list_github_tags
}

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

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="${3%/bin}/bin"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path"
    cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

    # TODO: Assert <YOUR TOOL> executable exists.
    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error occurred while installing $TOOL_NAME $version."
  )
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
  local bit_arch="$(get_bit_arch)"
  local arch="$(get_arch)"
  if [ "${arch}" = "MacOS" ] && [ "${bit_arch}" = "arm64" ]; then
    local first="$(echo "${version}" | cut -d'.' -f1)"
    local second="$(echo "${version}" | cut -d'.' -f2)"
    local third="$(echo "${version}" | cut -d'.' -f3)"
    if [ "${first}" = "0" ]; then
      if ((${second} < 7)); then
        fail_unsupported_version "${version}" "${arch}" "${bit_arch}"
      fi
      if [ "${second}" = "7" ] && ((${third} <= 3)); then
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
  echo "$GH_REPO/releases/download/v${version}/$(release_file_name $version $ext)"
}
