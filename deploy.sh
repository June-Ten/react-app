#!/bin/bash

# React应用Docker部署脚本
# 使用方法: ./deploy.sh [服务器IP] [用户名] [部署路径]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 默认参数
SERVER_IP=${1:-"your-server-ip"}
USERNAME=${2:-"root"}
DEPLOY_PATH=${3:-"/opt/react-app"}

echo -e "${GREEN}🚀 开始部署React应用到服务器...${NC}"

# 检查dist目录是否存在
if [ ! -d "dist" ]; then
    echo -e "${RED}❌ 错误: dist目录不存在，请先运行 npm run build${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 检查构建文件...${NC}"
ls -la dist/

# 创建部署目录结构
echo -e "${YELLOW}📁 创建服务器部署目录...${NC}"
ssh ${USERNAME}@${SERVER_IP} "mkdir -p ${DEPLOY_PATH}"

# 上传必要文件
echo -e "${YELLOW}📤 上传文件到服务器...${NC}"
scp -r dist/ ${USERNAME}@${SERVER_IP}:${DEPLOY_PATH}/
scp Dockerfile ${USERNAME}@${SERVER_IP}:${DEPLOY_PATH}/
scp nginx.conf ${USERNAME}@${SERVER_IP}:${DEPLOY_PATH}/
scp docker-compose.yml ${USERNAME}@${SERVER_IP}:${DEPLOY_PATH}/

# 在服务器上构建和运行Docker容器
echo -e "${YELLOW}🐳 在服务器上构建Docker镜像...${NC}"
ssh ${USERNAME}@${SERVER_IP} "cd ${DEPLOY_PATH} && docker build -t react-app ."

echo -e "${YELLOW}🔄 停止并删除旧容器...${NC}"
ssh ${USERNAME}@${SERVER_IP} "docker stop react-app || true && docker rm react-app || true"

echo -e "${YELLOW}🚀 启动新容器...${NC}"
ssh ${USERNAME}@${SERVER_IP} "docker run -d --name react-app -p 80:80 --restart unless-stopped react-app"

# 检查容器状态
echo -e "${YELLOW}🔍 检查容器状态...${NC}"
ssh ${USERNAME}@${SERVER_IP} "docker ps | grep react-app"

echo -e "${GREEN}✅ 部署完成！${NC}"
echo -e "${GREEN}🌐 访问地址: http://${SERVER_IP}${NC}"

# 显示容器日志
echo -e "${YELLOW}📋 容器日志:${NC}"
ssh ${USERNAME}@${SERVER_IP} "docker logs react-app"
