# Use the slim variant — smaller image, faster pulls, same Python runtime
FROM python:3.12-slim

# Ensure Python output is unbuffered so kubelet sees logs immediately
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Install dependencies first (Docker layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Run as non-root for security
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

EXPOSE 8080

# Use exec form so SIGTERM reaches Python (important for graceful shutdown)
CMD ["python", "app.py"]
