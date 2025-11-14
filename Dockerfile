# Multi-stage Dockerfile with security best practices
# Build stage
FROM node:18-alpine AS builder

# Add build metadata arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# Set working directory
WORKDIR /app

# Install dependencies first (better layer caching)
COPY package*.json ./
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application code
COPY . .

# Build application (if applicable)
# RUN npm run build

# Production stage
FROM node:18-alpine AS production

# Add metadata labels
LABEL org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.title="myapp" \
      org.opencontainers.image.description="Application container" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.vendor="MyCompany" \
      org.opencontainers.image.licenses="MIT"

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy dependencies from builder
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules

# Copy application code
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

# Expose port (adjust as needed)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node healthcheck.js || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Run application
CMD ["node", "server.js"]
