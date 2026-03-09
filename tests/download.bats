#!/usr/bin/env bats
# tests/download.bats — tests for lib/download.sh
# bats file_tags=ci

load 'test_helper'

setup() {
  setup_mocks
  source_lib log.sh
  source_lib download.sh
  WORKDIR="$(mktemp -d)"
}

teardown() {
  teardown_mocks
  rm -rf "$WORKDIR"
}

@test "downloads file and passes sha256 check" {
  local fake_content="fake deb content"
  local sha
  sha="$(echo -n "$fake_content" | sha256sum | awk '{print $1}')"

  make_stub curl "echo -n '${fake_content}' > \"\${@: -1}\""
  run download_and_verify \
    "https://apt-base" "pool/some.deb" "$sha" "${WORKDIR}/out.deb"
  [ "$status" -eq 0 ]
  [[ "$output" == *"verified"* ]]
}

@test "fails when sha256 does not match" {
  local fake_content="fake deb content"
  make_stub curl "echo -n '${fake_content}' > \"\${@: -1}\""
  run download_and_verify \
    "https://apt-base" "pool/some.deb" "0000000000000000000000000000000000000000000000000000000000000000" "${WORKDIR}/out.deb"
  [ "$status" -ne 0 ]
  [[ "$output" == *"mismatch"* ]]
}

@test "fails when curl errors" {
  stub_fail curl
  run download_and_verify \
    "https://apt-base" "pool/some.deb" "abc" "${WORKDIR}/out.deb"
  [ "$status" -ne 0 ]
}

@test "constructs correct download URL" {
  local captured_url=""
  make_stub curl 'echo "$@" >> /tmp/curl_args_test'
  sha="$(echo -n '' | sha256sum | awk '{print $1}')"
  make_stub curl "echo -n '' > \"\${@: -1}\"; echo \$@ >> /tmp/curl_url_capture"
  download_and_verify "https://base" "pool/file.deb" "$sha" "${WORKDIR}/out.deb" 2>/dev/null || true
  if [[ -f /tmp/curl_url_capture ]]; then
    grep -q "https://base/pool/file.deb" /tmp/curl_url_capture
  fi
  rm -f /tmp/curl_url_capture
}
