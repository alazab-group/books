FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    default-mysql-client \
    postgresql-client \
    nodejs \
    npm \
    libmagic1 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    fonts-liberation \
    fonts-noto-cjk \
    wkhtmltopdf \
    libssl-dev \
    libffi-dev \
    git \
    supervisor \
    libjpeg-dev \
    libpng-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash books

WORKDIR /home/books

COPY requirements.txt package.json ./

RUN pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt

RUN npm install -g yarn && npm install

COPY . .

RUN chown -R books:books /home/books

USER books

RUN npm run production

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/api/method/ping')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "--timeout", "120", "--worker-class", "gthread", "--threads", "4", "books.app:application"]
