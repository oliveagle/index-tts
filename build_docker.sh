#!/bin/bash

# IndexTTS2 Docker 构建脚本
# 作者: Kilo Code
# 用途: 简化Docker镜像的构建和部署过程

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE} IndexTTS2 Docker 构建脚本${NC}"
    echo -e "${BLUE}================================================${NC}"
}

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    print_message "Docker版本: $(docker --version)"
}

# 检查Docker Compose是否安装
check_docker_compose() {
    if ! command -v docker-compose &> /dev/null; then
        print_warning "Docker Compose未安装，建议安装以获得更好的体验"
    else
        print_message "Docker Compose版本: $(docker-compose --version)"
    fi
}

# 检查NVIDIA Docker支持
check_nvidia_docker() {
    if command -v nvidia-docker &> /dev/null; then
        print_message "NVIDIA Docker已安装"
    else
        print_warning "NVIDIA Docker未安装，如果需要GPU支持请安装nvidia-docker2"
    fi
}

# 构建Docker镜像
build_image() {
    local tag=${1:-"indextts2:latest"}
    print_message "开始构建Docker镜像: $tag"
    
    # 使用buildkit加速构建
    export DOCKER_BUILDKIT=1
    
    docker build -t "$tag" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --no-cache \
        .
    
    print_message "镜像构建完成: $tag"
}

# 启动WebUI服务
start_webui() {
    print_message "启动IndexTTS2 WebUI服务..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose up --build -d
        print_message "WebUI已启动，访问: http://localhost:7860"
    else
        # 回退到纯Docker命令
        docker run -d --name indextts2-container --gpus all -p 7860:7860 indextts2:latest
        print_message "WebUI已启动，访问: http://localhost:7860"
    fi
}

# 停止服务
stop_services() {
    print_message "停止IndexTTS2服务..."
    
    if command -v docker-compose &> /dev/null; then
        docker-compose down
    else
        docker stop indextts2-container 2>/dev/null || true
        docker rm indextts2-container 2>/dev/null || true
    fi
    
    print_message "服务已停止"
}

# 清理资源
cleanup() {
    print_message "清理Docker资源..."
    
    # 停止并删除容器
    docker-compose down 2>/dev/null || true
    docker stop indextts2-container 2>/dev/null || true
    docker rm indextts2-container 2>/dev/null || true
    
    # 删除镜像
    docker rmi indextts2:latest 2>/dev/null || true
    
    print_message "清理完成"
}

# 下载模型权重
download_models() {
    print_message "下载IndexTTS2模型权重..."
    
    # 检查容器是否运行
    if ! docker ps | grep -q indextts2-container; then
        print_error "容器未运行，请先启动服务"
        return 1
    fi
    
    # 进入容器下载模型
    docker exec indextts2-container bash -c "
        echo '正在安装huggingface工具...'
        uv tool install 'huggingface-hub[cli,hf_xet]' || true
        uv tool install 'modelscope' || true
        
        echo '开始下载模型...'
        hf download IndexTeam/IndexTTS-2 --local-dir=checkpoints || true
        echo '或使用modelscope下载...'
        modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints || true
        
        echo '模型下载完成'
        ls -la checkpoints/
    "
}

# 显示日志
show_logs() {
    if command -v docker-compose &> /dev/null; then
        docker-compose logs -f
    else
        docker logs -f indextts2-container
    fi
}

# 进入容器
enter_container() {
    docker exec -it indextts2-container bash
}

# 显示帮助信息
show_help() {
    echo "IndexTTS2 Docker 构建脚本"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  build           构建Docker镜像"
    echo "  build-dev       构建开发版镜像"
    echo "  up              启动WebUI服务"
    echo "  down            停止所有服务"
    echo "  restart         重启服务"
    echo "  logs            查看日志"
    echo "  shell           进入容器"
    echo "  download        下载模型权重"
    echo "  cleanup         清理所有Docker资源"
    echo "  status          查看容器状态"
    echo "  help            显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 build        # 构建镜像"
    echo "  $0 up           # 启动服务"
    echo "  $0 shell        # 进入容器调试"
}

# 查看状态
show_status() {
    echo "=== Docker容器状态 ==="
    docker ps -a | grep indextts2 || echo "未找到IndexTTS2容器"
    
    echo ""
    echo "=== Docker镜像状态 ==="
    docker images | grep indextts2 || echo "未找到IndexTTS2镜像"
    
    echo ""
    echo "=== 端口占用情况 ==="
    netstat -tuln | grep 7860 || echo "7860端口未被占用"
}

# 主函数
main() {
    print_header
    
    case "${1:-help}" in
        "build")
            check_docker
            check_nvidia_docker
            build_image indextts2:latest
            ;;
        "build-dev")
            check_docker
            build_image indextts2:dev
            ;;
        "up")
            check_docker
            start_webui
            ;;
        "down")
            stop_services
            ;;
        "restart")
            stop_services
            sleep 2
            start_webui
            ;;
        "logs")
            show_logs
            ;;
        "shell")
            enter_container
            ;;
        "download")
            download_models
            ;;
        "cleanup")
            cleanup
            ;;
        "status")
            show_status
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# 运行主函数
main "$@"