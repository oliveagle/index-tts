# 使用官方PyTorch基础镜像，集成CUDA支持
FROM harbor1.suanleme.cn/oliveagle/indextts2:20251028

# COPY uv.lock uv.lock

# 设置默认的环境变量
ENV PATH=/opt/conda/bin:$PATH
ENV PYTHONPATH=/app:$PYTHONPATH
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# 暴露端口（用于WebUI）
EXPOSE 7860

# 健康检查
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import torch; print('PyTorch:', torch.__version__); \
                   import torchaudio; print('torchaudio:', torchaudio.__version__); \
                   print('CUDA available:', torch.cuda.is_available())" || exit 1

WORKDIR /app

# --- 默认进入 bash
CMD ["bash"]
ENTRYPOINT []


# --- 默认直接启动 webui_modifed.py
# CMD []
# ENTRYPOINT ["/app/.venv/bin/python", "webui_modifed.py"]


