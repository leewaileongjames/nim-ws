## One-Click setup for Democenter Lab
Make sure you export the necessary environment variables before running the script:
```
export NGC_API_KEY=<your_ngc_api_key>
export HF_TOKEN=<your_huggingface_api_token>
```

Run the script:
```
sudo -E bash ./setup_script.sh
```

This will execute all the steps in sequence, ensuring the setup process is fully automated with a one-click execution.


## Manual Setup

### Pre-setup
1. Clean current lab environment
```
docker system prune -a
```
```
docker volume prune -a
```
```
sudo rm -rf app_char_rag.py nvidia-workbench/* Downloads/*
```

### 1. Pull images and install common libraries
1. Login to Docker NGC

```
export NGC_API_KEY=<API_KEY_HERE>
echo "${NGC_API_KEY}" | docker login nvcr.io -u '$oauthtoken' --password-stdin
```
2. Pull images required for NIM workshop:

```
export IMG_NAME=nvcr.io/nim/meta/llama3-8b-instruct:1.0.3
export TRITON_IMG_NAME=nvcr.io/nvidia/tritonserver:24.06-py3-sdk
docker image pull $IMG_NAME
docker image pull $TRITON_IMG_NAME
```

3. Install common libraries
```
sudo apt install jq -y
sudo apt install zip unzip -y
```

### 2. Download model caches
1. List model cache
```
export IMG_NAME=nvcr.io/nim/meta/llama3-8b-instruct:latest
export LOCAL_NIM_CACHE=~/.cache/nim
sudo mkdir -p "$LOCAL_NIM_CACHE"
sudo chmod -R 777 "$LOCAL_NIM_CACHE"
docker run --rm --runtime=nvidia --gpus=all \
	-e NGC_API_KEY=$NGC_API_KEY \
	$IMG_NAME \
	list-model-profiles
```

2. Download normal NIM model cache profile
```
docker run -it --rm --gpus all \
	-e NGC_API_KEY \
	-v $LOCAL_NIM_CACHE:/opt/nim/.cache \
    $IMG_NAME \
    download-to-cache \
    -p 8835c31752fbc67ef658b20a9f78e056914fdef0660206d82f252d62fd96064d
```
3. Download LoRA model cache
```
docker run -it --rm --gpus all \
	-e NGC_API_KEY \
	-v $LOCAL_NIM_CACHE:/opt/nim/.cache \
    $IMG_NAME \
    download-to-cache \
    -p 8d3824f766182a754159e88ad5a0bd465b1b4cf69ecf80bd6d6833753e945740
```

### 3. Download tokenizers
1. Prepare Huggingface API Token (ensure it has read access granted to llama3 models)
2. Download HF pip library
```
pip install -U "huggingface_hub"
```
3. HF Login
```
export HF_TOKEN=<HF_API_KEY_HERE>
hf auth login
```
4. Download tokenizer into `~/tokenizer/hub/`
```
mkdir -p ~/tokenizer/hub/
hf download meta-llama/Meta-Llama-3-8B-Instruct --include "*.json" --cache-dir ~/tokenizer/hub/
sudo chmod -R 777 ~/tokenizer/hub/
```
### 4. Download Adapters
Reference
https://docs.nvidia.com/nim/large-language-models/latest/peft.html

1. Create directory to store LoRA adapters under `~/nim/loras`:
```
export LOCAL_PEFT_DIRECTORY=~/nim/loras
mkdir -p $LOCAL_PEFT_DIRECTORY
```
2. Copy over Adapters from NGC 
```
cd ./prep-democenter
cp -R llama3-8b-instruct-lora_vhf-math-v1 llama3-8b-instruct-lora_vhf-squad-v1 llama3-8b-instruct-lora_vnemo-math-v1 llama3-8b-instruct-lora_vnemo-squad-v1 $LOCAL_PEFT_DIRECTORY
chmod -R 777 $LOCAL_PEFT_DIRECTORY
```