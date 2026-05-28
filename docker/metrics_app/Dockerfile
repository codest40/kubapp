FROM python:3.11-slim

WORKDIR /app

ARG USER=metrics
ARG UID=10009
ARG GID=10009

RUN groupadd -g ${GID} ${USER} \
 && useradd -u ${UID} -g ${USER} -m -s /bin/bash ${USER}

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app

RUN mkdir -p /data \
 && chown -R ${USER}:${USER} /data

USER ${USER}

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
