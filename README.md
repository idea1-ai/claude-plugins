# Idea1 Plugins for Claude Code

[Idea1](https://idea1.ai) project management skills and tools for Claude Code and Claude Cowork.

## Installation

In Claude Code (CLI or Desktop), add the marketplace and install the plugin:

```
/plugin marketplace add idea1-ai/claude-plugins
/plugin install idea1@idea1-plugins
```

In Claude Cowork (Desktop), open the **Customize** panel and add this marketplace by URL:

```
https://github.com/idea1-ai/claude-plugins
```

Then install the **idea1** plugin from it.

## Auto-update

After installing, toggle **"sync automatically"** (Cowork) or enable auto-update for the marketplace in the `/plugin` UI's Marketplaces tab (Claude Code) so future releases roll out without manual action.

## What's included

### idea1 plugin

Skills and an MCP server connection for managing Idea1 projects from within Claude Code.

**Skills:**

- `/idea1:status` — Check the Idea1 plugin connection, verify OAuth authentication, and see which team and project are active.

**MCP server:**

Connects to the Idea1 API at `https://api.idea1.ai/v1/mcp`. Authentication is handled via OAuth — Claude Code will prompt you to authorize on first use.

## Source

This marketplace is built and published from the [omega monorepo](https://github.com/idea1-ai/omega). See `claude-plugins/` in that repo for the build pipeline.
