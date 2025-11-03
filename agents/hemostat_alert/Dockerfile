# Stage 1: Builder
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

WORKDIR /build

# Copy project files
COPY pyproject.toml uv.lock* ./
COPY agents/ ./agents/

# Install dependencies
RUN uv sync --extra agents --no-dev

# Stage 2: Runtime
FROM python:3.11-slim-bookworm

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /build/.venv /app/.venv

# Copy agents code
COPY agents/ /app/agents/

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONPATH=/app
ENV PATH=/app/.venv/bin:$PATH

# Create non-root user
RUN useradd -m -u 1000 hemostat && \
    chown -R hemostat:hemostat /app

USER hemostat

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD python -c "import redis; redis.Redis(host='redis').ping()" || exit 1

# Entrypoint
ENTRYPOINT ["python", "-m", "agents.hemostat_alert.main"]
