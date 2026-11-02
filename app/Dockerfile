# Multi-stage build: dependencies in one stage, a small non-root runtime image in the other
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
# mkdir: the directory must exist for the COPY below, even when there are no dependencies
RUN npm install --omit=dev && mkdir -p node_modules

FROM node:22-alpine
ENV NODE_ENV=production PORT=8080
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY server.js package.json ./
# numeric UID of the built-in "node" user - lets Kubernetes verify runAsNonRoot
USER 1000:1000
EXPOSE 8080
HEALTHCHECK CMD wget -qO- http://localhost:8080/healthz || exit 1
CMD ["node", "server.js"]
