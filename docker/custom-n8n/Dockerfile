ARG N8N_VERSION=latest
FROM n8nio/n8n:${N8N_VERSION}

# Install extra system dependencies example
USER root
RUN apk add --no-cache jq python3

# Switch back to node user
USER node
