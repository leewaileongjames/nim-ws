# 🧪 Lab Guide 02: Running NVIDIA NIM with LoRA (Low-Rank Adaptation)

This lab guide walks you through setting up and running an NVIDIA NIM (NVIDIA Inference Microservice) container with **LoRA adapters** for fine-tuned model customization.
You’ll learn how to configure the environment, launch the container, and query LoRA-enabled models.

---

## 🧩 Prerequisites

Before starting, ensure you have the following:

* **Docker** (with NVIDIA Container Toolkit installed)
* **NGC API key** (for accessing NVIDIA’s NGC registry)
* **GPU-enabled system**
* **LoRA adapter files**

---

## Step 1: Stop All Running Containers

Before starting a new container, it’s best to stop any previously running containers to avoid port conflicts or GPU contention.

```bash
docker stop $(docker ps -q)
```

This command stops all running Docker containers.
If no containers are running, you’ll see a harmless error message.

---

## Step 2: Set Up the LoRA Directory

Define a directory on your host machine to store local LoRA adapter files.

```bash
export LOCAL_PEFT_DIRECTORY=~/nim/loras
mkdir -p $LOCAL_PEFT_DIRECTORY
ls $LOCAL_PEFT_DIRECTORY
```

**Explanation:**

* `LOCAL_PEFT_DIRECTORY` points to where your LoRA weights/adapters will be stored.
* `mkdir -p` ensures the directory exists (creates it if missing).
* The `ls` command confirms it’s created correctly.

---

## Step 3: Configure NIM Runtime Variables

Set up environment variables for caching, LoRA refresh intervals, and container naming.

```bash
export LOCAL_NIM_CACHE=~/.cache/nim
mkdir -p "$LOCAL_NIM_CACHE"

export NIM_PEFT_REFRESH_INTERVAL=3600      # Refresh LoRA adapters every 1 hour
export NIM_PEFT_SOURCE=/tmp/loras          # Inside-container LoRA path
export CONTAINER_NAME=llama3-8b-instruct   # Name of the NIM container
```

**Explanation:**

* `LOCAL_NIM_CACHE` → Local cache directory for NIM models and metadata.
* `NIM_PEFT_REFRESH_INTERVAL` → Automatically refreshes LoRA adapters every 3600 seconds.
* `NIM_PEFT_SOURCE` → Directory inside the container that maps to LoRA files.
* `CONTAINER_NAME` → Container name for easier management.

---

## Step 4: Run NIM with LoRA Support

Now we can start running an instance of NIM with LoRA support profile:

```bash
docker run -itd --rm --name=$CONTAINER_NAME \
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
    nvcr.io/nim/meta/llama3-8b-instruct:1.0.3
```

**Explanation:**

* `--gpus all` enables GPU acceleration.
* `--shm-size=16GB` ensures sufficient shared memory for large models.
* `-v` mounts host directories into the container.
* `-e` sets environment variables for NIM configuration.
* `-p 8000:8000` exposes the inference API on port 8000.

Once launched, the container will begin serving the NIM API.

---

## Step 5: List Available LoRA Adapters

Check which LoRA adapters are available and ready for inference.

```bash
curl -X GET 'http://0.0.0.0:8000/v1/models' | jq
```

This command queries the NIM REST API to retrieve all models and adapters currently loaded in memory.

---

## Step 6: Query a LoRA-Enhanced Model

You can now send a test prompt to the model.
This example uses a math reasoning LoRA adapter (`lora_vhf-math-v1`):

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
---

## ✅ Summary

In this lab, you have successfully:

* Set up directories for LoRA storage and caching.
* Configured environment variables for NIM runtime.
* Launched the NIM container with GPU support.
* Queried and tested a LoRA-enhanced model through the REST API.

---

Would you like me to format this as a **PDF lab guide** (with headings, code blocks, and notes for printing/distribution)?
