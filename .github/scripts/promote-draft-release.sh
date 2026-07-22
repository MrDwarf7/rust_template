#!/usr/bin/env bash
# Promote a draft GitHub Release (created by the Draft workflow) to published.
#
# Why this exists (and why we do not use svenstaro/upload-release-action here):
#   GET /repos/{owner}/{repo}/releases/tags/{tag} does NOT return drafts.
#   Actions that look up by tag see a 404, try to create, and fail with a
#   misleading "Not Found" while a draft already holds the assets.
#   Draft attaches the zips; this script only flips draft -> published.
#
# Usage:
#   promote-draft-release.sh [TAG]
#
# TAG resolution order:
#   1. $1 positional
#   2. $TAG env
#   3. $INPUT_TAG env (workflow_dispatch input)
#   4. $GITHUB_REF_NAME when $GITHUB_REF is refs/tags/*
#
# Required env:
#   GH_TOKEN           -- token with contents:write (github.token is fine)
#   GITHUB_REPOSITORY  -- owner/repo (set automatically on GHA runners)
#
# Optional env:
#   MAX_ATTEMPTS  -- poll count (default 30)
#   SLEEP_SECS    -- seconds between polls (default 20)
#
set -euo pipefail

MAX_ATTEMPTS="${MAX_ATTEMPTS:-30}"
SLEEP_SECS="${SLEEP_SECS:-20}"

die() {
  echo "::error::$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

resolve_tag() {
  local tag="${1:-}"
  if [ -z "${tag}" ]; then
    tag="${TAG:-}"
  fi
  if [ -z "${tag}" ]; then
    tag="${INPUT_TAG:-}"
  fi
  if [ -z "${tag}" ] && [ "${GITHUB_REF:-}" = "refs/tags/${GITHUB_REF_NAME:-}" ]; then
    tag="${GITHUB_REF_NAME}"
  elif [ -z "${tag}" ] && [[ "${GITHUB_REF:-}" == refs/tags/* ]]; then
    tag="${GITHUB_REF_NAME:-${GITHUB_REF#refs/tags/}}"
  fi
  if [ -z "${tag}" ]; then
    die "No tag provided. Pass TAG as \$1, \$TAG, \$INPUT_TAG, or run on a tag ref."
  fi
  # strip accidental refs/tags/ prefix
  tag="${tag#refs/tags/}"
  printf '%s\n' "${tag}"
}

# List endpoint returns drafts; GET .../releases/tags/{tag} does NOT.
find_draft_id() {
  local tag="$1"
  gh api "repos/${GITHUB_REPOSITORY}/releases" --paginate \
    --jq ".[] | select(.tag_name == \"${tag}\" and .draft == true) | .id" \
    | head -n1
}

find_any_id() {
  local tag="$1"
  gh api "repos/${GITHUB_REPOSITORY}/releases" --paginate \
    --jq ".[] | select(.tag_name == \"${tag}\") | .id" \
    | head -n1
}

is_published() {
  local release_id="$1"
  local draft_state
  draft_state="$(gh api "repos/${GITHUB_REPOSITORY}/releases/${release_id}" --jq .draft)"
  [ "${draft_state}" = "false" ]
}

promote_release() {
  local release_id="$1"
  local tag="$2"
  echo "Promoting release ${release_id} (tag ${tag}) to published"
  gh api --method PATCH "repos/${GITHUB_REPOSITORY}/releases/${release_id}" \
    -f draft=false \
    -f make_latest=true \
    --jq '{id,tag_name,draft,prerelease,html_url,assets:[.assets[].name]}'
}

main() {
  require_cmd gh
  require_cmd head

  if [ -z "${GH_TOKEN:-}" ]; then
    die "GH_TOKEN is required (use github.token on Actions runners)"
  fi
  if [ -z "${GITHUB_REPOSITORY:-}" ]; then
    die "GITHUB_REPOSITORY is required (owner/repo)"
  fi

  local tag
  tag="$(resolve_tag "${1:-}")"
  echo "Publishing tag: ${tag}"

  # Draft.yml builds assets and opens a draft on the same tag push.
  # Poll until it appears (or until we see an already-published release).
  local rid="" attempt any
  for attempt in $(seq 1 "${MAX_ATTEMPTS}"); do
    rid="$(find_draft_id "${tag}" || true)"
    if [ -n "${rid}" ]; then
      echo "Found draft release id=${rid} for tag ${tag} (attempt ${attempt})"
      break
    fi

    any="$(find_any_id "${tag}" || true)"
    if [ -n "${any}" ] && is_published "${any}"; then
      echo "Release id=${any} for ${tag} is already published -- nothing to do"
      exit 0
    fi

    echo "No draft for ${tag} yet (attempt ${attempt}/${MAX_ATTEMPTS}); sleeping ${SLEEP_SECS}s"
    sleep "${SLEEP_SECS}"
  done

  if [ -z "${rid}" ]; then
    die "Timed out waiting for draft release on tag ${tag}. Ensure the Draft workflow ran on this tag and created a draft release."
  fi

  promote_release "${rid}" "${tag}"
}

main "$@"
