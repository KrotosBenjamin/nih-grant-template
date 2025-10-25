#!/usr/bin/env bash
#
# update_boilerplate_submodule.sh
#
# Bump the boilerplate submodule in this repo to a branch (default: main), tag, or specific commit.
# Records the new submodule pointer in the parent repo with a clear commit message.
#
# Usage:
#   ./update_boilerplate_submodule.sh                # update 'common' to latest origin/main
#   ./update_boilerplate_submodule.sh --path common --branch main
#   ./update_boilerplate_submodule.sh --path common --tag v0.3.0
#   ./update_boilerplate_submodule.sh --path common --sha abc1234
#   ./update_boilerplate_submodule.sh --status       # show current submodule status and exit
#   ./update_boilerplate_submodule.sh --push         # push parent commit after updating
#
set -euo pipefail

PATH_IN_PARENT="common"
REF_TYPE="branch"
REF_VALUE="main"
DO_PUSH="false"
DO_STATUS="false"

usage() {
  cat <<'EOF'
update_boilerplate_submodule.sh

Options:
  --path <dir>      Submodule path in this repo (default: common)
  --branch <name>   Update to latest commit on this branch (default: main)
  --tag <tag>       Update to this tag (exclusive with --branch/--sha)
  --sha <commit>    Update to this exact commit SHA (exclusive with --branch/--tag)
  --push            Push the parent repo after committing the new pointer
  --status          Show current submodule status and exit
  -h, --help        Show this help
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      PATH_IN_PARENT="$2"; shift 2;;
    --branch)
      REF_TYPE="branch"; REF_VALUE="$2"; shift 2;;
    --tag)
      REF_TYPE="tag"; REF_VALUE="$2"; shift 2;;
    --sha)
      REF_TYPE="sha"; REF_VALUE="$2"; shift 2;;
    --push)
      DO_PUSH="true"; shift;;
    --status)
      DO_STATUS="true"; shift;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown argument: $1" >&2; usage; exit 1;;
  esac
done

# Ensure we're in a Git repo
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: run this script from within a Git repository." >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Submodule must exist
if [[ ! -d "$PATH_IN_PARENT" ]]; then
  echo "Error: submodule path '$PATH_IN_PARENT' not found in repo root: $REPO_ROOT" >&2
  echo "Hint: git submodule add <URL> $PATH_IN_PARENT && git submodule update --init --recursive" >&2
  exit 1
fi

if [[ "$DO_STATUS" == "true" ]]; then
  echo "== Submodule status =="
  git submodule status "$PATH_IN_PARENT" || true
  echo "== Submodule remote =="
  git -C "$PATH_IN_PARENT" remote -v || true
  exit 0
fi

echo "== Initializing submodule if needed =="
git submodule update --init "$PATH_IN_PARENT"

# Check for local changes in the submodule
if [[ -n "$(git -C "$PATH_IN_PARENT" status --porcelain)" ]]; then
  echo "Error: uncommitted changes found inside submodule '$PATH_IN_PARENT'." >&2
  echo "Please commit or stash them in the submodule first." >&2
  exit 1
fi

# Update to requested ref
case "$REF_TYPE" in
  branch)
    echo "== Setting submodule '$PATH_IN_PARENT' to branch '$REF_VALUE' and updating to latest =="
    git config -f .gitmodules "submodule.$PATH_IN_PARENT.branch" "$REF_VALUE"
    git submodule sync -- "$PATH_IN_PARENT"
    git -C "$PATH_IN_PARENT" fetch origin "$REF_VALUE" --tags
    git -C "$PATH_IN_PARENT" checkout -B "$REF_VALUE" "origin/$REF_VALUE"
    ;;
  tag)
    echo "== Updating submodule '$PATH_IN_PARENT' to tag '$REF_VALUE' =="
    git -C "$PATH_IN_PARENT" fetch --tags --prune
    git -C "$PATH_IN_PARENT" checkout "tags/$REF_VALUE"
    ;;
  sha)
    echo "== Updating submodule '$PATH_IN_PARENT' to commit '$REF_VALUE' =="
    git -C "$PATH_IN_PARENT" fetch --all --tags --prune
    git -C "$PATH_IN_PARENT" checkout "$REF_VALUE"
    ;;
  *)
    echo "Internal error: unknown REF_TYPE '$REF_TYPE'" >&2
    exit 1
    ;;
esac

# Capture new commit info
NEW_SHA="$(git -C "$PATH_IN_PARENT" rev-parse HEAD)"
NEW_SHA_SHORT="$(git -C "$PATH_IN_PARENT" rev-parse --short=12 HEAD)"
REMOTE_URL="$(git -C "$PATH_IN_PARENT" remote get-url origin || echo 'origin')"

# Stage the submodule pointer change
git add "$PATH_IN_PARENT"

# If nothing to commit (already at desired state), exit gracefully
if git diff --cached --quiet -- "$PATH_IN_PARENT"; then
  echo "Submodule pointer is already up-to-date ($NEW_SHA_SHORT). Nothing to commit."
  exit 0
fi

# Build commit message
case "$REF_TYPE" in
  branch) MSG="Update boilerplate submodule '$PATH_IN_PARENT' to latest '${REF_VALUE}' (${NEW_SHA_SHORT})";;
  tag)    MSG="Pin boilerplate submodule '$PATH_IN_PARENT' to tag '${REF_VALUE}' (${NEW_SHA_SHORT})";;
  sha)    MSG="Pin boilerplate submodule '$PATH_IN_PARENT' to commit ${NEW_SHA_SHORT}";;
esac

echo "== Committing parent pointer =="
git commit -m "${MSG}" -m "Repo: ${REMOTE_URL}"

if [[ "$DO_PUSH" == "true" ]]; then
  echo "== Pushing parent repo =="
  git push
fi

echo "Done."
echo "Submodule:   $PATH_IN_PARENT"
echo "Remote URL:  $REMOTE_URL"
echo "Ref:         $REF_TYPE $REF_VALUE"
echo "New commit:  $NEW_SHA"
