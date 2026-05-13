---
name: idea1:status
description: Check the status of the Idea1 plugin connection, verify OAuth authentication, and see which team and project are active.
---

# Idea1 Connection Status Check

Use this skill to verify the Idea1 plugin is connected and working correctly.

## Steps

1. Run these two checks in parallel:

   a. **Latest version** — Call `mcp__idea1__get_plugin_versions` to get the latest available plugin version. The result contains a `plugins` object with plugin names as keys and version strings as values (e.g., `plugins.idea1`). This also verifies MCP connectivity and authentication.

   b. **Installed version** — The installed version is: `1.0.1`
      If this still shows a value containing `{{`, the version was not injected at build time — report the installed version as "unknown".

2. After both checks complete, determine connection and version status:

   - If the `get_plugin_versions` call **succeeds**: Connection and authentication are working. Extract the latest version for the "idea1" plugin.
   - If the call **fails with an authentication error**: Server is reachable but the user needs to complete OAuth authorization.
   - If the call **fails with a network error**: Connection failed — the MCP server may be unreachable.

## Report Format

Report results in this format:

```
Idea1 Plugin Status
-------------------
Connection:     [Connected / Failed]
Authentication: [Authenticated / Not authenticated]
MCP Server:     https://api.idea1.ai/v1/mcp
Version:        [installed version][ -> latest version (update available)]
```

For the Version line:
- If installed and latest versions are the **same**, show just the version (e.g., `1.0.0`)
- If they are **different**, show both with an arrow (e.g., `1.0.0 -> 1.1.0 (update available)`)
- If the latest version could **not be fetched**, show only the installed version

If the connection fails, include recovery steps:
- Re-run `/idea1:status` after resolving the issue
- Check that the Idea1 plugin is installed correctly
