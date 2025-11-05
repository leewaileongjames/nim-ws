pip install -U "huggingface_hub"

hf auth login

hf download meta-llama/Meta-Llama-3-8B-Instruct --include "*.json" 