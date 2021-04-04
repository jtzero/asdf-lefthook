#!/usr/bin/env bash

set -euo pipefail

# TODO: Ensure this is the correct GitHub homepage where releases can be downloaded for <YOUR TOOL>.
GH_REPO="https://github.com/Arkweid/lefthook"
TOOL_NAME="lefthook"
TOOL_TEST="lefthook --version"

if [ -n "${DEBUG:-}" ]; then
  set -x
fi

get_arch() {
  uname
}

get_bit_arch() {
  uname -m
}

release_file_name() {
  local version="${1}"
  echo "${TOOL_NAME}_${version}_$(get_arch)_$(get_bit_arch).gz"
}


get_download_url() {
  local version="${1}"
  local downloaded_filename="${2}"
  # https://github.com/Arkweid/lefthook/releases/download/v0.7.2/lefthook_0.7.2_Linux_i386.gz
  echo "$GH_REPO/releases/download/v${version}/$(release_file_name $version)"
}

extract(){
  local release_file_no_extension="${1}"
  local install_path="${2}"
  local release_file="${release_file_no_extension}.gz"

  gunzip "$release_file" || fail "Could not extract $release_file"
  #tar -xzf "$release_file" -C "$install_path" --strip-components=1 || fail "Could not extract $release_file"
  #rm "$release_file"

  mkdir -p "${install_path}/bin"
  mv "${release_file_no_extension}" "${install_path}/bin/lefthook"
  chmod +x "${install_path}/bin/lefthook"
}

###########################

fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

curl_opts=(-fsSL)

# NOTE: You might want to remove this if <YOUR TOOL> is not hosted on GitHub releases.
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
  # Change this function if <YOUR TOOL> has other means of determining installable versions.
  list_github_tags
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"

  # TODO: Adapt the release URL convention for <YOUR TOOL>
  url="$(get_download_url $version $filename)"

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  # TODO: Adapt this to proper extension and adapt extracting strategy.
  local release_file_no_ext="$install_path/$TOOL_NAME-$version"
  local release_file="${release_file_no_ext}.gz"
  (
    mkdir -p "$install_path"
    download_release "$version" "$release_file"
    extract "${release_file_no_ext}" "${install_path}"

    # TODO: Asert <YOUR TOOL> executable exists.
    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error ocurred while installing $TOOL_NAME $version."
  )
}
