
FROM python:3.12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends graphviz \
 && rm -rf /var/lib/apt/lists/*

COPY requirements-planner.txt /tmp/requirements-planner.txt
RUN pip install --no-cache-dir -r /tmp/requirements-planner.txt

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PYTHONPATH=/workspace/src

WORKDIR /workspace
CMD ["bash"]
