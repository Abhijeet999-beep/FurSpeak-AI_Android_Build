FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (FFmpeg for video, curl for healthcheck, libgomp1 for ML)
RUN apt-get update && apt-get install -y \
    ffmpeg \
    curl \
    libgomp1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code into /app/backend to maintain package structure
COPY . /app/backend

# Create temp directory inside the package or root
RUN mkdir -p /app/backend/temp

# Expose port (Cloud Run defaults to 8080)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the application with gunicorn + uvicorn worker. Cloud Run provides PORT env var.
# Workers restricted to 1 for memory safety in constrained Cloud Run environments.
CMD exec gunicorn backend.main:app --workers 1 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:${PORT:-8080} --timeout 180
