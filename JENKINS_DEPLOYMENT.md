# Jenkins部署React应用指南

## 概述

本指南介绍如何使用Jenkins自动部署React应用到Linux服务器。支持Pipeline和传统Job两种方式。

## 前置条件

### Jenkins服务器要求
- Jenkins 2.0+
- 已安装插件：
  - Pipeline Plugin
  - SSH Agent Plugin
  - Docker Plugin
  - NodeJS Plugin

### 目标服务器要求
- Linux系统
- 已安装Docker
- 已配置SSH密钥认证
- 用户有Docker执行权限

## 配置步骤

### 1. 配置Jenkins全局工具

1. 进入 **Manage Jenkins** → **Global Tool Configuration**
2. 配置NodeJS：
   - Name: `NodeJS`
   - Version: `18.x` 或更高版本
   - 勾选 "Install automatically"

### 2. 配置SSH密钥

1. 进入 **Manage Jenkins** → **Manage Credentials**
2. 添加SSH私钥：
   - Kind: `SSH Username with private key`
   - ID: `server-ssh-key`
   - Username: `root` (或你的服务器用户名)
   - Private Key: 选择 "Enter directly" 并粘贴私钥内容

### 3. 配置环境变量

1. 进入 **Manage Jenkins** → **Configure System**
2. 在 "Global properties" 中添加环境变量：
   - `SERVER_IP`: 你的服务器IP地址
   - `SERVER_USER`: 服务器用户名
   - `DEPLOY_PATH`: 部署路径 (如: `/opt/react-app`)

## 部署方式

### 方式一：Pipeline Job（推荐）

#### 创建Pipeline Job

1. 点击 **New Item**
2. 选择 **Pipeline**，输入项目名称
3. 在 **Pipeline** 配置中：
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: 你的Git仓库地址
   - Script Path: `Jenkinsfile`

#### 配置Pipeline参数

在Pipeline脚本中修改环境变量：

```groovy
environment {
    SERVER_IP = '192.168.1.100'        // 你的服务器IP
    SERVER_USER = 'root'                // 服务器用户名
    DEPLOY_PATH = '/opt/react-app'      // 部署路径
    DOCKER_IMAGE_NAME = 'react-app'     // Docker镜像名
    DOCKER_CONTAINER_NAME = 'react-app' // 容器名
}
```

### 方式二：传统Job

#### 创建Freestyle Job

1. 点击 **New Item**
2. 选择 **Freestyle project**，输入项目名称

#### 配置源码管理

1. **Source Code Management**:
   - 选择 `Git`
   - Repository URL: 你的Git仓库地址
   - Branches: `*/main` 或 `*/master`

#### 配置构建环境

1. **Build Environment**:
   - 勾选 "Provide Node & npm bin/ folder to PATH"
   - NodeJS Installation: 选择配置的NodeJS版本

#### 配置构建步骤

1. **Build Steps** → **Add build step** → **Execute shell**:

```bash
#!/bin/bash
set -e

echo "📦 安装依赖..."
npm ci

echo "🔨 构建应用..."
npm run build

echo "🧪 运行测试..."
npm run lint

echo "📁 准备部署文件..."
mkdir -p deployment
cp -r dist deployment/
cp Dockerfile deployment/
cp nginx.conf deployment/
cp docker-compose.yml deployment/

echo "🚀 部署到服务器..."
ssh root@${SERVER_IP} "mkdir -p ${DEPLOY_PATH}"

scp -r deployment/* root@${SERVER_IP}:${DEPLOY_PATH}/

ssh root@${SERVER_IP} "
    cd ${DEPLOY_PATH}
    
    echo '🐳 构建Docker镜像...'
    docker build -t react-app .
    
    echo '🔄 停止旧容器...'
    docker stop react-app || true
    docker rm react-app || true
    
    echo '🚀 启动新容器...'
    docker run -d --name react-app -p 80:80 --restart unless-stopped react-app
    
    echo '🔍 检查容器状态...'
    docker ps | grep react-app
    
    echo '✅ 部署完成！'
"

echo "🧹 清理临时文件..."
rm -rf deployment/
```

### 方式三：使用Jenkins部署脚本

#### 创建部署脚本

创建 `jenkins-deploy.sh`:

```bash
#!/bin/bash
set -e

# 从Jenkins环境变量获取配置
SERVER_IP=${SERVER_IP:-"your-server-ip"}
SERVER_USER=${SERVER_USER:-"root"}
DEPLOY_PATH=${DEPLOY_PATH:-"/opt/react-app"}
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-"react-app"}
DOCKER_CONTAINER_NAME=${DOCKER_CONTAINER_NAME:-"react-app"}

echo "🚀 开始Jenkins部署..."

# 构建应用
echo "📦 安装依赖..."
npm ci

echo "🔨 构建应用..."
npm run build

# 准备部署文件
echo "📁 准备部署文件..."
mkdir -p deployment
cp -r dist deployment/
cp Dockerfile deployment/
cp nginx.conf deployment/
cp docker-compose.yml deployment/

# 部署到服务器
echo "🚀 部署到服务器..."
ssh ${SERVER_USER}@${SERVER_IP} "mkdir -p ${DEPLOY_PATH}"
scp -r deployment/* ${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/

ssh ${SERVER_USER}@${SERVER_IP} "
    cd ${DEPLOY_PATH}
    
    # 构建Docker镜像
    docker build -t ${DOCKER_IMAGE_NAME} .
    
    # 停止并删除旧容器
    docker stop ${DOCKER_CONTAINER_NAME} || true
    docker rm ${DOCKER_CONTAINER_NAME} || true
    
    # 启动新容器
    docker run -d --name ${DOCKER_CONTAINER_NAME} -p 80:80 --restart unless-stopped ${DOCKER_IMAGE_NAME}
    
    # 检查状态
    docker ps | grep ${DOCKER_CONTAINER_NAME}
"

# 健康检查
echo "🏥 健康检查..."
sleep 10
response=$(curl -s -o /dev/null -w "%{http_code}" http://${SERVER_IP} || echo "000")
if [ "$response" = "200" ]; then
    echo "✅ 部署成功！"
else
    echo "❌ 部署失败，HTTP状态码: $response"
    exit 1
fi

# 清理
echo "🧹 清理临时文件..."
rm -rf deployment/

echo "🎉 Jenkins部署完成！"
```

## 高级配置

### 1. 多环境部署

修改Pipeline脚本支持多环境：

```groovy
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: '选择部署环境'
        )
    }
    
    environment {
        SERVER_IP = "${params.ENVIRONMENT == 'production' ? 'prod-server-ip' : 'dev-server-ip'}"
        DEPLOY_PATH = "/opt/react-app-${params.ENVIRONMENT}"
    }
    
    // ... 其他配置
}
```

### 2. 回滚功能

添加回滚步骤：

```groovy
stage('Rollback') {
    when {
        expression { params.ACTION == 'rollback' }
    }
    steps {
        sh """
            ssh ${SERVER_USER}@${SERVER_IP} '
                cd ${DEPLOY_PATH}
                
                # 停止当前容器
                docker stop ${DOCKER_CONTAINER_NAME} || true
                docker rm ${DOCKER_CONTAINER_NAME} || true
                
                # 启动上一个版本的镜像
                docker run -d --name ${DOCKER_CONTAINER_NAME} -p 80:80 --restart unless-stopped ${DOCKER_IMAGE_NAME}:previous
            '
        """
    }
}
```

### 3. 通知配置

添加邮件通知：

```groovy
post {
    success {
        emailext (
            subject: "✅ 部署成功: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            body: """
                <h2>部署成功</h2>
                <p>应用已成功部署到服务器</p>
                <ul>
                    <li>服务器: ${SERVER_IP}</li>
                    <li>部署路径: ${DEPLOY_PATH}</li>
                    <li>访问地址: http://${SERVER_IP}</li>
                </ul>
            """,
            to: "dev-team@example.com"
        )
    }
    
    failure {
        emailext (
            subject: "❌ 部署失败: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            body: "部署失败，请检查Jenkins日志",
            to: "dev-team@example.com"
        )
    }
}
```

## 故障排除

### 常见问题

1. **SSH连接失败**
   - 检查SSH密钥配置
   - 确认服务器IP和端口
   - 测试SSH连接: `ssh user@server-ip`

2. **Docker权限问题**
   - 确保用户有Docker执行权限
   - 将用户添加到docker组: `usermod -aG docker username`

3. **构建失败**
   - 检查Node.js版本
   - 确认package.json配置
   - 查看构建日志

4. **部署后无法访问**
   - 检查Docker容器状态: `docker ps`
   - 查看容器日志: `docker logs container-name`
   - 检查端口映射: `docker port container-name`

### 调试命令

```bash
# 检查Jenkins环境
echo $NODE_HOME
echo $PATH

# 检查构建结果
ls -la dist/

# 检查Docker状态
docker ps -a
docker images

# 检查容器日志
docker logs react-app

# 进入容器调试
docker exec -it react-app sh
```

## 最佳实践

1. **使用版本标签**: 为Docker镜像添加版本标签
2. **环境隔离**: 不同环境使用不同的配置
3. **备份策略**: 定期备份部署配置
4. **监控告警**: 配置应用监控和告警
5. **安全加固**: 使用非root用户运行容器
6. **日志管理**: 配置日志收集和分析
