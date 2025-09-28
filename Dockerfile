# 多阶段构建Dockerfile - 包含Node.js构建步骤
# 第一阶段：构建阶段
FROM node:20 AS builder

# 设置工作目录
WORKDIR /app

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装依赖（包括开发依赖，因为构建需要）
RUN npm ci

# 复制源代码
COPY . .

# 构建应用
RUN npm run build

# 第二阶段：生产阶段
FROM nginx:stable-perl

# 从构建阶段复制构建好的dist文件到Nginx目录
COPY --from=builder /app/dist/ /usr/share/nginx/html/

# 复制Nginx配置文件
COPY nginx.conf /etc/nginx/nginx.conf

# 暴露端口
EXPOSE 80

# 启动Nginx
CMD ["nginx", "-g", "daemon off;"]
