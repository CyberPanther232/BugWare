# Use an official Nginx image as the base
# Nginx is a lightweight and high-performance web server
FROM nginx:alpine

# Remove the default Nginx welcome page
RUN rm /usr/share/nginx/html/index.html

# Copy the calculator.html file from your local machine
# into the directory where Nginx serves files from
COPY templates/index.html /usr/share/nginx/html/index.html

# Expose port 80 to the outside world. This is the default HTTP port
# that Nginx listens on.
EXPOSE 80
