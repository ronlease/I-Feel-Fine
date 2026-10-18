#!/usr/bin/env bash
# Shared helpers for the hooks in this plugin. Source this file; never run it.
#
# What it gives you:
#   - PROJECT_DIR: the repo Claude is working in (CLAUDE_PROJECT_DIR, else git root, else cwd).
#   - read_input / json_get: parse the JSON that Claude Code sends to a hook on stdin.
#   - cfg_get / cfg_get_lines: read optional settings from .claude/ifeelfine.json.
#   - normalize_path, lower, run_with_timeout, block: small portable helpers.
#
# Why: every hook needs the same parsing and the same safe defaults. Two rules
# hold for all of them. A missing tool (jq, dotnet, npx) means the hook exits 0
# without a word, so a hook you cannot use never fails your session. A missing
# or broken config file means defaults, never an error.
#
# Portable bash only: no bash 4 features, no GNU-only flags, so macOS works.
# The dotnet-angular plugin ships an identical copy. CI checks that they match.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-}"
if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi
CONFIG_FILE="$PROJECT_DIR/.claude/ifeelfine.json"
INPUT=""

# Exit 0 quietly when a tool is missing. Usage: need_tool jq
need_tool() {
  command -v "$1" >/dev/null 2>&1 || exit 0
}

read_input() {
  INPUT="$(cat)"
}

# Print a field of the hook input, e.g. json_get tool_input.command. Empty when absent.
json_get() {
  jq -r ".${1} // empty" <<<"$INPUT" 2>/dev/null || true
}

# Print a config value, or the default when the file, key or jq is missing or broken.
# Usage: cfg_get backlogDir docs/backlog
cfg_get() {
  local value=""
  if [[ -f "$CONFIG_FILE" ]]; then
    value="$(jq -r --arg k "$1" '.[$k] // empty | if type == "string" or type == "number" then tostring else empty end' "$CONFIG_FILE" 2>/dev/null || true)"
  fi
  if [[ -n "$value" ]]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "${2:-}"
  fi
}

# Print the entries of an array key as tab-separated "glob<TAB>message" lines.
# Usage: cfg_protected_paths
cfg_protected_paths() {
  [[ -f "$CONFIG_FILE" ]] || return 0
  jq -r '(.protectedPaths // [])
         | if type == "array" then .[] else empty end
         | select(type == "object" and (.glob | type == "string"))
         | [.glob, (.message // "protected path")] | @tsv' "$CONFIG_FILE" 2>/dev/null || true
}

# Lowercase a string. Replaces the bash 4 "${var,,}".
lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# Turn backslashes into slashes and "C:/x" into "/c/x" so Windows and Git Bash paths compare.
unixify_path() {
  local p="${1//\//}"
  if [[ "$p" =~ ^([A-Za-z]):/(.*)$ ]]; then
    p="/$(lower "${BASH_REMATCH[1]}")/${BASH_REMATCH[2]}"
  fi
  printf '%s' "$p"
}

# Print the path relative to the project, with forward slashes.
normalize_path() {
  local p root
  p="$(unixify_path "$1")"
  root="$(unixify_path "$PROJECT_DIR")"
  printf '%s\n' "${p#"$root"/}"
}

# Run a command with a time limit when timeout or gtimeout exists. Otherwise run it
# unbounded and rely on the hook's own timeout in hooks.json. Exit 124 means timed out.
run_with_timeout() {
  local seconds="$1"
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$seconds" "$@"
  else
    "$@"
  fi
}

# Stop the tool call (PreToolUse) or feed the message back to Claude (other events).
block() {
  echo "BLOCKED: $1" >&2
  exit 2
}
