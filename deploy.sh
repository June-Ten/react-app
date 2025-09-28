#!/bin/bash

# 设置变量
APP_NAME="react-app"
DOCKER_IMAGE="june-ten/react-app"
DOCKER_TAG="latest"
PORT="80"
CONTAINER_NAME="${APP_NAME}-container"

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
    echo "✅ 部署成功!"
    # 尝试探测当前服务器的可达 IP 地址（优先本机路由的源地址，再 hostname -I，再 ifconfig，再公网 IP 探测）
    HOST_IP=""
    if command -v ip >/dev/null 2>&1; then
        HOST_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}') || true
    fi
    if [ -z "${HOST_IP}" ] && command -v hostname >/dev/null 2>&1; then
        HOST_IP=$(hostname -I 2>/dev/null | awk '{print $1}') || true
    fi
    if [ -z "${HOST_IP}" ] && command -v ifconfig >/dev/null 2>&1; then
        HOST_IP=$(ifconfig 2>/dev/null | awk '/inet / && $2!~/(127|::1)/{print $2; exit}') || true
    fi
    # 最后尝试使用公网 IP 服务（可能被防火墙或离线环境阻止）
    if [ -z "${HOST_IP}" ] && command -v curl >/dev/null 2>&1; then
        HOST_IP=$(curl -s https://ifconfig.co 2>/dev/null || true)
    fi
    if [ -z "${HOST_IP}" ]; then
        HOST_IP="localhost"
    fi

    echo "🌐 应用地址: http://${HOST_IP}:${PORT}"
else
    echo "❌ 容器启动失败"
    docker logs ${CONTAINER_NAME}
    exit 1
fi
