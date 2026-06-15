FROM python:3.12-slim

ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    WEISS_CARD_ART_CACHE=/data/card_art \
    WEISS_HUMAN_PLAY_REPO_ROOT=/data/weiss-demo

WORKDIR /app

COPY pyproject.toml README.md ./
COPY python ./python

RUN python -m pip install --no-cache-dir --upgrade pip && \
    python -m pip install --no-cache-dir --index-url "${TORCH_INDEX_URL}" "torch==2.11.0" && \
    python -m pip install --no-cache-dir ".[sim]"

EXPOSE 8765

CMD ["python", "-m", "weiss_rl.human_play.web_server", "--host", "0.0.0.0", "--port", "8765", "--static-dir", "/app/static"]
