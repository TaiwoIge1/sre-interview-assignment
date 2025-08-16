# -------------------------
# Base deps stage
# -------------------------
    FROM node:22.14.0-alpine AS base

    # Set working directory
    WORKDIR /app
    
    # Install dependencies (use package-lock.json for reproducibility)
    COPY package*.json ./
    RUN npm ci --only=production
    
    # Copy all source (later stages may override dependencies)
    COPY . .
    
    # -------------------------
    # Test stage
    # -------------------------
    FROM node:22.14.0-alpine AS test
    WORKDIR /app
    
    # Copy in lockfile + deps
    COPY package*.json ./
    RUN npm ci
    
    # Copy source
    COPY . .
    
    # Run tests
    CMD ["npm", "run", "test:ci"]
    
    # -------------------------
    # Build stage
    # -------------------------
    FROM node:22.14.0-alpine AS build
    WORKDIR /app
    
    COPY package*.json ./
    RUN npm ci
    
    COPY . .
    RUN npm run build
    
    # -------------------------
    # Production runtime
    # -------------------------
    FROM node:22.14.0-alpine AS production
    WORKDIR /app
    
    # Copy build output & runtime deps only
    COPY --from=build /app/dist ./dist
    COPY --from=build /app/package*.json ./
    COPY --from=base /app/node_modules ./node_modules
    
    USER node
    CMD ["node", "dist/index.js"]
    