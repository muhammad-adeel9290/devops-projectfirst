# ==============================================================================
# Stage 1: Build Dependencies
# ==============================================================================
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency definitions
COPY package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev --ignore-scripts

# ==============================================================================
# Stage 2: Minimal Production Runtime
# ==============================================================================
FROM node:20-alpine AS runner

# Security: Add dumb-init and curl for healthcheck
RUN apk add --no-cache dumb-init curl

# Set production environment
ENV NODE_ENV=production \
    PORT=3000

WORKDIR /app

# Copy dependencies and application code
COPY --from=builder /app/node_modules ./node_modules
COPY package.json ./
COPY src/ ./src/
COPY server_health_check.sh alert_on_failure.sh ./

# Make scripts executable and set ownership to built-in non-root 'node' user
RUN chmod +x *.sh && \
    chown -R node:node /app

# Switch to unprivileged user
USER node

# Container healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/healthz || exit 1

EXPOSE 3000

# Use dumb-init as PID 1 for signal handling (SIGTERM/SIGINT)
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["node", "src/app.js"]
