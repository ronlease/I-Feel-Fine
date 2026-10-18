#!/usr/bin/env bash
# Stop: when .cs files changed, run a fast build and send failures back to Claude.
#
# Enforces: Claude does not finish a turn with code that does not compile, and does
# not leave a destructive migration without its DESTRUCTIVE-ACK line.
#
# Why: a broken build found at the end of a turn costs one more turn. Found at the
# pull request, it costs a review cycle. The hook honors stop_hook_active, so a
# build that stays broken cannot trap Claude in a loop. A build that exceeds the
# time limit counts as a skip, not a failure.
#
# Config (.claude/ifeelfine.json), optional:
#   "solution": "App.slnx"           Solution or project to build. Default: the shallowest
#                                    .slnx, .sln or .csproj found within four folders.
#   "stopVerifyTimeoutSeconds": 25   Build time limit. Keep it under the 30 second hook timeout.
#
# Needs jq and dotnet. Either missing means the hook exits 0 and does nothing.

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_tool jq
need_tool dotnet
read_input

[[ "$(json_get stop_hook_active)" == "true" ]] && exit 0

changed="$(git -C "$PROJECT_DIR" status --porcelain -uall 2>/dev/null | grep -E '\.cs$' || true)"
[[ -z "$changed" ]] && exit 0

# New migrations must acknowledge destructive changes.
if ! bash "$(dirname "${BASH_SOURCE[0]}")/guard-destructive-migration.sh" scan </dev/null; then
  exit 2
fi

# Find the shallowest solution or project file, preferring .slnx, then .sln, then .csproj.
discover_solution() {
  local depth ext found
  for depth in 1 2 3 4; do
    for ext in slnx sln csproj; do
      found="$(find "$PROJECT_DIR" -mindepth "$depth" -maxdepth "$depth" -name "*.$ext" \
        -not -path '*/node_modules/*' -not -path '*/bin/*' -not -path '*/obj/*' 2>/dev/null | head -n 1)"
      if [[ -n "$found" ]]; then
        printf '%s\n' "$found"
        return 0
      fi
    done
  done
  return 0
}

solution="$(cfg_get solution "")"
if [[ -n "$solution" ]]; then
  target="$PROJECT_DIR/$solution"
else
  target="$(discover_solution)"
fi
[[ -n "$target" && -e "$target" ]] || exit 0

limit="$(cfg_get stopVerifyTimeoutSeconds 25)"
[[ "$limit" =~ ^[0-9]+$ ]] || limit=25

output="$(cd "$PROJECT_DIR" && run_with_timeout "$limit" dotnet build "$target" --no-restore -nologo -v q -clp:ErrorsOnly 2>&1)"
code=$?

if [[ $code -eq 124 ]]; then
  echo "stop-verify: build exceeded ${limit}s, skipped. Run dotnet build before committing." >&2
  exit 0
fi
if [[ $code -ne 0 ]]; then
  echo "BUILD FAILED. Fix these errors before finishing:" >&2
  echo "$output" | tail -30 >&2
  exit 2
fi
exit 0
