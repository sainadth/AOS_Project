# Use Alpine Linux as the base image
FROM alpine:latest

# Install SQLite3
RUN apk add --no-cache sqlite

# Set the working directory
WORKDIR /data

# Default command to keep the container running
CMD ["sh", "-c", "tail -f /dev/null"]
