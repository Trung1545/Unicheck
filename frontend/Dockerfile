# ==============================================================================
# UniCheck - Frontend Dockerfile (Production Multi-Stage Build)
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build the React 18 / TypeScript SPA
# ------------------------------------------------------------------------------
FROM node:20-alpine AS builder

WORKDIR /app

# Copy dependency specifications for layer caching
COPY package.json package-lock.json ./

# Install exact dependencies without modifying package-lock
RUN npm ci

# Copy project source and configuration
COPY . .

# Build production bundle with TypeScript check
ARG VITE_API_URL=/api/v1
ENV VITE_API_URL=${VITE_API_URL}
RUN npm run build

# ------------------------------------------------------------------------------
# Stage 2: Serve production build using lightweight Nginx Alpine
# ------------------------------------------------------------------------------
FROM nginx:alpine

# Remove default boilerplate configuration
RUN rm -rf /etc/nginx/conf.d/*

# Copy custom Nginx configuration with SPA fallback & API proxying
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy production static assets from builder stage (zero node_modules)
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose standard HTTP port
EXPOSE 80

# Health check to ensure Nginx server is actively responding
HEALTHCHECK --interval=15s --timeout=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/ || exit 1

# Launch Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
