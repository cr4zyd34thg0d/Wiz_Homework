# Wiz Security Demo - Intentionally Vulnerable Container
# This Dockerfile demonstrates common container security issues that tools like Wiz detect
# Built for educational purposes to show real-world vulnerabilities

FROM node:24-alpine

# 🚨 INTENTIONAL SECURITY VULNERABILITIES FOR DEMONSTRATION:
# 
# 1. KUBERNETES OVER-PRIVILEGES:
#    - Service account with cluster-admin privileges (configured in K8s manifests)
#    - Container can perform any action in the cluster
#
# 2. MONGODB CREDENTIALS IN ENV:
#    - Database credentials passed via environment variables
#    - Visible in container inspection and process lists
#
# 3. DETECTION:
#    - Wiz would flag over-privileged service accounts
#    - Security scanners would detect credential exposure
#    - Compliance frameworks would mark as non-compliant

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY . .

# 📋 REQUIREMENT VALIDATION: wizexercise.txt file
# The Wiz exercise requires a file named "wizexercise.txt" containing the candidate's name
# This build-time validation ensures the requirement is met before container deployment
RUN echo "Validating required wizexercise.txt file..." && \
    test -f wizexercise.txt && \
    echo "wizexercise.txt file exists" && \
    echo "File contents:" && \
    cat wizexercise.txt && \
    test "$(cat wizexercise.txt)" = "Devon Diffie" && \
    echo "wizexercise.txt content validation passed" && \
    echo "File will be accessible at /app/wizexercise.txt in running container"

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