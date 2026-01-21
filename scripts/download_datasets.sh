import os
import subprocess
import requests

def safe_download(url, path):
    if os.path.exists(path):
        return print(f"Déjà: {path}")
    try:
        r = requests.get(url)
        with open(path, 'wb') as f:
            f.write(r.content)
        print(f"OK: {path}")
    except:
        print(f"Erreur: {url}")

def safe_git_clone(url, folder):
    if os.path.exists(folder):
        return print(f"Déjà: {folder}")
    try:
        subprocess.run(['git', 'clone', url, folder], check=True)
        print(f"OK: {folder}")
    except:
        print(f"Erreur clone: {url}")

os.makedirs('datasets', exist_ok=True)
os.chdir('datasets')

safe_git_clone('https://github.com/suzgunmirac/BIG-Bench-Hard.git', 'bbh')
safe_git_clone('https://github.com/xlang-ai/Spider2.git', 'spider2')
safe_download('https://github.com/xlang-ai/Spider2/raw/main/spider2-lite/spider2-lite.jsonl', 'spider2/spider2-lite.jsonl')
safe_download('https://github.com/xlang-ai/Spider2/raw/main/spider2-snow/spider2-snow.jsonl', 'spider2/spider2-snow.jsonl')
safe_download('http://curtis.ml.cmu.edu/datasets/hotpot/hotpot_train_v1.1.json', 'hotpot_train_v1.1.json')
safe_download('http://curtis.ml.cmu.edu/datasets/hotpot/hotpot_dev_distractor_v1.json', 'hotpot_dev_distractor_v1.json')
safe_git_clone('https://github.com/StonyBrookNLP/musique.git', 'musique')
try:
    subprocess.run(['bash', 'musique/download_data.sh'], check=True)
except:
    print("Erreur MuSiQue")
safe_git_clone('https://github.com/eladsegal/strategyqa.git', 'strategyqa')
safe_download('https://storage.googleapis.com/strategyqa_data/strategyqa_train.json', 'strategyqa/strategyqa_train.json')
safe_download('https://msmarco.blob.core.windows.net/msmarco/train_v2.1.json.gz', 'train_v2.1.json.gz')
try:
    subprocess.run(['gunzip', 'train_v2.1.json.gz'], check=True)
except:
    print("Erreur MS MARCO")
safe_git_clone('https://github.com/wenhuchen/Table-Fact-Checking.git', 'tabfact')
safe_download('https://github.com/wenhuchen/Table-Fact-Checking/raw/master/tokenized_data/train_examples.json', 'tabfact/train_examples.json')
safe_git_clone('https://github.com/openai/grade-school-math.git', 'gsm8k')
safe_download('https://github.com/openai/grade-school-math/raw/master/dataset/GSM8K/train.jsonl', 'gsm8k/train.jsonl')
safe_download('https://rajpurkar.github.io/SQuAD-explorer/dataset/train-v2.0.json', 'squad_train-v2.0.json')
safe_download('https://rajpurkar.github.io/SQuAD-explorer/dataset/dev-v2.0.json', 'squad_dev-v2.0.json')
safe_git_clone('https://github.com/pubmedqa/pubmedqa.git', 'pubmedqa')
safe_download('https://drive.google.com/uc?id=1RsGLINVce-0GsDkCLDuLZmoLuzfmoCuQ', 'pubmedqa/ori_pqau.json')
safe_download('https://huggingface.co/datasets/MoE-UNC/wikihop/resolve/main/data/train-00000-of-00001.parquet', 'wikihop_train.parquet')
safe_git_clone('https://github.com/tdiggelm/climate-fever-dataset.git', 'climatefever')
safe_download('https://huggingface.co/datasets/tdiggelm/climate_fever/resolve/main/data/climate_fever.jsonl', 'climatefever/climate_fever.jsonl')
safe_download('https://huggingface.co/datasets/Shitao/bge-reranker-data/resolve/main/train.jsonl', 'reranker/train.jsonl')

os.chdir('..')
print("Fin. Vérifiez datasets/.")

