#!/usr/bin/env bash
# Hook tests. Feeds simulated hook JSON to each hook and checks the exit code.
#
#   bash tests/run.sh
#
# Needs bash, git and jq. Every test uses throwaway git repos in a temp folder,
# so it never touches your own repos, branches or files.
#
# Fixtures: tests/fixtures/ifeelfine.json is the config the fake repos use. It
# protects "docs/diagrams/*.png" and "private.csv" so the config-driven path of
# guard-paths gets exercised.

# shellcheck disable=SC2016  # single quotes keep test commands literal on purpose
set -u
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$TESTS_DIR/.." && pwd)"
CORE="$ROOT/plugins/core/hooks"
DOTNET="$ROOT/plugins/dotnet-angular/hooks"
FIXTURE_CONFIG="$TESTS_DIR/fixtures/ifeelfine.json"
pass=0
fail=0
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

if ! command -v jq >/dev/null 2>&1; then
  echo "tests need jq to build their input. Install jq and run again." >&2
  exit 1
fi

# --- helpers ---------------------------------------------------------------

make_repo() { # $1 = branch, $2 = "noconfig" to skip the fixture config
  local dir
  dir="$(mktemp -d "$scratch/repo.XXXXXX")"
  git -C "$dir" init -q -b "$1"
  git -C "$dir" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
  if [[ "${2:-}" != "noconfig" ]]; then
    mkdir -p "$dir/.claude"
    cp "$FIXTURE_CONFIG" "$dir/.claude/ifeelfine.json"
  fi
  echo "$dir"
}

ok() {
  pass=$((pass + 1))
  echo "PASS  $1"
}

bad() {
  fail=$((fail + 1))
  echo "FAIL  $1"
}

# expect <label> <want exit> <hooks dir> <hook> <project dir> <json> [hook args...]
expect() {
  local label="$1" want="$2" hooks="$3" hook="$4" dir="$5" json="$6" got
  shift 6
  CLAUDE_PROJECT_DIR="$dir" "$BASH" "$hooks/$hook" "$@" <<<"$json" >/dev/null 2>&1
  got=$?
  if [[ "$got" == "$want" ]]; then ok "$label (exit $got)"; else bad "$label (wanted $want, got $got)"; fi
}

# Git Bash on Windows rewrites arguments that look like paths (a leading "//" becomes "/")
# before they reach native programs such as jq. Turn that off for the jq calls that build
# test input, so the input stays literal.
build_json() { MSYS2_ARG_CONV_EXCL='*' jq "$@"; }

bash_json() { build_json -cn --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }
edit_json() { build_json -cn --arg p "$1" '{tool_name:"Edit",tool_input:{file_path:$p}}'; }
write_json() { build_json -cn --arg p "$1" --arg c "$2" '{tool_name:"Write",tool_input:{file_path:$p,content:$c}}'; }
patch_json() { build_json -cn --arg p "$1" --arg o "$2" --arg n "$3" '{tool_name:"Edit",tool_input:{file_path:$p,old_string:$o,new_string:$n}}'; }

# Build a PATH value that holds the basic tools but not the ones named in $1 (space separated).
# Prints the PATH, or nothing when this machine cannot build one. First try a folder of links
# to the basic tools. Where links do not work (Git Bash on Windows), fall back to the system
# folders, which hold no jq or dotnet, and add the jq folder back unless jq is excluded.
make_stub_path() {
  local exclude=" $1 " tool src stub candidate jq_path git_path
  stub="$(mktemp -d "$scratch/path.XXXXXX")"
  for tool in bash git grep sed tr cat dirname basename find head tail mktemp uname rm mkdir sort printf date timeout cut jq; do
    [[ "$exclude" == *" $tool "* ]] && continue
    src="$(command -v "$tool" 2>/dev/null)" || continue
    ln -s "$src" "$stub/$tool" 2>/dev/null || true
  done
  jq_path="$(dirname "$(command -v jq)")"
  git_path="$(dirname "$(command -v git)")"
  for candidate in "$stub" "/usr/bin:/bin:$git_path" "/usr/bin:/bin:$git_path:$jq_path"; do
    [[ "$exclude" != *" jq "* && "$candidate" != "$stub" && "$candidate" != *"$jq_path"* ]] && continue
    usable "$candidate" "$exclude" && { echo "$candidate"; return 0; }
  done
  return 0
}

# A PATH is usable when the basic tools run and every excluded tool is absent.
usable() {
  local candidate="$1" exclude="$2" tool
  PATH="$candidate" "$BASH" -c 'git --version >/dev/null && grep -q a <<<a && echo x | tr x y >/dev/null && command -v bash >/dev/null' 2>/dev/null || return 1
  for tool in $exclude; do
    PATH="$candidate" command -v "$tool" >/dev/null 2>&1 && return 1
  done
  return 0
}

# expect_silent <label> <hooks dir> <hook> <project dir> <json> <path> [hook args...]
# Runs the hook with a custom PATH and wants exit 0 and no output at all.
expect_silent() {
  local label="$1" hooks="$2" hook="$3" dir="$4" json="$5" path="$6" out
  shift 6
  out="$(CLAUDE_PROJECT_DIR="$dir" PATH="$path" "$BASH" "$hooks/$hook" "$@" <<<"$json" 2>&1)"
  if [[ $? -eq 0 && -z "$out" ]]; then ok "$label"; else bad "$label (exit or output: $out)"; fi
}

main_repo="$(make_repo main)"
feat_repo="$(make_repo chore/test)"

# --- guard-main ------------------------------------------------------------

echo "== guard-main =="
g() { expect "$1" "$2" "$CORE" guard-main.sh "$3" "$(bash_json "$4")"; }
g "commit on main"                   2 "$main_repo" 'git commit -m x'
g "commit on feature branch"         0 "$feat_repo" 'git commit -m x'
g "checkout -b then commit"          0 "$main_repo" 'git checkout -b feat && git commit -m x'
g "add && commit on main"            2 "$main_repo" 'git add . && git commit -m x'
g "push origin main"                 2 "$feat_repo" 'git push origin main'
g "push HEAD:main"                   2 "$feat_repo" 'git push origin HEAD:main'
g "bare push on main"                2 "$main_repo" 'git push'
g "push feature branch"              0 "$feat_repo" 'git push -u origin chore/test'
g "force push --force"               2 "$feat_repo" 'git push --force origin chore/test'
g "force push -f"                    2 "$feat_repo" 'git push -f origin chore/test'
g "force push with lease"            2 "$feat_repo" 'git push --force-with-lease'
g "force push +refspec"              2 "$feat_repo" 'git push origin +chore/test'
g "push --all"                       2 "$feat_repo" 'git push origin --all'
g "push --delete"                    2 "$feat_repo" 'git push origin --delete chore/test'
g "push with variable expansion"     2 "$feat_repo" 'b=main; git push origin $b'
g "push with brace expansion"        2 "$feat_repo" 'git push origin {main,x}'
g "push with escaped branch name"    2 "$feat_repo" 'git push origin ma\in'
g "push with glob"                   2 "$feat_repo" 'git push origin ma?n'
g "rm -rf is not a force-push"       0 "$feat_repo" 'rm -rf obj && git push origin chore/test'
g "quoted push to main"              2 "$feat_repo" 'git push origin "main"'
g "git -C push to main"              2 "$feat_repo" 'git -C . push origin main'
g "commit then checkout -b"          2 "$main_repo" 'git commit -m x && git checkout -b feat'
g "switch back to main then commit"  2 "$feat_repo" 'git switch main && git commit -m x'
g "git -C commit on main"            2 "$main_repo" 'git -C . commit -m x'
g "non-git command"                  0 "$main_repo" 'ls -la'
g "git status on main"               0 "$main_repo" 'git status'
expect "empty input"                 0 "$CORE" guard-main.sh "$main_repo" ''
expect "no config file needed"       2 "$CORE" guard-main.sh "$(make_repo main noconfig)" "$(bash_json 'git commit -m x')"

# --- guard-paths -----------------------------------------------------------

echo "== guard-paths =="
for p in \
  "src/App.Web/node_modules/x/index.js" \
  "src/App.Api/bin/Debug/a.dll" \
  "src/App.Api/obj/project.assets.json" \
  "src/App.Web/coverage/index.html" \
  "coverage-report/Summary.txt" \
  "src/App.Web/package-lock.json" \
  "src/App.Api/Migrations/20260101_X.Designer.cs" \
  "docs/diagrams/context.png" \
  "src/App.Tools/data/private.csv" \
  "private.csv"; do
  expect "blocks $p" 2 "$DOTNET" guard-paths.sh "$feat_repo" "$(edit_json "$feat_repo/$p")"
done
expect "allows API source"     0 "$DOTNET" guard-paths.sh "$feat_repo" "$(edit_json "$feat_repo/src/App.Api/Program.cs")"
expect "allows migration .cs"  0 "$DOTNET" guard-paths.sh "$feat_repo" "$(edit_json "$feat_repo/src/App.Api/Migrations/20260101_X.cs")"
expect "allows diagram source" 0 "$DOTNET" guard-paths.sh "$feat_repo" "$(edit_json "$feat_repo/docs/diagrams/context.puml")"
expect "odd casing is still blocked" 2 "$DOTNET" guard-paths.sh "$feat_repo" "$(edit_json "$feat_repo/src/App.Web/NODE_MODULES/x.js")"
expect "backslash path is blocked" 2 "$DOTNET" guard-paths.sh "$feat_repo" "$(edit_json "$feat_repo\\src\\App.Web\\node_modules\\x.js")"
expect "relative path is blocked" 2 "$DOTNET" guard-paths.sh "$feat_repo" "$(edit_json "src/App.Web/node_modules/x.js")"
noconf="$(make_repo chore/test noconfig)"
expect "no config: built-in rule still blocks" 2 "$DOTNET" guard-paths.sh "$noconf" "$(edit_json "$noconf/src/App.Api/obj/a.json")"
expect "no config: config-only path is allowed" 0 "$DOTNET" guard-paths.sh "$noconf" "$(edit_json "$noconf/docs/diagrams/context.png")"
badconf="$(make_repo chore/test)"
printf '{ not json' > "$badconf/.claude/ifeelfine.json"
expect "malformed config: built-in rule still blocks" 2 "$DOTNET" guard-paths.sh "$badconf" "$(edit_json "$badconf/src/App.Api/obj/a.json")"
expect "malformed config: ordinary file is allowed" 0 "$DOTNET" guard-paths.sh "$badconf" "$(edit_json "$badconf/src/App.Api/Program.cs")"
oddconf="$(make_repo chore/test)"
printf '{"protectedPaths":"nope"}' > "$oddconf/.claude/ifeelfine.json"
expect "wrong-type protectedPaths is ignored" 0 "$DOTNET" guard-paths.sh "$oddconf" "$(edit_json "$oddconf/src/App.Api/Program.cs")"

# --- guard-destructive-migration -------------------------------------------

echo "== guard-destructive-migration =="
mig="$feat_repo/src/App.Api/Migrations/20260101_Drop.cs"
gm() { expect "$1" "$2" "$DOTNET" guard-destructive-migration.sh "$feat_repo" "$3"; }
gm "Write DropTable no ack"           2 "$(write_json "$mig" 'migrationBuilder.DropTable(name: "A");')"
gm "Write DropColumn no ack"          2 "$(write_json "$mig" 'migrationBuilder.DropColumn(name: "A");')"
gm "Write DropTable with ack"         0 "$(write_json "$mig" $'// DESTRUCTIVE-ACK: table unused since v2\nmigrationBuilder.DropTable(name: "A");')"
gm "Write DropTable empty reason"     2 "$(write_json "$mig" $'// DESTRUCTIVE-ACK:\nmigrationBuilder.DropTable(name: "A");')"
gm "Write raw SQL DROP TABLE"         2 "$(write_json "$mig" 'migrationBuilder.Sql("drop table x");')"
gm "Write raw SQL TRUNCATE"           2 "$(write_json "$mig" 'migrationBuilder.Sql("TRUNCATE x");')"
gm "Write DropSchema"                 2 "$(write_json "$mig" 'migrationBuilder.DropSchema(name: "s");')"
gm "Write ack inside a string is not an ack" 2 "$(write_json "$mig" 'var s = "// DESTRUCTIVE-ACK: x"; migrationBuilder.DropTable(name: "A");')"
gm "Write AddColumn"                  0 "$(write_json "$mig" 'migrationBuilder.AddColumn<int>(name: "A");')"
gm "Write non-migration"              0 "$(write_json "$feat_repo/src/X.cs" 'DropTable')"
gm "Write Designer skipped"           0 "$(write_json "$feat_repo/src/App.Api/Migrations/20260101_Drop.Designer.cs" 'DropTable')"
gm "Edit with odd path casing"        2 "$(write_json "$feat_repo/src/App.Api/MIGRATIONS/20260101_Drop.CS" 'DropTable')"
mkdir -p "$feat_repo/src/App.Api/Migrations"
printf 'migrationBuilder.DropColumn(name: "A");\n' > "$mig"
expect "scan new file no ack"         2 "$DOTNET" guard-destructive-migration.sh "$feat_repo" "$(bash_json 'dotnet ef migrations add Drop')" scan
printf '// DESTRUCTIVE-ACK: reason\nmigrationBuilder.DropColumn(name: "A");\n' > "$mig"
expect "scan new file with ack"       0 "$DOTNET" guard-destructive-migration.sh "$feat_repo" "$(bash_json 'dotnet ef migrations add Drop')" scan
printf 'migrationBuilder.DropColumn(name: "A");\n' > "$mig"
expect "scan ignores other commands"  0 "$DOTNET" guard-destructive-migration.sh "$feat_repo" "$(bash_json 'ls')" scan
printf 'migrationBuilder.AddColumn<int>(name: "A");\n' > "$mig"
gm "Edit introduces DropColumn"       2 "$(patch_json "$mig" 'AddColumn<int>' 'DropColumn')"
printf '// DESTRUCTIVE-ACK: reason\nmigrationBuilder.AddColumn<int>(name: "A");\n' > "$mig"
gm "Edit DropColumn with ack elsewhere" 0 "$(patch_json "$mig" 'AddColumn<int>' 'DropColumn')"
printf 'migrationBuilder.DropColumn(name: "A");\n' > "$mig"
gm "Edit removing the drop"           0 "$(patch_json "$mig" 'DropColumn' 'AddColumn<int>')"
gm "Edit that does not apply fails closed" 2 "$(patch_json "$mig" 'NotInFile' 'migrationBuilder.DropTable(name: 1);')"
printf 'a\r\nmigrationBuilder.AddColumn<int>(name: "A");\r\n' > "$mig"
gm "Edit on a CRLF file applies cleanly" 0 "$(patch_json "$mig" 'AddColumn<int>' 'AddColumn<long>')"
rm -f "$mig"

# --- session-start ---------------------------------------------------------

echo "== session-start =="
expect "exits 0 with jq" 0 "$CORE" session-start.sh "$feat_repo" '{}'
out="$(CLAUDE_PROJECT_DIR="$feat_repo" "$BASH" "$CORE/session-start.sh" <<<'{}' 2>&1)"
if [[ -z "$out" ]]; then ok "silent when jq exists"; else bad "silent when jq exists (got: $out)"; fi

# --- stop-verify -----------------------------------------------------------

echo "== stop-verify =="
expect "stop_hook_active skips"  0 "$DOTNET" stop-verify.sh "$feat_repo" '{"stop_hook_active":true}'
expect "no .cs changes skips"    0 "$DOTNET" stop-verify.sh "$feat_repo" '{"stop_hook_active":false}'

fake_dotnet="$(mktemp -d "$scratch/dotnet.XXXXXX")"
record="$scratch/dotnet-args.txt"
printf '#!/usr/bin/env bash\necho "$@" > "%s"\necho "Program.cs(1,1): error CS1002: ; expected"\nexit 1\n' "$record" > "$fake_dotnet/dotnet"
chmod +x "$fake_dotnet/dotnet"
echo "class A {}" > "$feat_repo/A.cs"
echo "<Project/>" > "$feat_repo/App.slnx"

got="$(PATH="$fake_dotnet:$PATH" CLAUDE_PROJECT_DIR="$feat_repo" "$BASH" "$DOTNET/stop-verify.sh" <<<'{"stop_hook_active":false}' 2>&1 >/dev/null; echo "exit=$?")"
if grep -q "BUILD FAILED" <<<"$got" && grep -q "exit=2" <<<"$got"; then ok "changed .cs + failing build exits 2 with errors"; else bad "failing build: $got"; fi
got="$(PATH="$fake_dotnet:$PATH" CLAUDE_PROJECT_DIR="$feat_repo" "$BASH" "$DOTNET/stop-verify.sh" <<<'{"stop_hook_active":true}' 2>&1 >/dev/null; echo "exit=$?")"
if grep -q "exit=0" <<<"$got"; then ok "stop_hook_active=true skips a failing build"; else bad "loop guard: $got"; fi

printf '#!/usr/bin/env bash\necho "$@" > "%s"\nexit 0\n' "$record" > "$fake_dotnet/dotnet"
PATH="$fake_dotnet:$PATH" expect "changed .cs + passing build" 0 "$DOTNET" stop-verify.sh "$feat_repo" '{"stop_hook_active":false}'
if grep -q "App.slnx" "$record"; then ok "auto-discovers the solution file"; else bad "auto-discovery: $(cat "$record")"; fi

rm -f "$feat_repo/App.slnx"
mkdir -p "$feat_repo/src/App"
echo "<Project/>" > "$feat_repo/src/App/App.csproj"
PATH="$fake_dotnet:$PATH" expect "falls back to a .csproj" 0 "$DOTNET" stop-verify.sh "$feat_repo" '{"stop_hook_active":false}'
if grep -q "App.csproj" "$record"; then ok "builds the discovered .csproj"; else bad "csproj discovery: $(cat "$record")"; fi

echo "<Project/>" > "$feat_repo/Other.sln"
printf '{"solution":"Other.sln"}' > "$feat_repo/.claude/ifeelfine.json"
PATH="$fake_dotnet:$PATH" expect "configured solution" 0 "$DOTNET" stop-verify.sh "$feat_repo" '{"stop_hook_active":false}'
if grep -q "Other.sln" "$record"; then ok "builds the configured solution"; else bad "configured solution: $(cat "$record")"; fi

printf '{"solution":"Missing.sln"}' > "$feat_repo/.claude/ifeelfine.json"
rm -f "$record"
PATH="$fake_dotnet:$PATH" expect "configured solution that does not exist is skipped" 0 "$DOTNET" stop-verify.sh "$feat_repo" '{"stop_hook_active":false}'
if [[ ! -f "$record" ]]; then ok "does not build a missing solution"; else bad "built a missing solution"; fi

echo "<Project/>" > "$feat_repo/Mig.slnx"
printf '{"solution":"Mig.slnx"}' > "$feat_repo/.claude/ifeelfine.json"
mkdir -p "$feat_repo/src/App.Api/Migrations"
printf 'migrationBuilder.DropTable(name: "A");\n' > "$feat_repo/src/App.Api/Migrations/20260101_Drop.cs"
PATH="$fake_dotnet:$PATH" expect "unacknowledged destructive migration blocks the stop" 2 "$DOTNET" stop-verify.sh "$feat_repo" '{"stop_hook_active":false}'
rm -rf "$feat_repo/src/App.Api" "$feat_repo/A.cs" "$feat_repo/Other.sln" "$feat_repo/Mig.slnx" "$feat_repo/src/App"
cp "$FIXTURE_CONFIG" "$feat_repo/.claude/ifeelfine.json"

# --- format-on-edit --------------------------------------------------------

echo "== format-on-edit =="
expect "missing file is ignored" 0 "$DOTNET" format-on-edit.sh "$feat_repo" "$(write_json "$feat_repo/none.cs" '')"
expect "unrelated file ignored"  0 "$DOTNET" format-on-edit.sh "$feat_repo" "$(write_json "$feat_repo/README.md" '')"
mkdir -p "$feat_repo/src/App"
echo "class B {}" > "$feat_repo/src/App/B.cs"
echo "<Project/>" > "$feat_repo/src/App/App.csproj"
printf '#!/usr/bin/env bash\necho "$@" > "%s"\nexit 0\n' "$record" > "$fake_dotnet/dotnet"
rm -f "$record"
PATH="$fake_dotnet:$PATH" expect "formats a .cs file" 0 "$DOTNET" format-on-edit.sh "$feat_repo" "$(write_json "$feat_repo/src/App/B.cs" '')"
if grep -q "src/App" "$record" && grep -q -- "--include src/App/B.cs" "$record"; then ok "dotnet format targets the owning project and file"; else bad "dotnet format args: $(cat "$record" 2>/dev/null)"; fi
mkdir -p "$feat_repo/src/App/Migrations"
echo "class M {}" > "$feat_repo/src/App/Migrations/M.cs"
rm -f "$record"
PATH="$fake_dotnet:$PATH" expect "skips migrations" 0 "$DOTNET" format-on-edit.sh "$feat_repo" "$(write_json "$feat_repo/src/App/Migrations/M.cs" '')"
if [[ ! -f "$record" ]]; then ok "migration files are not formatted"; else bad "formatted a migration"; fi
mkdir -p "$feat_repo/web/node_modules/.bin" "$feat_repo/web/src"
echo "{}" > "$feat_repo/web/package.json"
echo "const a = 1" > "$feat_repo/web/src/a.ts"
printf '#!/usr/bin/env bash\necho "$@" > "%s"\n' "$record" > "$feat_repo/web/node_modules/.bin/prettier"
chmod +x "$feat_repo/web/node_modules/.bin/prettier"
rm -f "$record"
expect "formats a web file" 0 "$DOTNET" format-on-edit.sh "$feat_repo" "$(write_json "$feat_repo/web/src/a.ts" '')"
if grep -q -- "--write src/a.ts" "$record" 2>/dev/null; then ok "prettier runs from the folder that holds package.json"; else bad "prettier args: $(cat "$record" 2>/dev/null)"; fi
printf '{"webDir":"other"}' > "$feat_repo/.claude/ifeelfine.json"
rm -f "$record"
expect "webDir config excludes files outside it" 0 "$DOTNET" format-on-edit.sh "$feat_repo" "$(write_json "$feat_repo/web/src/a.ts" '')"
if [[ ! -f "$record" ]]; then ok "file outside webDir is not formatted"; else bad "formatted outside webDir"; fi
cp "$FIXTURE_CONFIG" "$feat_repo/.claude/ifeelfine.json"

# --- missing tools ---------------------------------------------------------

echo "== missing tools =="
nojq="$(make_stub_path jq)"
if [[ -n "$nojq" ]]; then
  expect_silent "guard-main without jq"          "$CORE"   guard-main.sh      "$main_repo" "$(bash_json 'git commit -m x')" "$nojq"
  expect_silent "guard-paths without jq"         "$DOTNET" guard-paths.sh     "$feat_repo" "$(edit_json "$feat_repo/obj/a")" "$nojq"
  expect_silent "guard-destructive without jq"   "$DOTNET" guard-destructive-migration.sh "$feat_repo" "$(write_json "$feat_repo/Migrations/a.cs" 'DropTable')" "$nojq"
  expect_silent "guard-destructive scan without jq" "$DOTNET" guard-destructive-migration.sh "$feat_repo" "$(bash_json 'dotnet ef migrations add X')" "$nojq" scan
  expect_silent "format-on-edit without jq"      "$DOTNET" format-on-edit.sh  "$feat_repo" "$(write_json "$feat_repo/a.cs" '')" "$nojq"
  expect_silent "stop-verify without jq"         "$DOTNET" stop-verify.sh     "$feat_repo" '{"stop_hook_active":false}' "$nojq"
  out="$(CLAUDE_PROJECT_DIR="$feat_repo" PATH="$nojq" "$BASH" "$CORE/session-start.sh" <<<'{}' 2>&1)"
  if [[ $? -eq 0 && "$out" == *"jq is not installed"* ]]; then ok "session-start explains the missing jq and exits 0"; else bad "session-start without jq: $out"; fi
else
  echo "SKIP  missing-jq tests: this machine cannot build a PATH without jq"
fi

nodotnet="$(make_stub_path dotnet)"
if [[ -n "$nodotnet" ]]; then
  echo "class C {}" > "$feat_repo/C.cs"
  echo "<Project/>" > "$feat_repo/C.slnx"
  expect_silent "stop-verify without dotnet"     "$DOTNET" stop-verify.sh     "$feat_repo" '{"stop_hook_active":false}' "$nodotnet"
  mkdir -p "$feat_repo/proj"
  echo "<Project/>" > "$feat_repo/proj/proj.csproj"
  echo "class D {}" > "$feat_repo/proj/D.cs"
  expect_silent "format-on-edit without dotnet"  "$DOTNET" format-on-edit.sh  "$feat_repo" "$(write_json "$feat_repo/proj/D.cs" '')" "$nodotnet"
  rm -rf "$feat_repo/C.cs" "$feat_repo/C.slnx" "$feat_repo/proj"
else
  echo "SKIP  missing-dotnet tests: this machine cannot build a PATH without dotnet"
fi

nonode="$(make_stub_path node)"
if [[ -n "$nonode" ]]; then
  expect_silent "format-on-edit web file without node or prettier" "$DOTNET" format-on-edit.sh "$feat_repo" "$(write_json "$feat_repo/web/src/a.ts" '')" "$nonode"
fi

echo
echo "passed=$pass failed=$fail"
[[ $fail -eq 0 ]]
