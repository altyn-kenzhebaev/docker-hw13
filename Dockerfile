FROM nginx
ADD default80.conf /etc/nginx/conf.d/default.conf
ADD default3000.conf /etc/nginx/conf.d/
RUN mkdir /www; mkdir /logs
