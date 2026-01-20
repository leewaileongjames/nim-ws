https://docs.nvidia.com/nim/large-language-models/latest/peft.html


export LOCAL_PEFT_DIRECTORY=~/nim/loras
mkdir -p $LOCAL_PEFT_DIRECTORY

cp -R llama3-8b-instruct-lora_vhf-math-v1 llama3-8b-instruct-lora_vhf-squad-v1 llama3-8b-instruct-lora_vnemo-math-v1 llama3-8b-instruct-lora_vnemo-squad-v1 $LOCAL_PEFT_DIRECTORY

chmod -R 777 $LOCAL_PEFT_DIRECTORY

OR

## Download Adapters
Reference
https://docs.nvidia.com/nim/large-language-models/latest/peft.html

1. Install and setup NGC over at https://org.ngc.nvidia.com/setup/installers/cli:
```
wget --content-disposition https://api.ngc.nvidia.com/v2/resources/nvidia/ngc-apps/ngc_cli/versions/4.10.0/files/ngccli_linux.zip -O ngccli_linux.zip && unzip ngccli_linux.zip
```
```
chmod u+x ngc-cli/ngc
echo "export PATH=\"\$PATH:$(pwd)/ngc-cli\"" >> ~/.bash_profile && source ~/.bash_profile
```
```
ngc config set
``` 

2. Create directory to store LoRA adapters under `~/nim/loras`:
```
export LOCAL_PEFT_DIRECTORY=~/nim/loras
mkdir -p $LOCAL_PEFT_DIRECTORY
```
3. Download Adapters from NGC 
```
# downloading NeMo-format loras
ngc registry model download-version "nim/meta/llama3-8b-instruct-lora:nemo-math-v1"
ngc registry model download-version "nim/meta/llama3-8b-instruct-lora:nemo-squad-v1"


# Downloading vLLM-format LoRAs
ngc registry model download-version "nim/meta/llama3-8b-instruct-lora:hf-math-v1"
ngc registry model download-version "nim/meta/llama3-8b-instruct-lora:hf-squad-v1"

cp -R llama3-8b-instruct-lora_vhf-math-v1 llama3-8b-instruct-lora_vhf-squad-v1 llama3-8b-instruct-lora_vnemo-math-v1 llama3-8b-instruct-lora_vnemo-squad-v1 $LOCAL_PEFT_DIRECTORY

chmod -R 777 $LOCAL_PEFT_DIRECTORY
```