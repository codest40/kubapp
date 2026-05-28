FROM node:18-alpine

WORKDIR /app

COPY package.json .
RUN npm install --omit=dev

COPY app.js .

ARG SERVICE_NAME=admin_app
ARG UID=10003
ARG GID=10003

RUN addgroup -g ${GID} -S ${SERVICE_NAME} && \
    adduser -S -D -H -u ${UID} -G ${SERVICE_NAME} ${SERVICE_NAME} && \
    mkdir -p /data && \
    chown -R ${SERVICE_NAME}:${SERVICE_NAME} /app /data

USER ${SERVICE_NAME}

EXPOSE 4000

CMD ["node", "app.js"]
