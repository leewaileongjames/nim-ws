# milvusdb/milvus:v2.6.2-gpu
# minio/minio:RELEASE.2025-09-07T16-13-09Z
# nvcr.io/mgsgvj1csvvp/nv-ingest-uv:25.9.0
# nvcr.io/nim/baidu/paddleocr:1.5.0
# nvcr.io/nim/nvidia/llama-3.2-nv-embedqa-1b-v2:1.10.0
# nvcr.io/nim/nvidia/llama-3.2-nv-rerankqa-1b-v2:1.8.0
# nvcr.io/nim/nvidia/nemoretriever-graphic-elements-v1:1.5.0
# nvcr.io/nim/nvidia/nemoretriever-page-elements-v2:1.5.0
# nvcr.io/nim/nvidia/nemoretriever-table-structure-v1:1.5.0
# nvcr.io/nvidia/blueprint/ingestor-server:2.3.0
# nvcr.io/nvidia/blueprint/rag-frontend:2.3.0
# nvcr.io/nvidia/blueprint/rag-server:2.3.0
# quay.io/coreos/etcd:v3.6.5
# redis/redis-stack:7.2.0-v18


#!/bin/bash

# List of Docker images to pull
images=(
    "milvusdb/milvus:v2.6.2-gpu"
    "minio/minio:RELEASE.2025-09-07T16-13-09Z"
    "nvcr.io/mgsgvj1csvvp/nv-ingest-uv:25.9.0"
    "nvcr.io/nim/baidu/paddleocr:1.5.0"
    "nvcr.io/nim/nvidia/llama-3.2-nv-embedqa-1b-v2:1.10.0"
    "nvcr.io/nim/nvidia/llama-3.2-nv-rerankqa-1b-v2:1.8.0"
    "nvcr.io/nim/nvidia/nemoretriever-graphic-elements-v1:1.5.0"
    "nvcr.io/nim/nvidia/nemoretriever-page-elements-v2:1.5.0"
    "nvcr.io/nim/nvidia/nemoretriever-table-structure-v1:1.5.0"
    "nvcr.io/nvidia/blueprint/ingestor-server:2.3.0"
    "nvcr.io/nvidia/blueprint/rag-frontend:2.3.0"
    "nvcr.io/nvidia/blueprint/rag-server:2.3.0"
    "quay.io/coreos/etcd:v3.6.5"
    "redis/redis-stack:7.2.0-v18"
)

# Pull each image
for image in "${images[@]}"; do
    echo "Pulling image: $image"
    docker pull "$image"
done

echo "All images have been pulled."
