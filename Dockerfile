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
RUN npm ci
COPY . .
ENV PATH=/app/node_modules/.bin:$PATH
CMD ["npm", "run", "test:ci"]

# -------------------------
# Builder stage
# -------------------------
FROM base AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
# Build into "build" folder as per tsconfig.json
RUN npm run build

# -------------------------
# Production runtime
# -------------------------
FROM node:22.14.0-alpine AS production
WORKDIR /app
# Copy the actual output folder "build" instead of "dist"
COPY --from=builder /app/build ./dist
COPY --from=base /app/node_modules ./node_modules
USER node
CMD ["node", "dist/index.js"]
    