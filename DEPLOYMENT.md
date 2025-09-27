# React应用Docker部署指南

## 文件说明

- `Dockerfile`: 简化版Dockerfile，用于部署预构建的dist文件
- `nginx.conf`: Nginx配置文件，优化了静态文件服务和React Router支持
- `.dockerignore`: Docker构建时忽略的文件和目录
- `docker-compose.yml`: Docker Compose配置文件，简化部署流程
- `deploy.sh`: Linux/macOS部署脚本
- `deploy.bat`: Windows部署脚本

## 部署方式

### 方式一：本地构建 + 上传部署（推荐）

这种方式适合本地开发完成后，将构建好的文件上传到服务器部署。

#### 步骤：

1. **本地构建**
   ```bash
   # 在本地构建React应用
   npm run build
   ```

2. **使用部署脚本（推荐）**
   
   **Linux/macOS:**
   ```bash
   # 给脚本执行权限
   chmod +x deploy.sh
   
   # 运行部署脚本
   ./deploy.sh your-server-ip username /opt/react-app
   ```
   
   **Windows:**
   ```cmd
   # 运行部署脚本
   deploy.bat your-server-ip username /opt/react-app
   ```

3. **手动部署**
   ```bash
   # 上传必要文件到服务器
   scp -r dist/ user@your-server:/opt/react-app/
   scp Dockerfile user@your-server:/opt/react-app/
   scp nginx.conf user@your-server:/opt/react-app/
   scp docker-compose.yml user@your-server:/opt/react-app/
   
   # 在服务器上构建和运行
   ssh user@your-server
   cd /opt/react-app
   docker build -t react-app .
   docker run -d --name react-app -p 80:80 --restart unless-stopped react-app
   ```

### 方式二：使用Docker Compose

1. **上传文件到服务器**
   ```bash
   # 将整个项目文件夹上传到Linux服务器
   scp -r ./my-react-app user@your-server:/path/to/deployment/
   ```

2. **在服务器上构建和运行**
   ```bash
   cd /path/to/deployment/my-react-app
   
   # 构建并启动容器
   docker-compose up -d
   
   # 查看运行状态
   docker-compose ps
   
   # 查看日志
   docker-compose logs -f
   ```

3. **访问应用**
   - 在浏览器中访问 `http://your-server-ip` 或 `http://your-domain`

## 常用管理命令

### Docker Compose命令
```bash
# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 重新构建并启动
docker-compose up -d --build

# 查看日志
docker-compose logs -f react-app
```

### Docker命令
```bash
# 停止容器
docker stop my-react-app

# 启动容器
docker start my-react-app

# 删除容器
docker rm my-react-app

# 删除镜像
docker rmi my-react-app

# 进入容器
docker exec -it my-react-app sh
```

## 配置说明

### 端口配置
- 默认端口：80
- 如需修改端口，编辑 `docker-compose.yml` 中的端口映射：
  ```yaml
  ports:
    - "8080:80"  # 将80改为8080
  ```

### 环境变量
- 在 `docker-compose.yml` 中可以添加环境变量：
  ```yaml
  environment:
    - NODE_ENV=production
    - API_URL=https://your-api.com
  ```

### Nginx配置
- 如需修改Nginx配置，编辑 `nginx.conf` 文件
- 主要配置包括：
  - 静态文件缓存
  - Gzip压缩
  - 安全头设置
  - React Router支持

## 故障排除

1. **容器无法启动**
   ```bash
   # 查看详细错误信息
   docker-compose logs react-app
   ```

2. **端口被占用**
   ```bash
   # 检查端口占用
   netstat -tulpn | grep :80
   
   # 修改端口映射
   # 编辑 docker-compose.yml
   ```

3. **构建失败**
   ```bash
   # 清理Docker缓存
   docker system prune -a
   
   # 重新构建
   docker-compose build --no-cache
   ```

## 生产环境建议

1. **使用HTTPS**
   - 配置SSL证书
   - 修改Nginx配置支持HTTPS

2. **监控和日志**
   - 配置日志轮转
   - 使用监控工具（如Prometheus + Grafana）

3. **备份策略**
   - 定期备份应用代码
   - 配置容器镜像备份

4. **安全加固**
   - 定期更新基础镜像
   - 使用非root用户运行容器
   - 配置防火墙规则
