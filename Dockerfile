# -------------------------
# Base stage: install prod dependencies
# -------------------------
FROM node:22.14.0-alpine AS base

WORKDIR /app

# Copy package.json + package-lock.json
COPY package*.json ./

# Install only production deps for runtime
RUN npm ci --omit=dev

# Copy all source
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

# Run tests by default
CMD ["npm", "run", "test:ci"]

# -------------------------
# Builder stage
# -------------------------
FROM base AS builder

WORKDIR /app

# Copy source (base already has prod deps)
COPY . .

# Build TypeScript
RUN npm run build

# -------------------------
# Production runtime
# -------------------------
FROM node:22.14.0-alpine AS production

WORKDIR /app

# Copy build output
COPY --from=builder /app/dist ./dist

# Copy prod dependencies only
COPY --from=base /app/node_modules ./node_modules

# Use non-root user
USER node

# Run the app
CMD ["node", "dist/index.js"]    