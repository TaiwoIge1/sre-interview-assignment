# -------------------------
# Base stage: install prod dependencies
# -------------------------
FROM node:22.14.0-alpine AS base
WORKDIR /app

# Copy only package.json + package-lock.json for caching
COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# Copy full source
COPY . .

# -------------------------
# Test stage: install all deps including dev
# -------------------------
FROM node:22.14.0-alpine AS tester
WORKDIR /app

COPY package*.json ./
RUN npm ci   # install all dependencies including dev
COPY . .

# Run tests
CMD ["npm", "run", "test:ci"]

# -------------------------
# Build stage
# -------------------------
FROM base AS builder
WORKDIR /app

# Build the app
RUN npm run build

# -------------------------
# Production stage
# -------------------------
FROM node:22.14.0-alpine AS production
WORKDIR /app

# Copy build output and prod deps
COPY --from=builder /app/dist ./dist
COPY --from=base /app/node_modules ./node_modules

# Use non-root user
USER node

CMD ["node", "dist/index.js"]
    