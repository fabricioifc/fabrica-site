FROM lipanski/docker-static-website:latest

# Copy the website files
COPY /app .

# Expose the website
EXPOSE 1111

# Start the website
CMD ["/busybox-httpd", "-f", "-v", "-p",  "1111", "-c", "httpd.conf"]