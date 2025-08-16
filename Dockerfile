# -------------------------
# Base stage: install prod dependencies
# -------------------------
FROM node:22.14.0-alpine AS base
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .

# -------------------------
# Tester stage: install devDependencies
# -------------------------
FROM node:22.14.0-alpine AS tester
WORKDIR /app
COPY package*.json ./
# Install all dependencies (including dev) for testing
RUN npm ci
COPY . .
ENV PATH=/app/node_modules/.bin:$PATH
CMD ["npm", "run", "test:ci"]

# -------------------------
# Builder stage: install all dependencies for building
# -------------------------
FROM node:22.14.0-alpine AS builder
WORKDIR /app
COPY package*.json ./
# Install all deps including devDependencies temporarily for build
RUN npm ci
COPY . .
RUN npm run build

# -------------------------
# Production runtime
# -------------------------
FROM node:22.14.0-alpine AS production
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=base /app/node_modules ./node_modules
USER node
CMD ["node", "dist/index.js"]
    