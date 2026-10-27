#!/usr/bin/env bash
# Resolve only the official standalone Antigravity IDE Linux ARM64 archive URL.
extract_antigravity_ide_url() {
  local html_file="$1"
  sed 's|\\/|/|g' "$html_file" |
    grep -Eo 'https://edgedl\.me\.gvt1\.com/edgedl/release2/[A-Za-z0-9_-]+/antigravity/stable/[0-9]+\.[0-9]+\.[0-9]+-[0-9]+/linux-arm/Antigravity%20IDE\.tar\.gz' |
    head -n 1 || true
}
extract_antigravity_ide_version() {
  printf '%s\n' "$1" | sed -nE 's#^.*/stable/([0-9]+\.[0-9]+\.[0-9]+)-[0-9]+/linux-arm/Antigravity%20IDE\.tar\.gz$#\1#p'
}
