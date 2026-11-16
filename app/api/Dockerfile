
# Pinned Node.js Alpine image
FROM node:20.18.1-alpine3.20

# Production configuration
ENV NODE_ENV=production
ENV PORT=3000

WORKDIR /app

# Copy package files first for Docker layer caching
COPY package*.json ./

# Install production dependencies only
RUN npm install --omit=dev && npm cache clean --force

# Copy application source
COPY --chown=node:node . .

# Run as non-root user
USER node

EXPOSE 3000

# API health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:3000/api/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

# Default API command
CMD ["npm", "start"]
