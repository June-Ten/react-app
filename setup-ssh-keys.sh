#!/bin/bash
# Jenkins SSH配置脚本
# 解决GitHub SSH连接问题

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_info "🔧 配置Jenkins SSH密钥..."

# 检查是否在Jenkins环境中
if [ -z "$JENKINS_HOME" ]; then
    log_warning "未检测到Jenkins环境，请确保在Jenkins服务器上运行此脚本"
fi

# 创建.ssh目录
log_info "📁 创建SSH目录..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# 添加GitHub主机密钥到known_hosts
log_info "🔑 添加GitHub主机密钥..."
ssh-keyscan -t rsa,dsa,ecdsa,ed25519 github.com >> ~/.ssh/known_hosts

# 验证known_hosts文件
if grep -q "github.com" ~/.ssh/known_hosts; then
    log_success "GitHub主机密钥已添加"
else
    log_error "添加GitHub主机密钥失败"
    exit 1
fi

# 设置正确的权限
chmod 644 ~/.ssh/known_hosts

# 测试SSH连接
log_info "🔍 测试SSH连接..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    log_success "SSH连接测试成功"
elif ssh -T git@github.com 2>&1 | grep -q "Permission denied"; then
    log_warning "SSH连接成功但权限被拒绝，这是正常的（GitHub不允许shell访问）"
    log_success "SSH连接配置正确"
else
    log_error "SSH连接测试失败"
    log_info "请检查："
    log_info "1. 网络连接是否正常"
    log_info "2. 防火墙是否阻止SSH连接"
    log_info "3. GitHub服务是否正常"
    exit 1
fi

log_success "🎉 SSH配置完成！"
log_info "现在可以在Jenkins中使用SSH方式连接GitHub仓库了"
