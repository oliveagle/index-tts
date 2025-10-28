# IndexTTS2 Docker 容器化部署指南

本指南介绍如何使用Docker部署和使用IndexTTS2项目。

## 🚀 快速开始

### 1. 构建和运行

#### 使用Docker Compose（推荐）

```bash
# 构建并启动WebUI服务
docker-compose up --build

# 后台运行
docker-compose up -d

# 访问WebUI
# 浏览器打开: http://localhost:7860

# 停止服务
docker-compose down
```

#### 仅使用Docker

```bash
# 构建镜像
docker build -t indextts2:latest .

# 运行容器
docker run --rm -it --gpus all -p 7860:7860 indextts2:latest

# 或后台运行
docker run -d --name indextts2-container --gpus all -p 7860:7860 indextts2:latest
```

### 2. 下载模型权重

容器启动后，需要下载模型权重：

```bash
# 进入容器
docker exec -it indextts2-container bash

# 安装huggingface工具
uv tool install "huggingface-hub[cli,hf_xet]"

# 下载模型
hf download IndexTeam/IndexTTS-2 --local-dir=checkpoints

# 或使用modelscope
uv tool install "modelscope"
modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints

# 退出容器
exit
```

### 3. 使用方法

#### WebUI方式
1. 启动容器后，浏览器访问 `http://localhost:7860`
2. 上传参考音频文件和情感音频文件（如需要）
3. 输入文本，点击生成

#### Python API方式
```bash
# 进入容器
docker exec -it indextts2-container bash

# 运行推理脚本
uv run indextts/infer_v2.py

# 或在Python中直接使用
python3 -c "
from indextts.infer_v2 import IndexTTS2
tts = IndexTTS2(cfg_path='checkpoints/config.yaml', model_dir='checkpoints')
tts.infer(spk_audio_prompt='examples/voice_01.wav', text='Hello world!', output_path='output.wav')
"
```

## 📁 目录结构

容器内的目录结构：
```
/app/
├── indextts/              # 主要代码
├── checkpoints/           # 模型权重目录
├── examples/              # 示例音频
├── saved_timbres/         # 用户保存的音色
├── outputs/               # 输出文件
└── pyproject.toml         # 项目配置
```

## 🔧 配置选项

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `CUDA_VISIBLE_DEVICES` | `all` | 可见的GPU设备 |
| `HF_ENDPOINT` | - | HuggingFace镜像地址（可选） |

### 端口映射

- `7860`: WebUI端口

### 卷挂载

- `./checkpoints:/app/checkpoints`: 模型权重（只读）
- `./saved_timbres:/app/saved_timbres`: 用户音色文件
- `./outputs:/app/outputs`: 输出文件

## 🛠️ 开发模式

开发时可以启动开发模式容器：

```bash
# 启动开发模式
docker-compose --profile dev up indextts2-dev

# 进入容器进行开发
docker exec -it indextts2-dev-container bash

# 在容器内可以直接修改代码
uv run --watch webui.py  # 实时重新加载
```

## 🐛 故障排除

### 1. GPU不支持
如果机器没有GPU，可以使用CPU版本：
```bash
docker run --rm -it -p 7860:7860 indextts2:latest
```

### 2. 端口占用
如果7860端口被占用，可以映射到其他端口：
```bash
docker run -d --name indextts2-custom -p 8888:7860 indextts2:latest
```

### 3. 模型下载失败
使用国内镜像：
```bash
export HF_ENDPOINT="https://hf-mirror.com"
```

### 4. 音频输出问题
检查系统音频设置：
```bash
# 进入容器
docker exec -it indextts2-container bash

# 检查音频设备
python -c "import sounddevice; print(sounddevice.query_devices())"
```

## 📋 构建选项

### 完整构建
```bash
# 包含所有可选依赖
docker build --target production -t indextts2:latest .
```

### 开发构建
```bash
# 用于开发，保留源代码调试信息
docker build --target development -t indextts2:dev .
```

## 🔄 更新

更新到新版本：
```bash
# 拉取最新代码
git pull origin main

# 重新构建镜像
docker-compose build --no-cache

# 重启服务
docker-compose up -d
```

## 📞 支持

如有问题，请参考：
- [IndexTTS2官方文档](https://index-tts.github.io/index-tts2.github.io/)
- [GitHub Issues](https://github.com/index-tts/index-tts/issues)
- [Discord社区](https://discord.gg/uT32E7KDmy)

## 🇨🇳 中国用户特殊说明

### 镜像源配置
Docker镜像已预配置清华大学镜像源：
- pip镜像：`https://pypi.tuna.tsinghua.edu.cn/simple`
- uv镜像：`https://pypi.tuna.tsinghua.edu.cn/simple`

这将显著提升在中国地区的包下载速度。

### HuggingFace加速
如需加速HuggingFace模型下载，可在启动容器时设置环境变量：
```bash
# 使用国内镜像
docker run -e HF_ENDPOINT="https://hf-mirror.com" ...
```

### 完整的中国用户友好配置
```bash
# 构建镜像（使用清华大学镜像源）
./build_docker.sh build

# 启动服务并设置HuggingFace镜像
docker run -e HF_ENDPOINT="https://hf-mirror.com" -e HF_HOME="/app/.cache/huggingface" ...
```