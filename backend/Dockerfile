FROM python:3.10-slim

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    HOST=0.0.0.0 \
    PIP_DEFAULT_TIMEOUT=300 \
    PIP_RETRIES=10

# Set working directory
WORKDIR /app

# Install necessary system build tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --no-cache-dir --upgrade pip

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install \
    --no-cache-dir \
    --default-timeout=300 \
    --retries=10 \
    -r requirements.txt

# Copy the rest of the application code
COPY . .

# Ensure upload directories exist
RUN mkdir -p uploadvoices uploadimages

# Expose port
EXPOSE 8000

# Command to run application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
