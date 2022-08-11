FROM nginx:latest

COPY etc/nginx/nginx.conf /etc/nginx/nginx.conf 
COPY etc/nginx/conf.d /etc/nginx/conf.d 
COPY etc/nginx/projects.d /etc/nginx/projects.d/ 
COPY etc/nginx/upstream.d /etc/nginx/upstream.d/
COPY version.txt /usr/share/nginx/html/version.txt