
# Stage 1: Build React application
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Build React application
RUN npm run build


# Stage 2: Production Nginx server
FROM nginxinc/nginx-unprivileged:1.27-alpine

# Copy only production build
COPY --from=builder /app/dist /usr/share/nginx/html

# Nginx listens on port 8080
EXPOSE 8080

# Run as non-root user
USER 101

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1
