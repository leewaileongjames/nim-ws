https://docs.nvidia.com/nim/large-language-models/latest/peft.html


export LOCAL_PEFT_DIRECTORY=~/nim/loras
mkdir -p $LOCAL_PEFT_DIRECTORY
cd $LOCAL_PEFT_DIRECTORY

# downloading NeMo-format loras
ngc registry model download-version "nim/meta/llama3-8b-instruct-lora:nemo-math-v1"
ngc registry model download-version "nim/meta/llama3-8b-instruct-lora:nemo-squad-v1"


# Downloading vLLM-format LoRAs
ngc registry model download-version "nim/meta/llama3-8b-instruct-lora:hf-math-v1"
ngc registry model download-version "nim/meta/llama3-8b-instruct-lora:hf-squad-v1"

chmod -R 777 $LOCAL_PEFT_DIRECTORY