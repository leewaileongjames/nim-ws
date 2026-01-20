export NGC_API_KEY=""
echo "${NGC_API_KEY}" | docker login nvcr.io -u '$oauthtoken' --password-stdin

source deploy/compose/.env
source deploy/compose/perf_profile.env

mkdir -p ~/.cache/model-cache
export MODEL_DIRECTORY=~/.cache/model-cache

USERID=$(id -u) docker compose -f deploy/compose/nims.yaml up -d
docker compose -f deploy/compose/vectordb.yaml up -d
docker compose -f deploy/compose/docker-compose-ingestor-server.yaml up -d
USERID=$(id -u) docker compose -f deploy/compose/docker-compose-rag-server.yaml up -d
USERID=$(id -u) docker compose -f deploy/compose/docker-compose-rag-server.yaml up -d --build


down all rag containers
docker compose -f deploy/compose/docker-compose-ingestor-server.yaml down
docker compose -f deploy/compose/nims.yaml down
docker compose -f deploy/compose/nims.yaml --profile vlm down
docker compose -f deploy/compose/docker-compose-rag-server.yaml down
docker compose -f deploy/compose/vectordb.yaml down