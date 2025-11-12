# 3. Running RAG AI Blueprint

mkdir -p ~/.cache/nim
export MODEL_DIRECTORY=~/.cache/nim
sudo chmod -R 777 "$MODEL_DIRECTORY"

source deploy/compose/.env
source deploy/compose/perf_profile.env

## Start RAG services
export NGC_API_KEY=<key-here>
USERID=$(id -u) docker compose -f deploy/compose/nims.yaml up -d
docker compose -f deploy/compose/vectordb.yaml up -d
docker compose -f deploy/compose/docker-compose-ingestor-server.yaml up -d
USERID=$(id -u) docker compose -f deploy/compose/docker-compose-rag-server.yaml up -d --build

docker compose -f deploy/compose/docker-compose-rag-server.yaml up -d

## Stop RAG services
docker compose -f deploy/compose/docker-compose-ingestor-server.yaml down
docker compose -f deploy/compose/nims.yaml down
docker compose -f deploy/compose/nims.yaml --profile vlm down
docker compose -f deploy/compose/docker-compose-rag-server.yaml down
docker compose -f deploy/compose/vectordb.yaml down