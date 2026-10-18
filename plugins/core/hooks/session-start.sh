#!/usr/bin/env bash
# SessionStart: tell the user when the hooks cannot work on this machine.
#
# Enforces: nothing. It only reports. Every hook in these plugins needs jq to
# read Claude Code's JSON input and quietly does nothing without it. That is the
# right default for a session, but a silent guard is easy to mistake for a working
# one, so this hook prints one line when jq is missing.
#
# Why: learners should know their guardrails are off. It always exits 0.

if ! command -v jq >/dev/null 2>&1; then
  echo "i-feel-fine: jq is not installed, so the guard hooks are inactive. Install jq to turn them on."
fi
exit 0
