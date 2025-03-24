#!/bin/env python

import vec2text
import torch
import openai
import os
import dotenv
import math
from vec2text.models.model_utils import device

# Add a OPENAI_API_KEY=blah to a .env file
dotenv.load_dotenv()

print(device)

sentences = [
    "Jack Morris is a PhD student at Cornell Tech in New York City",
    "It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity",
]

print("Original strings:")
print(sentences)


def get_embeddings_openai(text_list, model="text-embedding-ada-002") -> torch.Tensor:
    # TODO: save off the values to avoid calls and allow offline use
    client = openai.OpenAI()
    outputs = []
    response = client.embeddings.create(
        input=text_list,
        model=model,
        encoding_format="float",  # override default base64 encoding...
    )

    for x in response.data:
        outputs.append(x.embedding)

    return torch.tensor(outputs)


embeddings = get_embeddings_openai(sentences)
print("Embeddings:")
print(embeddings)

corrector = vec2text.load_pretrained_corrector("text-embedding-ada-002")

# inverted_strings = vec2text.invert_strings(
#     sentences,
#     corrector=corrector,
# )
# print("Inverted strings")
# print(inverted_strings)


inverted_embeddings = vec2text.invert_embeddings(
    embeddings=embeddings,
    corrector=corrector,
)
print("Inverted embeddings:")
print(inverted_embeddings)
