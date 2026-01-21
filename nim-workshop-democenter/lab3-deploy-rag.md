# Lab 03 - Get Started With the NVIDIA Blueprints - Enterprise RAG Blueprint

Use the following documentation to get started quickly with the [NVIDIA RAG Blueprint](readme.md).
In this walkthrough you deploy the NVIDIA RAG Blueprint with Docker Compose for a single node deployment, and using self-hosted on-premises models.
For other deployment options, refer to [Deployment Options](readme.md#deployment-options-for-rag-blueprint).

:::{tip}
If you want to run the RAG Blueprint with [NVIDIA AI Workbench](https://docs.nvidia.com/ai-workbench/user-guide/latest/overview/introduction.html), use [Quickstart for NVIDIA AI Workbench](https://github.com/NVIDIA-AI-Blueprints/rag/blob/main/deploy/workbench/README.md).
:::


## Prerequisites

1. [Get an API Key](api-key.md).

2. Install Docker Engine. For more information, see [Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

3. Install Docker Compose. For more information, see [install the Compose plugin](https://docs.docker.com/compose/install/linux/).

   a. Ensure the Docker Compose plugin version is 2.29.1 or later.

   b. After you get the Docker Compose plugin installed, run `docker compose version` to confirm.

4. To pull images required by the blueprint from NGC, you must first authenticate Docker with nvcr.io. Use the NGC API Key you created in the first step.

   ```bash
   export NGC_API_KEY="nvapi-..."
   echo "${NGC_API_KEY}" | docker login nvcr.io -u '$oauthtoken' --password-stdin
   ```

5. Containers that are enabled with GPU acceleration, such as Milvus and NVIDIA NIMS, deployed on-prem. To configure Docker for GPU-accelerated containers, install the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

6. Ensure you meet [the hardware requirements](./support-matrix.md).


## Start services using self-hosted on-premises models

Use the following procedure to start all containers needed for this blueprint.

1. Create a directory to cache the models and export the path to the cache as an environment variable.

   ```bash
   mkdir -p ~/.cache/model-cache
   export MODEL_DIRECTORY=~/.cache/model-cache
   ```


2. Export all the required environment variables to use on-prem models.

   ```bash
   source deploy/compose/.env
   ```

3. Set the `NIM_MODEL_PROFILE` to be used for the LLM NIM model:

   ```bash
   export NIM_MODEL_PROFILE=5811750e70b7e9f340f4d670c72fcbd5282e254aeb31f62fd4f937cfb9361007
   ```


4. Start all required NIMs by running the following code.

   :::{warning}
   Do not attempt this step unless you have completed the previous steps.
   :::

   ```bash
   USERID=$(id -u) docker compose -f deploy/compose/nims.yaml up -d
   ```

   The NIM LLM service can take 30 mins to start for the first time as the model is downloaded and cached. Subsequent deployments can take 2-5 minutes, depending on the GPU profile.

   :::{tip}
   The models are downloaded and cached in the path specified by `MODEL_DIRECTORY`.
   :::


5. Check the status of the deployment by running the following code. Wait until all services are up and the `nemoretriever-ranking-ms`, `nemoretriever-embedding-ms` and `nim-llm-ms`  NIMs are in healthy state before proceeding further.

     ```bash
     watch -n 2 'docker ps --format "table {{.Names}}\t{{.Status}}"'
     ```
    Your output should look similar to the following.

     ```output
        NAMES                                   STATUS

        nemoretriever-ranking-ms                Up 14 minutes (healthy)
        compose-page-elements-1                 Up 14 minutes
        compose-paddle-1                        Up 14 minutes
        compose-graphic-elements-1              Up 14 minutes
        compose-table-structure-1               Up 14 minutes
        nemoretriever-embedding-ms              Up 14 minutes (healthy)
        nim-llm-ms                              Up 14 minutes (healthy)
     ```


6. Start the vector db containers from the repo root.

   ```bash
   docker compose -f deploy/compose/vectordb.yaml up -d
   ```


7. Start the ingestion containers from the repo root. This pulls the prebuilt containers from NGC and deploys them on your system.

   ```bash
   docker compose -f deploy/compose/docker-compose-ingestor-server.yaml up -d
   ```

   You can check the status of the ingestor-server and running the following code.

   ```bash
   curl -X 'GET' 'http://localhost:8082/v1/health?check_dependencies=true' -H 'accept: application/json' | jq
   ```

    You should see output similar to the following.

    ```bash
    {
        "message": "Service is up.",
        "databases": [
            ...
        ],
        "object_storage": [
            ...
        ],
        "nim": [
            {
                "service": "Embeddings",
                "status": "healthy",
                ...
            },
            {
                "service": "Summary LLM",
                "status": "healthy",
                ...
            }
        ],
        "processing": [
            {
                "service": "NV-Ingest",
                "status": "healthy",
                ...
            }
        ],
        "task_management": [
            {
                "service": "Redis",
                "status": "healthy",
                ...
            }
        ]
    }
    ```


8. Start the RAG containers from the repo root. This pulls the prebuilt containers from NGC and deploys them on your system.

    ```bash
    docker compose -f deploy/compose/docker-compose-rag-server.yaml up -d
    ```

    You can check the status of the rag-server by running the following code.

    ```bash
    curl -X 'GET' 'http://localhost:8081/v1/health?check_dependencies=true' -H 'accept: application/json' | jq
    ```

    You should see output similar to the following.

    ```bash
    {
        "message": "Service is up.",
        "databases": [
            ...
        ],
        "object_storage": [
            ...
        ],
        "nim": [
        {
            "service": "LLM",
            "status": "healthy",
            ...
        },
        {
            "service": "Embeddings",
            "status": "healthy",
            ...
        },
        {
            "service": "Ranking",
            "status": "healthy",
            ...
        }
      ]
    }
    ```


9. Check the status of the deployment by running the following code.

    ```bash
    docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}"
    ```

    You should see output similar to the following. Confirm all the following containers are running.

    ```output
    NAMES                                   STATUS
    compose-nv-ingest-ms-runtime-1          Up 5 minutes (healthy)
    ingestor-server                         Up 5 minutes
    compose-redis-1                         Up 5 minutes
    rag-frontend                            Up 9 minutes
    rag-server                              Up 9 minutes
    milvus-standalone                       Up 36 minutes
    milvus-minio                            Up 35 minutes (healthy)
    milvus-etcd                             Up 35 minutes (healthy)
    nemoretriever-ranking-ms                Up 38 minutes (healthy)
    compose-page-elements-1                 Up 38 minutes
    compose-paddle-1                        Up 38 minutes
    compose-graphic-elements-1              Up 38 minutes
    compose-table-structure-1               Up 38 minutes
    nemoretriever-embedding-ms              Up 38 minutes (healthy)
    nim-llm-ms                              Up 38 minutes (healthy)
    ```



## Experiment with the Web User Interface

After the RAG Blueprint is deployed, you can use the RAG UI to start experimenting with it.

1. Open a web browser and access the RAG UI. You can start experimenting by uploading docs and asking questions. For details, see [User Interface for NVIDIA RAG Blueprint](user-interface.md).


## Shut down services

1. To stop all running services, run the following code.

    ```bash
    docker compose -f deploy/compose/docker-compose-ingestor-server.yaml down
    docker compose -f deploy/compose/nims.yaml down
    docker compose -f deploy/compose/docker-compose-rag-server.yaml down
    docker compose -f deploy/compose/vectordb.yaml down
    ```