# -------------------------
# Base stage: install dependencies
# -------------------------
    FROM node:22.14.0-alpine AS base

    # Set working directory
    WORKDIR /app
    
    # Copy only package.json + package-lock.json first for caching
    COPY package*.json ./
    
    # Install all dependencies
    RUN npm ci
    
    # Copy the rest of the source
    COPY . .
    
    # -------------------------
    # Test stage
    # -------------------------
    FROM base AS tester
    
    # Run tests inside image (JUnit configured)
    CMD ["npm", "run", "test:ci"]
    
    # -------------------------
    # Build stage
    # -------------------------
    FROM base AS builder
    
    # Build the TypeScript source
    RUN npm run build
    
    # -------------------------
    # Production runtime stage
    # -------------------------
    FROM node:22.14.0-alpine AS production
    
    # Set working directory
    WORKDIR /app
    
    # Copy built artifacts from builder
    COPY --from=builder /app/dist ./dist
    
    # Copy node_modules from base
    COPY --from=base /app/node_modules ./node_modules
    
    # Use non-root user
    USER node
    
    # Run the app
    CMD ["node", "dist/index.js"]
    