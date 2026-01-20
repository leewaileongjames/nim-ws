# NIM Model Setup and GenAI-Perf Benchmark

This guide will walk you through setting up a Llama 3.8B Instruct model on NIM and running a GenAI-Perf benchmark using Triton Server.

## 1. Running the NIM Model

### Step 1: Set Up Local Nim Cache

First, set up a local cache directory for NIM.

```bash
export LOCAL_NIM_CACHE=~/.cache/nim
mkdir -p "$LOCAL_NIM_CACHE"
```

### Step 2: List Available Model Profiles

You can list the available model profiles for the desired model using the following command.

```bash
docker run --rm --runtime=nvidia --gpus=all \
    -e NGC_API_KEY=$NGC_API_KEY \
    nvcr.io/nim/meta/llama3-8b-instruct:latest \
    list-model-profiles
```
### Step 3: Start the Model Server

Run the Llama 3.8B Instruct model on NIM in detached mode.

```bash
docker run -itd --name=llama3-8b-instruct --rm \
    --gpus all \
    --shm-size=16GB \
    -e NGC_API_KEY \
    -v "$LOCAL_NIM_CACHE:/opt/nim/.cache" \
    -u $(id -u) \
    -p 8000:8000 \
    nvcr.io/nim/meta/llama3-8b-instruct:latest
```

### Step 4: Test the Model Endpoint

To verify that the model server is running, send a `GET` request to list the available models.

```bash
curl -s -X GET 'http://0.0.0.0:8000/v1/models' | jq
```

### Step 5: Test Model Response

You can now test the model by sending a `POST` request with a sample input.

```bash
curl -s -X 'POST' \
'http://0.0.0.0:8000/v1/chat/completions' \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
-d '{
    "model": "meta/llama3-8b-instruct",
    "messages": [{"role":"user", "content":"Write a limerick about the wonders of GPU computing."}],
    "max_tokens": 64
}' | jq
```

## 2. Running GenAI-Perf Benchmark

### Step 6: Copy the Tokenizer for Llama 3.1 8B Instruct

Copy the tokenizer for the Llama 3.1 8B Instruct model.

```bash
export HF_TOKENIZER=~/tokenizer
mkdir -p $HF_TOKENIZER
cp -ar ~/.cache/huggingface/hub $HF_TOKENIZER
```

### Step 7: Export Variables and Run Triton Server

Set the environment variables and run the Triton Server.

```bash
export RELEASE="24.06" # Use the latest releases in yy.mm format
export WORKDIR=~/genai-perf
mkdir -p "$WORKDIR"
docker run -it --rm --net=host --gpus=all \
    -v $WORKDIR:/workdir \
    -v $HF_TOKENIZER:/root/.cache/huggingface \
    nvcr.io/nvidia/tritonserver:${RELEASE}-py3-sdk
```

### Step 8: Run GenAI-Perf Benchmark

Run the GenAI-Perf benchmark script on the Triton Server. Allow approximately 30 seconds for the script to complete.

```bash
export INPUT_SEQUENCE_LENGTH=200
export INPUT_SEQUENCE_STD=10
export OUTPUT_SEQUENCE_LENGTH=200
export CONCURRENCY=10
export MODEL=meta/llama3-8b-instruct

cd /workdir
genai-perf \
    -m $MODEL \
    --endpoint-type chat \
    --service-kind openai \
    --streaming \
    -u localhost:8000 \
    --synthetic-input-tokens-mean $INPUT_SEQUENCE_LENGTH \
    --synthetic-input-tokens-stddev $INPUT_SEQUENCE_STD \
    --concurrency $CONCURRENCY \
    --output-tokens-mean $OUTPUT_SEQUENCE_LENGTH \
    --extra-inputs max_tokens:$OUTPUT_SEQUENCE_LENGTH \
    --extra-inputs min_tokens:$OUTPUT_SEQUENCE_LENGTH \
    --extra-inputs ignore_eos:true \
    --tokenizer meta-llama/Meta-Llama-3-8B-Instruct \
    -- \
    -v \
    --max-threads=256
```

---

## Notes:

* Ensure that your Docker installation supports GPU and that NVIDIA drivers and CUDA are properly installed on your machine.
* The model server and benchmark tool assume that the necessary ports are open (in this case, `8000` for HTTP).
* Modify the environment variables and paths as needed for your specific setup.

---
