pipeline {
    agent any
    
    environment {
        // 服务器配置 - 在Jenkins中配置这些环境变量
        SERVER_IP = 'your-server-ip'
        SERVER_USER = 'root'
        DEPLOY_PATH = '/opt/react-app'
        DOCKER_IMAGE_NAME = 'react-app'
        DOCKER_CONTAINER_NAME = 'react-app'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 检出代码...'
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo '📦 安装依赖...'
                sh 'npm ci'
            }
        }
        
        stage('Build') {
            steps {
                echo '🔨 构建React应用...'
                sh 'npm run build'
                
                // 验证构建结果
                sh 'ls -la dist/'
            }
        }
        
        stage('Test') {
            steps {
                echo '🧪 运行测试...'
                sh 'npm run lint'
                // 如果有测试，可以添加: sh 'npm test'
            }
        }
        
        stage('Prepare Deployment Files') {
            steps {
                echo '📁 准备部署文件...'
                sh '''
                    # 创建部署目录
                    mkdir -p deployment
                    
                    # 复制必要文件
                    cp -r dist deployment/
                    cp Dockerfile deployment/
                    cp nginx.conf deployment/
                    cp docker-compose.yml deployment/
                    
                    # 显示文件结构
                    ls -la deployment/
                '''
            }
        }
        
        stage('Deploy to Server') {
            steps {
                echo '🚀 部署到服务器...'
                script {
                    // 检查服务器连接
                    sh "ssh -o ConnectTimeout=10 ${SERVER_USER}@${SERVER_IP} 'echo 服务器连接成功'"
                    
                    // 创建服务器部署目录
                    sh "ssh ${SERVER_USER}@${SERVER_IP} 'mkdir -p ${DEPLOY_PATH}'"
                    
                    // 上传文件
                    sh "scp -r deployment/* ${SERVER_USER}@${SERVER_IP}:${DEPLOY_PATH}/"
                    
                    // 在服务器上执行部署
                    sh """
                        ssh ${SERVER_USER}@${SERVER_IP} '
                            cd ${DEPLOY_PATH}
                            
                            # 构建Docker镜像
                            echo "🐳 构建Docker镜像..."
                            docker build -t ${DOCKER_IMAGE_NAME} .
                            
                            # 停止并删除旧容器
                            echo "🔄 停止旧容器..."
                            docker stop ${DOCKER_CONTAINER_NAME} || true
                            docker rm ${DOCKER_CONTAINER_NAME} || true
                            
                            # 启动新容器
                            echo "🚀 启动新容器..."
                            docker run -d --name ${DOCKER_CONTAINER_NAME} -p 80:80 --restart unless-stopped ${DOCKER_IMAGE_NAME}
                            
                            # 检查容器状态
                            echo "🔍 检查容器状态..."
                            docker ps | grep ${DOCKER_CONTAINER_NAME}
                            
                            # 等待容器启动
                            sleep 5
                            
                            # 检查容器健康状态
                            if docker ps | grep -q ${DOCKER_CONTAINER_NAME}; then
                                echo "✅ 容器启动成功"
                            else
                                echo "❌ 容器启动失败"
                                docker logs ${DOCKER_CONTAINER_NAME}
                                exit 1
                            fi
                        '
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                echo '🏥 健康检查...'
                script {
                    // 等待服务启动
                    sh 'sleep 10'
                    
                    // 检查HTTP响应
                    sh """
                        response=\$(curl -s -o /dev/null -w "%{http_code}" http://${SERVER_IP} || echo "000")
                        if [ "\$response" = "200" ]; then
                            echo "✅ 应用部署成功，HTTP状态码: \$response"
                        else
                            echo "❌ 应用部署失败，HTTP状态码: \$response"
                            exit 1
                        fi
                    """
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                echo '🧹 清理临时文件...'
                sh '''
                    # 清理本地临时文件
                    rm -rf deployment/
                    
                    # 清理Docker构建缓存（可选）
                    # docker system prune -f
                '''
            }
        }
    }
    
    post {
        success {
            echo '🎉 部署成功！'
            // 可以添加通知，如发送邮件、Slack消息等
            // emailext (
            //     subject: "部署成功: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //     body: "React应用已成功部署到 ${SERVER_IP}",
            //     to: "your-email@example.com"
            // )
        }
        
        failure {
            echo '❌ 部署失败！'
            // 可以添加失败通知
            // emailext (
            //     subject: "部署失败: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
            //     body: "React应用部署失败，请检查日志",
            //     to: "your-email@example.com"
            // )
        }
        
        always {
            echo '📋 构建完成'
            // 清理工作空间（可选）
            // cleanWs()
        }
    }
}
