FROM python:3.11-slim

WORKDIR /app

ENV PYTHONUNBUFFERED=1 \
    AI_MODEL_DIR=/app/models

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
    CMD python -c "import urllib.request, json; res = json.loads(urllib.request.urlopen('http://localhost:5000/health').read().decode()); exit(0 if res.get('data', {}).get('model_ready') else 1)"

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "120", "app:app"]
