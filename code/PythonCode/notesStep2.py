#!pip install -U transformers
#!pip install keras_bert

from transformers import BertTokenizer
import pandas as pd
import re
from progressbar import ProgressBar
import numpy as np
import os
import sys
import random
import tensorflow.keras as keras
import tensorflow as tf
import json

os.environ['TF_KERAS'] = '1'
from keras_bert import load_vocabulary, load_trained_model_from_checkpoint, Tokenizer, get_checkpoint_paths, get_model, extract_embeddings 

BERT_PRETRAINED_DIR = '../../BlueBERT'
config_file = os.path.join(BERT_PRETRAINED_DIR, 'bert_config.json')
checkpoint_file = os.path.join(BERT_PRETRAINED_DIR, 'bert_model.ckpt')
model = load_trained_model_from_checkpoint(config_file, checkpoint_file,seq_len=512,training=False)
pool_layer = keras.layers.GlobalAveragePooling1D(name='Pooling')(model.output)
model = keras.models.Model(inputs=model.inputs, outputs=pool_layer)
paths = get_checkpoint_paths(BERT_PRETRAINED_DIR)
token_dict = load_vocabulary(paths.vocab)
bertTokenizer = Tokenizer(token_dict)
preTrainedTokenizer = BertTokenizer.from_pretrained(BERT_PRETRAINED_DIR)

textFrame = pd.read_table("../../data/Processed/notes_finalNotesForProcess.csv",delimiter = ",")

SECTION_TITLES = re.compile(
    r'('
    r'ABDOMEN AND PELVIS|CLINICAL HISTORY|CLINICAL INDICATION|COMPARISON|COMPARISON STUDY DATE'
    r'|EXAM|EXAMINATION|FINDINGS|HISTORY|IMPRESSION|INDICATION'
    r'|MEDICAL CONDITION|PROCEDURE|REASON FOR EXAM|REASON FOR STUDY|REASON FOR THIS EXAMINATION'
    r'|TECHNIQUE'
    r'):|FINAL REPORT',
    re.I | re.M)


def pattern_repl(matchobj):
    """
    Return a replacement string to be used for match object
    """
    return ' '.rjust(len(matchobj.group(0)))


def find_end(text):
    """Find the end of the report."""
    ends = [len(text)]
    patterns = [
        re.compile(r'BY ELECTRONICALLY SIGNING THIS REPORT', re.I),
        re.compile(r'\n {3,}DR.', re.I),
        re.compile(r'[ ]{1,}RADLINE ', re.I),
        re.compile(r'.*electronically signed on', re.I),
        re.compile(r'M\[0KM\[0KM')
    ]
    for pattern in patterns:
        matchobj = pattern.search(text)
        if matchobj:
            ends.append(matchobj.start())
    return min(ends)


def split_heading(text):
    """Split the report into sections"""
    start = 0
    for matcher in SECTION_TITLES.finditer(text):
        # add last
        end = matcher.start()
        if end != start:
            section = text[start:end].strip()
            if section:
                yield section

        # add title
        start = end
        end = matcher.end()
        if end != start:
            section = text[start:end].strip()
            if section:
                yield section

        start = end

    # add last piece
    end = len(text)
    if start < end:
        section = text[start:end].strip()
        if section:
            yield section


def clean_text(text):
    """
    Clean text
    """

    # Replace [**Patterns**] with spaces.
    text = re.sub(r'\[\*\*.*?\*\*\]', pattern_repl, text)
    text = re.sub(r'\*\*.*?\*\*', pattern_repl, text)
    # Replace `_` with spaces.
    text = re.sub(r'_', ' ', text)

    start = 0
    end = find_end(text)
    new_text = ''
    if start > 0:
        new_text += ' ' * start
    new_text = text[start:end]

    # make sure the new text has the same length of old text.
    if len(text) - end > 0:
        new_text += ' ' * (len(text) - end)
    return new_text

testIndList = []
testSegList = []
pbar = ProgressBar()
for i,p in pbar(textFrame[0:100].iterrows()):
  textLine = p['text']
  tempList = []
  for sec in split_heading(clean_text(textLine)):
    temp = sec.lower()
    tokenized = preTrainedTokenizer.tokenize(temp)
    tempList.append(preTrainedTokenizer.convert_tokens_to_string(tokenized))
  textForInput = ( " ".join(tempList))
  textChunkList = []
  textChunkList.append(textForInput)
  for j in textChunkList:
    ind,seg = bertTokenizer.encode(first = j,max_len=512)
    testIndList.append(ind)
    testSegList.append(seg)

predicts = model.predict([np.array(testIndList), np.array(testSegList)],verbose=1)
temp = pd.DataFrame(predicts)
finalOutput = pd.concat([textFrame,temp],axis = 1)
finalOutputV2= finalOutput.drop(columns=["text"])

np.savetxt("../../data/Processed/notesInput.csv", finalOutputV2, delimiter=",",fmt='%f')