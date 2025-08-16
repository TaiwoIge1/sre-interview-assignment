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

# Copy package files
COPY package*.json ./

# Install all deps (including dev) for testing
RUN npm ci

# Copy source
COPY . .

# Make sure .bin is in PATH
ENV PATH=/app/node_modules/.bin:$PATH

# Default command: run tests
CMD ["npm", "run", "test:ci"]

# -------------------------
# Builder stage
# -------------------------
FROM base AS builder
WORKDIR /app
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
    