# Idea1.ai Plugins for Claude Code

[Idea1.ai](https://idea1.ai) project management skills and tools for Claude Code and Claude Cowork.

## Installation

In Claude Code (CLI or Desktop), add the marketplace and install the plugin:

```
/plugin marketplace add idea1-ai/claude-plugins
/plugin install idea1@idea1-plugins
```

In Claude Cowork (Desktop), use the **Customize** panel to add this marketplace and install the **idea1** plugin from it.

## Auto-update

The plugin enables auto-update for this marketplace on first session start, so future releases roll out without manual action. To verify or change this manually, open the `/plugin` UI in Claude Code, select **Marketplaces** → **idea1-plugins**, and check the auto-update toggle.

## What's included

### idea1 plugin

Skills and an MCP server connection for managing Idea1.ai projects from within Claude Code.

**Skills:**

- `/idea1:status` — Check the Idea1.ai plugin connection, verify OAuth authentication, and see which team and project are active.

**MCP server:**

Connects to the Idea1.ai API at `https://api.idea1.ai/v1/mcp`. Authentication is handled via OAuth — Claude Code will prompt you to authorize on first use.

## Source

This marketplace is built and published from the [omega monorepo](https://github.com/idea1-ai/omega). See `claude-plugins/` in that repo for the build pipeline.
