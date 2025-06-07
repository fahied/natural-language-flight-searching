import itertools
import random
from pathlib import Path
from typing import List, Tuple

import torch
from transformers import AutoTokenizer, AutoModelForTokenClassification, Trainer, TrainingArguments


def load_airport_names(file_path: Path) -> List[str]:
    """Load airport or city names from a text file (one per line)."""
    with file_path.open() as f:
        names = [line.strip() for line in f if line.strip()]
    return names


def generate_examples(origins: List[str], destinations: List[str], dates: List[str]) -> List[Tuple[str, List[str]]]:
    """Generate synthetic sentences and IOB entity tags."""
    examples = []
    for origin, destination, date in itertools.product(origins, destinations, dates):
        if origin == destination:
            continue
        text = f"I want to fly from {origin} to {destination} on {date}."
        tokens = text.split()
        tags = ["O"] * len(tokens)

        # Tag origin tokens
        origin_tokens = origin.split()
        for i, tok in enumerate(origin_tokens):
            idx = tokens.index(tok)
            tags[idx] = "B-ORIGIN" if i == 0 else "I-ORIGIN"

        # Tag destination tokens
        dest_tokens = destination.split()
        for i, tok in enumerate(dest_tokens):
            idx = tokens.index(tok)
            tags[idx] = "B-DEST" if i == 0 else "I-DEST"

        # Tag date tokens
        date_tokens = date.split()
        for i, tok in enumerate(date_tokens):
            idx = tokens.index(tok)
            tags[idx] = "B-DATE" if i == 0 else "I-DATE"

        examples.append((text, tags))
    random.shuffle(examples)
    return examples


def main():
    origins = ["Amsterdam", "Berlin", "Chicago", "New York"]
    destinations = ["London", "Paris", "San Francisco", "Tokyo"]
    dates = ["June 1", "June 2", "July 10", "August 5"]

    examples = generate_examples(origins, destinations, dates)

    tokenizer = AutoTokenizer.from_pretrained("bert-base-uncased")
    label_list = ["O", "B-ORIGIN", "I-ORIGIN", "B-DEST", "I-DEST", "B-DATE", "I-DATE"]
    label_to_id = {l: i for i, l in enumerate(label_list)}

    tokenized_inputs = []
    token_labels = []
    for text, tags in examples:
        tokenized = tokenizer(text.split(), is_split_into_words=True, truncation=True, padding="max_length", max_length=32)
        word_ids = tokenized.word_ids()
        labels = []
        prev_word_idx = None
        for word_idx in word_ids:
            if word_idx is None:
                labels.append(-100)
            elif word_idx != prev_word_idx:
                labels.append(label_to_id[tags[word_idx]])
            else:
                # Inside a word
                tag = tags[word_idx]
                if tag.startswith("B-"):
                    tag = tag.replace("B-", "I-")
                labels.append(label_to_id[tag])
            prev_word_idx = word_idx
        tokenized_inputs.append({k: torch.tensor(v) for k, v in tokenized.items()})
        token_labels.append(torch.tensor(labels))

    class FlightDataset(torch.utils.data.Dataset):
        def __len__(self):
            return len(tokenized_inputs)

        def __getitem__(self, idx):
            item = tokenized_inputs[idx]
            item['labels'] = token_labels[idx]
            return item

    model = AutoModelForTokenClassification.from_pretrained("bert-base-uncased", num_labels=len(label_list))

    training_args = TrainingArguments(
        output_dir="./model_output",
        per_device_train_batch_size=8,
        num_train_epochs=3,
        logging_steps=10,
        save_steps=50,
        learning_rate=5e-5,
    )

    trainer = Trainer(
        model=model,
        args=training_args,
        train_dataset=FlightDataset(),
    )

    trainer.train()
    trainer.save_model("./FlightsTagger")


if __name__ == "__main__":
    main()
