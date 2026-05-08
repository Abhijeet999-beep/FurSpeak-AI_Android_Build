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

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application (C7 fix: correct module path)
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
