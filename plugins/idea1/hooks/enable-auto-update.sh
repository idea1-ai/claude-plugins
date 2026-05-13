#!/bin/bash
#
# SessionStart hook that flips autoUpdate=true on the plugin's marketplace
# entry in ~/.claude/plugins/known_marketplaces.json, exactly once per
# install. After the first run a marker file in $CLAUDE_PLUGIN_DATA prevents
# the hook from re-enabling autoUpdate if the user later disables it.
#
# Behavior:
#   - Exits silently if the marker file exists, the marketplace name arg is
#     missing, or the known_marketplaces.json file is absent.
#   - Otherwise: finds the entry whose name matches --marketplace-name,
#     sets autoUpdate=true, writes the file, drops the marker, exits.
#   - All errors are swallowed — never block or noise up a session.

set +e

CLAUDE_DIR="$HOME/.claude"
KNOWN_MARKETPLACES_FILE="$CLAUDE_DIR/plugins/known_marketplaces.json"

run() {
    local marketplace_name=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --marketplace-name) marketplace_name="$2"; shift 2 ;;
            --known-marketplaces-file) KNOWN_MARKETPLACES_FILE="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [ -n "$marketplace_name" ] || return 0
    [ -n "$CLAUDE_PLUGIN_DATA" ] || return 0

    local marker_file="$CLAUDE_PLUGIN_DATA/auto-update-enabled.flag"
    [ -f "$marker_file" ] && return 0

    [ -f "$KNOWN_MARKETPLACES_FILE" ] || return 0

    # Without node we can't safely round-trip arbitrary JSON. Bail without
    # dropping the marker so the hook tries again on a later session
    # (in case node becomes available, or the user toggles autoUpdate
    # manually via /plugin and the file gets out of sync).
    command -v node >/dev/null 2>&1 || return 0

    if update_with_node "$KNOWN_MARKETPLACES_FILE" "$marketplace_name"; then
        # Entry was found (and autoUpdate is now true). Drop the marker so
        # we respect any later user toggle.
        mkdir -p "$(dirname "$marker_file")" 2>/dev/null || return 0
        : > "$marker_file" 2>/dev/null || true
    fi
    # No matching marketplace entry: do nothing. The hook will retry next
    # session, which is the right behavior when the user hasn't yet run
    # /plugin marketplace add (e.g., a manually-installed dev zip).
}

# Locates the marketplace entry and sets autoUpdate=true. Handles both
# array and map shapes of known_marketplaces.json; Claude Code's on-disk
# format has varied across versions. Exits 0 if at least one matching
# entry was found (modified or already set), 1 if not found.
update_with_node() {
    local file="$1"
    local marketplace_name="$2"
    node -e '
const fs = require("fs");
const file = process.argv[1];
const name = process.argv[2];
let data;
try { data = JSON.parse(fs.readFileSync(file, "utf8")); }
catch { process.exit(1); }
let found = false;
let changed = false;
const flip = (entry) => {
    if (!entry || typeof entry !== "object") return;
    found = true;
    if (entry.autoUpdate !== true) { entry.autoUpdate = true; changed = true; }
};
if (Array.isArray(data)) {
    for (const e of data) if (e && e.name === name) flip(e);
} else if (data && typeof data === "object") {
    if (Array.isArray(data.marketplaces)) {
        for (const e of data.marketplaces) if (e && e.name === name) flip(e);
    }
    if (data[name]) flip(data[name]);
    if (data.marketplaces && typeof data.marketplaces === "object" && !Array.isArray(data.marketplaces)) {
        if (data.marketplaces[name]) flip(data.marketplaces[name]);
    }
}
if (changed) fs.writeFileSync(file, JSON.stringify(data, null, 2) + "\n");
process.exit(found ? 0 : 1);
' "$file" "$marketplace_name" 2>/dev/null
}

run "$@" 2>/dev/null
exit 0
