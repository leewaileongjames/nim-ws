# stop all containers
```bash
docker stop $(docker ps -q)
```

# setup lora path
```bash
export LOCAL_PEFT_DIRECTORY=~/nim/loras
mkdir -p $LOCAL_PEFT_DIRECTORY
ls $LOCAL_PEFT_DIRECTORY
```


# set configurations for NIM  with LoRA
```bash
export LOCAL_NIM_CACHE=~/.cache/nim
mkdir -p "$LOCAL_NIM_CACHE"

export NIM_PEFT_REFRESH_INTERVAL=3600

export NIM_PEFT_SOURCE=/tmp/loras
export CONTAINER_NAME=llama3-8b-instruct
```

# Run NIM with LoRA
```bash
docker run -it --rm --name=$CONTAINER_NAME \
    --runtime=nvidia \
    --gpus all \
    --shm-size=16GB \
    -e NGC_API_KEY=$NGC_API_KEY \
    -e NIM_PEFT_SOURCE \
    -e NIM_PEFT_REFRESH_INTERVAL \
    -v $LOCAL_NIM_CACHE:/opt/nim/.cache \
    -v $LOCAL_PEFT_DIRECTORY:$NIM_PEFT_SOURCE \
    -u $(id -u):$(id -g) \
    -p 8000:8000 \
    nvcr.io/nim/meta/llama3-8b-instruct:latest
```
# See list of availabble LoRA adapters
```bash
curl -X GET 'http://0.0.0.0:8000/v1/models' | jq
```

# Query LoRA Model
```bash
curl -X 'POST' \
  'http://0.0.0.0:8000/v1/completions' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
    "model": "llama3-8b-instruct-lora_vhf-math-v1",
    "prompt": "John buys 10 packs of magic cards. Each pack has 20 cards and 1/4 of those cards are uncommon. How many uncommon cards did he get?",
    "max_tokens": 128
  }' | jq
  ```