# Use Nginx as base image
FROM nginx:alpine

# Copy our custom index.html into Nginx default html folder
COPY index.html /usr/share/nginx/html/index.html
