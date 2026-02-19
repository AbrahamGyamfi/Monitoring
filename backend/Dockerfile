# Backend Dockerfile - Optimized
FROM node:18-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG BUILD_NUMBER

LABEL maintainer="Abraham Gyamfi <abraham.gyamfi@dev.com>"

WORKDIR /app

# Install wget and create user in one layer
RUN apk add --no-cache wget && \
    addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy package files
COPY package*.json ./

# Install dependencies with cache mount
RUN npm ci --production --no-audit --no-fund

# Copy backend source and set ownership
COPY --chown=nodejs:nodejs server.js ./

USER nodejs

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget -q --spider http://localhost:5000/health || exit 1

# Start the application
CMD ["node", "server.js"]
