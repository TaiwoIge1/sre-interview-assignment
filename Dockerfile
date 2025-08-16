# -------------------------
# Base deps stage
# -------------------------
    FROM node:22.14.0-alpine AS base
    WORKDIR /app
    
    # Copy package.json + lockfile
    COPY package*.json ./
    
    # Install all deps (cache-friendly)
    RUN npm ci
    
    # Copy source
    COPY . .
    
    # -------------------------
    # Test stage
    # -------------------------
    FROM base AS tester
    # Run tests in CI mode
    CMD ["npm", "run", "test:ci"]
    
    # -------------------------
    # Build stage
    # -------------------------
    FROM base AS builder
    RUN npm run build
    
    # -------------------------
    # Production runtime
    # -------------------------
    FROM node:22.14.0-alpine AS production
    WORKDIR /app
    
    # Copy build artifacts & runtime deps
    COPY --from=builder /app/dist ./dist
    COPY --from=base /app/node_modules ./node_modules
    COPY --from=base /app/package*.json ./
    
    USER node
    CMD ["node", "dist/index.js"]
    