# Simple Dockerfile for Wiz Security Demo
# INTENTIONALLY VULNERABLE: Uses outdated Node.js version with known CVEs
# Based on standard Node.js Docker practices

FROM node:16.14.0-alpine3.15

# VULNERABILITY NOTES:
# - Node.js 16.14.0 has known security vulnerabilities (CVE-2022-0778, CVE-2022-21824)
# - Alpine 3.15 has outdated packages with potential security issues
# - This creates a vulnerable container for security scanning demonstration

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY . .

# CRITICAL: Verify the wizexercise.txt file exists and has correct content
RUN echo "Validating wizexercise.txt file..." && \
    test -f wizexercise.txt && \
    echo "✅ wizexercise.txt file exists" && \
    cat wizexercise.txt && \
    test "$(cat wizexercise.txt)" = "Devon Diffie" && \
    echo "✅ wizexercise.txt content is correct"

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000

# Start the application
CMD ["node", "server.js"]