#!/bin/bash

# 设置变量
APP_NAME="react-app"
DOCKER_IMAGE="june-ten/react-app"
DOCKER_TAG="latest"
PORT="80"
CONTAINER_NAME="${APP_NAME}-container"
HOST_IP="http://106.14.124.190"

echo "🚀 开始部署 ${APP_NAME}..."

# 检查必要文件

if [ ! -f "nginx.conf" ]; then
    echo "❌ 错误: nginx.conf 文件不存在"
    exit 1
fi

# 构建 Docker 镜像
echo "📦 构建 Docker 镜像..."
docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} .

# 停止并删除旧容器
echo "🛑 停止旧容器..."
docker stop ${CONTAINER_NAME} 2>/dev/null || true
docker rm ${CONTAINER_NAME} 2>/dev/null || true

# 运行新容器
echo "▶️  启动新容器..."
docker run -d \
    --name ${CONTAINER_NAME} \
    -p ${PORT}:80 \
    ${DOCKER_IMAGE}:${DOCKER_TAG}

# 检查容器状态
echo "⏳ 检查容器状态..."
sleep 3

if docker ps | grep -q ${CONTAINER_NAME}; then

    echo "🌐 应用地址: ${HOST_IP}:${PORT}"
else
    echo "❌ 容器启动失败"
    docker logs ${CONTAINER_NAME}
    exit 1
fi
