# Tests

```
bash tests/run.sh
```

Needs bash, git and jq. Each test feeds simulated hook JSON to a hook inside a throwaway git repo and checks the exit code. Fixtures live in `tests/fixtures/`.

The suite covers every blocking and allowing case for each hook, odd path casing, push expansion tricks, a missing config file, malformed config, and missing `jq`, `dotnet` and `node`.

CI runs shellcheck, the tests on Linux and macOS, JSON syntax checks, and a check that the two `lib.sh` copies match.

## Adding a hook

1. Write the script with a header comment: what it enforces and why.
2. Source `lib.sh`, call `need_tool` for each tool it needs, then `read_input`.
3. Register it in `hooks.json`.
4. Add allow and block cases, and a missing-tool case, to `tests/run.sh`.
5. Run shellcheck and the tests.
