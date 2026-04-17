# Makefile for Currency Agent (A2A + ADK + MCP)

# Use uv for running python commands
PYTHON_CMD ?= uv run python

# Environment variables for local development
export GOOGLE_GENAI_USE_VERTEXAI ?= False
export LOG_LEVEL ?= INFO
export GENAI_MODEL ?= gemini-2.5-flash
export MCP_SERVER_URL ?= http://localhost:8080/mcp

.PHONY: help install mcp agent frontend test-client e2e-test adktest test frontend-test lint format clean start stop status deploy logs endpoint remote-status frontend-install frontend-build

help:
	@echo "Available commands:"
	@echo "  install      - Install dependencies using uv"
	@echo "  start        - Start all services in background (MCP + Agent)"
	@echo "  stop         - Stop all background services"
	@echo "  status       - Check status of background services"
	@echo "  mcp          - Start the MCP Server (foreground)"
	@echo "  agent        - Start the A2A Agent Server (foreground)"
	@echo "  frontend     - Build and start the frontend server (port 8000)"
	@echo "  test-client  - Run the A2A Client (test queries)"
	@echo "  e2e-test     - Run end-to-end tests (alias for test-client)"
	@echo "  adktest      - Run interactive ADK CLI for the agent"
	@echo "  test         - Run all tests (pytest)"
	@echo "  frontend-test - Run frontend specific tests"
	@echo "  lint         - Run linting checks (ruff)"
	@echo "  format       - Auto-format code (ruff)"
	@echo "  clean        - Remove caches and logs"
	@echo "  deploy       - Deploy to Cloud Run using Cloud Build"
	@echo "  logs         - Read logs from Cloud Run"
	@echo "  endpoint     - Get the Cloud Run service endpoint"
	@echo "  remote-status - Check the status of the remote endpoint"

install:
	@echo "Installing dependencies..."
	uv sync
	$(MAKE) frontend-install

start:
	@echo "Starting MCP Server in background..."
	@nohup uv run mcp-server/server.py > mcp.log 2>&1 &
	@echo "Waiting for MCP Server to initialize..."
	@sleep 2
	@echo "Starting A2A Agent Server in background..."
	@nohup uv run uvicorn currency_agent.agent:a2a_app --host localhost --port 10000 > agent.log 2>&1 &
	@echo "Services started. Logs: mcp.log, agent.log"

stop:
	@echo "Stopping servers..."
	@pgrep -f "mcp-server/server.py" | grep -v "$$$$" | xargs kill -9 2>/dev/null || true
	@pgrep -f "uvicorn currency_agent.agent:a2a_app" | grep -v "$$$$" | xargs kill -9 2>/dev/null || true
	@pgrep -f "frontend/main.py" | grep -v "$$$$" | xargs kill -9 2>/dev/null || true
	@sleep 1

test:
	@echo "Running tests..."
	-$(MAKE) stop
	$(MAKE) start
	-uv run pytest
	$(MAKE) stop

mcp:
	@echo "Starting MCP Server on port 8080..."
	uv run mcp-server/server.py

agent:
	@echo "Starting A2A Agent Server on port 10000..."
	uv run uvicorn currency_agent.agent:a2a_app --host localhost --port 10000

frontend: frontend-build
	@echo "Starting Frontend Server on port 8000..."
	@PORT=8000 AGENT_SERVER_URL=http://localhost:10000 uv run frontend/main.py

frontend-install:
	@echo "Installing frontend dependencies..."
	cd frontend/frontend && npm install
	uv pip install -r frontend/requirements.txt

frontend-build:
	@echo "Building frontend..."
	cd frontend/frontend && npm run build

frontend-test:
	@echo "Running frontend tests..."
	@PYTHONPATH=frontend uv run pytest frontend/tests

test-client:
	@echo "Running A2A Client tests..."
	uv run currency_agent/test_client.py

e2e-test: test-client

adktest:
	@echo "Starting interactive ADK CLI..."
	@echo "Note: Ensure MCP Server is running (make mcp) if tools are needed."
	uv run adk run currency_agent

lint:
	@echo "Running linting checks (ruff check + format)..."
	uv run ruff check .
	uv run ruff format --check .

format:
	@echo "Auto-formatting code..."
	uv run ruff format .
	uv run ruff check --fix .

clean:
	@echo "Cleaning up caches and temporary files..."
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +
	find . -type d -name ".venv" -exec rm -rf {} +
	find . -type f -name "*.log" -delete
	@echo "Clean completed."

deploy:
	@echo "Deploying to Cloud Run via Cloud Build..."
	gcloud builds submit --config cloudbuild.yaml .

logs:
	@echo "Reading Cloud Run service logs..."
	gcloud run services logs read currency-agent --region us-central1 --limit 5

endpoint:
	@echo "Getting Cloud Run service endpoint..."
	@gcloud run services describe currency-agent --region us-central1 --format "value(status.url)"

remote-status:
	@echo "Checking remote endpoint status..."
	@ENDPOINT=$$(gcloud run services describe currency-agent --region us-central1 --format "value(status.url)"); \
	curl -s -o /dev/null -w "%{http_code}" $$ENDPOINT/health || echo "Failed to connect"
