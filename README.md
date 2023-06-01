# Docker Nginx на 2 портах и 2 вольюмами
Для выполнения этого действия требуется установить приложением git:
`git clone https://github.com/altyn-kenzhebaev/docker-hw13.git`
В текущей директории появится папка с именем репозитория. В данном случае docker-hw13. Ознакомимся с содержимым:
```
cd docker-hw13
ls -l

README.md
Vagrantfile
```
Здесь:
- README.md - файл с данным руководством
- Vagrantfile - файл описывающий виртуальную инфраструктуру для `Vagrant`
- otus-linux-adm - папка для работы над 2-м заданием
Так как у меня рабочая станция на Ubuntu проводим слеующие действия в целях установки docker:
```
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER
newgrp docker
docker ps
```
Чтобы провести кастомную конфигурацию контейнера NGINX, требуется пересобрать контейнер с новыми конфигами и директориями для подключения вольюмов
Dockerfile:
```
FROM nginx
ADD default80.conf /etc/nginx/conf.d/default.conf
ADD default3000.conf /etc/nginx/conf.d/
RUN mkdir /www; mkdir /logs
```
Конфиги Nginx для 80 порта:
```
server {
    listen       80;
    listen  [::]:80;
    server_name  localhost;
    access_log  /logs/80/80-access.log  main;
    error_log  /logs/80/80-error.log  warn;
    location / {
        root   /www/80/;
        index  index.html index.htm;
    }
}
```
Конфиги Nginx для 3000 порта:
```
server {
    listen       3000;
    listen  [::]:3000;
    server_name  localhost;
    access_log  /logs/3000/3000-access.log  main;
    error_log  /logs/3000/3000-error.log  warn;
    location / {
        root   /www/3000/;
        index  index.html index.htm;
    }
}
```
Собираем контейнер:
```
docker build -t nginxcustom .
```
Создаем папки для логов и файлы веб-страниц:
```
mkdir -p www/80; mkdir -p www/3000

cat << EOF > www/80/index.html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx 80 PORT!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx 80 PORT!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOF

####################################

cat << EOF > www/3000/index.html 
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx 3000 PORT!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx 3000 PORT!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
EOF

mkdir -p var/3000; mkdir -p var/80
```
В окончании запускаем контейнер с подключенными вольюмами и перенаправляемыми портами:
```
docker run -dt --name nginx -p 80:80 -p 3000:3000 --mount type=bind,source="$(pwd)"/www,target=/www --mount type=bind,source="$(pwd)"/var,target=/logs nginxcustom
```
# Написать Docker-compose для приложения Redmine, с использованием опции build
## Добавить в базовый образ redmine любую кастомную тему оформления
Создаем Dockerfile и добавляем туда новую тема А1:
```
FROM redmine
ADD a1 /usr/src/redmine/public/themes/a1
```
Собираем контейнер со внесенной в ней новой темой:
```
docker build -t redminecustom .
```
## Docker-compose для приложения Redmine, с использованием опции build.
Создаем docker-compose.yml:
```
version: '3.1'

services:
  redmine:
    image: redminecustom
    restart: always
    ports:
      - 8080:3000
    environment:
      REDMINE_DB_MYSQL: db
      REDMINE_DB_PASSWORD: example
      REDMINE_SECRET_KEY_BASE: supersecretkey

  db:
    image: mysql:5.7
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: redmine
```
Далее поднимаем docker compose:
```
docker compose up -d
[+] Building 0.0s (0/0)
[+] Running 2/2
 ✔ Container redmine-custom-db-1 Started     1.6s 
 ✔ Container redmine-custom-redmine-1  Started  1.5s
```
В моем случае redmine не поднимается, пока я не зайду в контейнер:
```
$ docker ps  -a
CONTAINER ID   IMAGE           COMMAND                  CREATED              STATUS              PORTS                                       NAMES
1649af7291ee   redminecustom   "/docker-entrypoint.…"   About a minute ago   Up About a minute   0.0.0.0:8080->3000/tcp, :::8080->3000/tcp   redmine-custom-redmine-1
aebcf169192e   mysql:5.7       "docker-entrypoint.s…"   About a minute ago   Up About a minute   3306/tcp, 33060/tcp                         redmine-custom-db-1
$ docker exec -it 1649af7291ee bash
root@1649af7291ee:/usr/src/redmine# 
exit
```
## Убедиться что после сборки новая тема доступна в настройках.
Проверяем => заходим http://127.0.0.1:8080/ => логинимся admin/admin => меняем пароль => меняем тему по ссылке http://127.0.0.1:8080/settings?tab=display => Theme: A1
![](Screenshot%20from%202023-06-01%2009-08-42.png)