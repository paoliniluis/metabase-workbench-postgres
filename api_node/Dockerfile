FROM node:18-alpine

WORKDIR /app

COPY package.json server.js db.js ./
RUN npm install

EXPOSE 3000

CMD ["npm", "start"]