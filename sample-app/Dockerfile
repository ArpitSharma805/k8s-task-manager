# Multi-stage build for sample application
# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production

COPY . .

RUN npm run build || echo "No build script, skipping"

# Stage 2: Runtime
FROM node:18-alpine AS runtime

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S -u 1001 -G nodejs nodejs

# Copy package files
COPY --from=builder --chown=nodejs:nodejs /app/package*.json ./

# Copy dependencies
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Copy application
COPY --from=builder --chown=nodejs:nodejs /app/server.js ./

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { if(r.statusCode !== 200) throw new Error(r.statusCode) })"

# Start application
CMD ["node", "server.js"]
