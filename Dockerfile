FROM lipanski/docker-static-website:latest

# Copy the website files
COPY /app .

# Expose the website
EXPOSE 8090

# Start the website
CMD ["/busybox-httpd", "-f", "-v", "-p",  "8090", "-c", "httpd.conf"]