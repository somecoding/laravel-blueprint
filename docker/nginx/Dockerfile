FROM nginx:1.14.2-alpine

COPY nginx.conf /etc/nginx/nginx.conf
COPY site.conf /etc/nginx/conf.d/default.conf

# Make sure the server root directory exists
RUN mkdir -p /var/www/html/public
