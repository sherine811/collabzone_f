# Use official nginx image
FROM nginx:alpine

# Copy website content to nginx default directory
COPY . /usr/share/nginx/html

# Expose port 80 for the web app
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
