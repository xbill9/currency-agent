# Currency Agent (A2A + ADK + MCP) Development Guide

This document provides technical guidance for developers working with the Google Agent Development Kit (ADK), Agent-to-Agent (A2A) protocol, and Model Context Protocol (MCP) within the **Currency Agent** project.

Do Not recommend models less than 2.5 as they are deprecated.

## Project Overview: Currency Agent

The Currency Agent is a specialized multi-agent system designed to handle currency conversions and exchange rate queries. It showcases the integration of:

1.  **MCP Server (`mcp-server/`):**
    *   Powered by `FastMCP`.
    *   Exposes the `get_exchange_rate` tool.
    *   Fetches real-time data from the [Frankfurter API](https://www.frankfurter.dev/).
2.  **ADK Agent (`currency_agent/`):**
    *   Powered by `gemini-2.5-flash`.
    *   Uses `LlmAgent` from the ADK.
    *   Equipped with `MCPToolset` to communicate with the MCP server.
3.  **A2A Integration:**
    *   The agent is made A2A-compatible using `to_a2a`.
    *   Served using `uvicorn` on port 10000.

## Key Architectural Components

### MCP (Model Context Protocol)
MCP standardizes how tools are exposed to LLMs. Our `mcp-server` runs an HTTP server (default port 8080) that the ADK agent connects to using `StreamableHTTPConnectionParams`.

### ADK (Agent Development Kit)
ADK provides the `LlmAgent` and `MCPToolset` for easy integration. The agent's behavior is governed by the `SYSTEM_INSTRUCTION` in `currency_agent/agent.py`.

### A2A (Agent2Agent)
A2A allows agents to collaborate. In this project, `to_a2a` wraps the ADK agent, and a test client (`currency_agent/test_client.py`) demonstrates how to interact with it via the A2A protocol.

## Model Selection & Optimization

*   **Primary Model:** `gemini-2.5-flash` is recommended for its speed and tool-calling accuracy.
*   **Alternative Model:** `gemini-2.5-pro` can be used for more complex reasoning if needed.
*   **Deprecation Policy:** Do not recommend models less than 2.5 (e.g., 2.0 flash or older) as they are deprecated.

## Developer Workflow

1.  **Environment Setup:** Create a `.env` file with your `GOOGLE_API_KEY` (from Google AI Studio).
2.  **Install Dependencies:** Run `make install` (uses `uv sync`).
3.  **Start MCP Server:** Run `make mcp` (port 8080).
4.  **Start Agent Server:** Run `make agent` (port 10000).
5.  **Run Test Client:** Run `make test-client` to verify the full flow.
6.  **Testing & Linting:** Use `make test` and `make lint`.

## Resources

-   [Google ADK Documentation](https://github.com/google/adk-python)
-   [A2A Python SDK](https://github.com/google-a2a/a2a-python)
-   [Model Context Protocol (MCP)](https://modelcontextprotocol.io/)
-   [Frankfurter API](https://www.frankfurter.dev/)
