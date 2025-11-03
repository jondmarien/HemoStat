# Multi-stage build for HemoStat Dashboard using UV
# Stage 1: Builder - Install dependencies with UV
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim as builder

WORKDIR /build

# Copy project configuration
COPY pyproject.toml uv.lock* ./

# Copy source code
COPY agents/ ./agents/
COPY dashboard/ ./dashboard/

# Install dependencies with UV (dashboard extra includes streamlit)
RUN uv sync --extra dashboard --no-dev

# Stage 2: Runtime - Minimal image with only runtime dependencies
FROM python:3.11-slim-bookworm

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /build/.venv /app/.venv

# Copy source code
COPY agents/ ./agents/
COPY dashboard/ ./dashboard/

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONPATH=/app \
    PATH=/app/.venv/bin:$PATH

# Expose Streamlit port
EXPOSE 8501

# Create non-root user for security
RUN useradd -m -u 1000 hemostat && \
    chown -R hemostat:hemostat /app

# Switch to non-root user
USER hemostat

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=10s \
    CMD curl -f http://localhost:8501/_stcore/health || exit 1

# Run Streamlit dashboard
ENTRYPOINT ["streamlit", "run", "dashboard/app.py", \
    "--server.port=8501", \
    "--server.address=0.0.0.0", \
    "--server.headless=true", \
    "--server.enableCORS=false", \
    "--server.enableXsrfProtection=false"]
