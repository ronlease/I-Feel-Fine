#!/usr/bin/env bash
# PostToolUse (Edit|Write): format the file Claude just wrote.
#
# Enforces: formatting stays consistent without you asking.
#   .cs                  -> dotnet format, limited to that file, in its owning project
#                           (the nearest folder above it that holds a .csproj)
#   .ts .html .scss      -> the project's own prettier, inside the web folder
# Migrations are skipped. Formatting problems never block an edit: this hook always exits 0.
#
# Why: formatting is a tool's job. Running it right after each edit keeps diffs clean
# and spares Claude from spending turns on style.
#
# Config (.claude/ifeelfine.json), optional:
#   "webDir": "src/Web"   Folder with package.json and node_modules. Default: the nearest
#                         folder above the file that holds a package.json.
#
# Needs jq. dotnet formatting needs dotnet. Web formatting needs node and a local
# node_modules/.bin/prettier. Anything missing means the hook exits 0 and does nothing.

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
need_tool jq
read_input

file_path="$(json_get tool_input.file_path)"
[[ -z "$file_path" ]] && exit 0
rel="$(normalize_path "$file_path")"
[[ -f "$PROJECT_DIR/$rel" ]] || exit 0

# Print the nearest ancestor folder (relative to the project) that contains a file
# matching $2, starting at the folder of $1. Prints nothing when none exists.
nearest_dir_with() {
  local dir
  dir="$(dirname "$1")"
  while [[ "$dir" != "." && "$dir" != "/" && -n "$dir" ]]; do
    if compgen -G "$PROJECT_DIR/$dir/$2" >/dev/null; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 0
}

case "$rel" in
  *.cs)
    case "$(lower "$rel")" in
      */migrations/*) exit 0 ;;
    esac
    need_tool dotnet
    project="$(nearest_dir_with "$rel" '*.csproj')"
    [[ -z "$project" ]] && exit 0
    (cd "$PROJECT_DIR" && dotnet format "$project" --no-restore --include "$rel" --verbosity quiet) >&2 || true
    ;;
  *.ts | *.html | *.scss)
    case "$rel" in
      */node_modules/* | node_modules/*) exit 0 ;;
    esac
    need_tool node
    web_dir="$(cfg_get webDir "")"
    web_dir="${web_dir%/}"
    if [[ -n "$web_dir" ]]; then
      [[ "$rel" == "$web_dir"/* ]] || exit 0
    else
      web_dir="$(nearest_dir_with "$rel" 'package.json')"
      [[ -z "$web_dir" ]] && exit 0
    fi
    prettier="$PROJECT_DIR/$web_dir/node_modules/.bin/prettier"
    [[ -x "$prettier" ]] || exit 0
    (cd "$PROJECT_DIR/$web_dir" && "$prettier" --write "${rel#"$web_dir"/}") >&2 || true
    ;;
esac

exit 0
