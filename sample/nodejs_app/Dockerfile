FROM node:20-alpine

WORKDIR /app

COPY package.json ./
RUN npm install

COPY . .

ARG SERVICE_NAME=nodejs_app
RUN addgroup -S ${SERVICE_NAME} && \
    adduser -S ${SERVICE_NAME} -G ${SERVICE_NAME}
USER ${SERVICE_NAME}

EXPOSE 3000

CMD ["npm", "start"]
