@echo off
REM React应用Docker部署脚本 (Windows版本)
REM 使用方法: deploy.bat [服务器IP] [用户名] [部署路径]

setlocal enabledelayedexpansion

REM 默认参数
set SERVER_IP=%1
if "%SERVER_IP%"=="" set SERVER_IP=your-server-ip

set USERNAME=%2
if "%USERNAME%"=="" set USERNAME=root

set DEPLOY_PATH=%3
if "%DEPLOY_PATH%"=="" set DEPLOY_PATH=/opt/react-app

echo 🚀 开始部署React应用到服务器...

REM 检查dist目录是否存在
if not exist "dist" (
    echo ❌ 错误: dist目录不存在，请先运行 npm run build
    exit /b 1
)

echo 📦 检查构建文件...
dir dist

REM 创建部署目录结构
echo 📁 创建服务器部署目录...
ssh %USERNAME%@%SERVER_IP% "mkdir -p %DEPLOY_PATH%"

REM 上传必要文件
echo 📤 上传文件到服务器...
scp -r dist/ %USERNAME%@%SERVER_IP%:%DEPLOY_PATH%/
scp Dockerfile %USERNAME%@%SERVER_IP%:%DEPLOY_PATH%/
scp nginx.conf %USERNAME%@%SERVER_IP%:%DEPLOY_PATH%/
scp docker-compose.yml %USERNAME%@%SERVER_IP%:%DEPLOY_PATH%/

REM 在服务器上构建和运行Docker容器
echo 🐳 在服务器上构建Docker镜像...
ssh %USERNAME%@%SERVER_IP% "cd %DEPLOY_PATH% && docker build -t react-app ."

echo 🔄 停止并删除旧容器...
ssh %USERNAME%@%SERVER_IP% "docker stop react-app 2>nul || true && docker rm react-app 2>nul || true"

echo 🚀 启动新容器...
ssh %USERNAME%@%SERVER_IP% "docker run -d --name react-app -p 80:80 --restart unless-stopped react-app"

REM 检查容器状态
echo 🔍 检查容器状态...
ssh %USERNAME%@%SERVER_IP% "docker ps | grep react-app"

echo ✅ 部署完成！
echo 🌐 访问地址: http://%SERVER_IP%

REM 显示容器日志
echo 📋 容器日志:
ssh %USERNAME%@%SERVER_IP% "docker logs react-app"

pause
