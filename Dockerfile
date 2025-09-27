# 简化版Dockerfile - 用于部署预构建的dist文件
FROM 	nginx:stable-perl

# 复制构建好的dist文件到Nginx目录
COPY dist/ /usr/share/nginx/html/

# 复制Nginx配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# 启动Nginx
CMD ["nginx", "-g", "daemon off;"]
