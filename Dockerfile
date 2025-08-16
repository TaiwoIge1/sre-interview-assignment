# First stage - base deps
FROM node:22.14.0-alpine as base

# Create app directory and set non-root user
WORKDIR /app
COPY package*.json ./

# Install deps
RUN npm ci

# Copy source
COPY . .

# -------------------------
# Test stage
# -------------------------
FROM base as test
# Run tests (with CI flags for consistency)
RUN npm run test:ci

# -------------------------
# Build stage
# -------------------------
FROM base as build
RUN npm run build

# -------------------------
# Production runtime
# -------------------------
FROM node:22.14.0-alpine as prod

# Create and set working dir
WORKDIR /app
COPY --from=build /app ./

# Only copy node_modules from base (built with npm ci)
COPY --from=base /app/node_modules ./node_modules

# Use non-root user
USER node

CMD ["node", "dist/index.js"]
