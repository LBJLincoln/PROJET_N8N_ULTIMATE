import json

def compute_accuracy(predictions, references):
    correct = 0
    for p, r in zip(predictions, references):
        if p == r:
            correct += 1
    return correct / len(predictions) if predictions else 0

def compute_f1(predictions, references):
    def f1_one(p, r):
        p_tokens = set(str(p).split())
        r_tokens = set(str(r).split())
        if not p_tokens or not r_tokens:
            return 0
        tp = len(p_tokens & r_tokens)
        prec = tp / len(p_tokens)
        rec = tp / len(r_tokens)
        return 2 * prec * rec / (prec + rec) if prec + rec else 0

    scores = [f1_one(p, r) for p, r in zip(predictions, references)]
    return sum(scores) / len(scores) if scores else 0

def save_metrics(path, metrics):
    with open(path, "w") as f:
        json.dump(metrics, f, indent=2)

def load_json(path):
    with open(path, "r") as f:
        return json.load(f)

if __name__ == "__main__":
    predictions = ["Paris", "Berlin"]
    references = ["Paris", "Berlin"]
    metrics = {
        "accuracy": compute_accuracy(predictions, references),
        "f1": compute_f1(predictions, references)
    }
    print(metrics)
