#!/usr/bin/env python
# coding: utf-8

# In[35]:


# Keystroke recognition


# In[36]:


import sys
import os
import random

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
#get_ipython().run_line_magic('matplotlib', 'inline')

from sklearn.metrics import classification_report, confusion_matrix
from sklearn.model_selection import train_test_split
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import accuracy_score
from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import MinMaxScaler

from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
# For ANN
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
import pickle

from io import StringIO

pd.options.display.max_rows = 30
pd.options.display.max_columns = 30


# In[37]:


impostor_file_name = str(sys.argv[1])
keys = ["'q'", "'w'", "'e'", "'r'", "'t'", "'y'", "'u'", "'i'", "'o'", "'p'", "'a'", "'s'", "'d'", "'f'", "'g'", "'h'", "'j'", "'k'", "'l'", "'z'", "'x'", "'c'", "'v'", "'b'", "'n'", "'m'"]


# In[38]:


class KeyboardAction:
    def __init__(self, action_time, key_type, action_type):
        self.action_time = action_time
        self.key_type = key_type
        self.action_type = action_type


# In[39]:


def get_keyboard_actions(lines):
    keyboard_actions = []

    for line in lines:
        values = line.split()
        keyboard_actions.append(KeyboardAction(float(values[0]), values[1], values[2]))
    return keyboard_actions


# In[40]:


class UserAction:
    def __init__(self, key_type, duration, press_time):
        self.key_type = key_type
        self.duration = duration
        self.press_time = press_time
        self.previous_time = None
        self.next_time = None
    
    def set_previous(self, previous_time):
        self.previous_time = previous_time
        
    def set_next(self, next_time):
        self.next_time = next_time
        
    def set_user_id(self, user_id):
        self.user_id = user_id


# In[41]:


def get_user_actions(keyboard_actions):

    currently_pressed = {}
    user_actions = []

    for action in keyboard_actions:
        if action.action_type == "PRESS":
            if(action.key_type not in currently_pressed):
                currently_pressed[action.key_type] = action.action_time
        elif action.action_type == "RELEASE":
            if action.key_type in currently_pressed:
                duration = action.action_time - currently_pressed[action.key_type]
                user_actions.append(UserAction(action.key_type, duration, currently_pressed[action.key_type]))
                currently_pressed.pop(action.key_type, None)
        #else:
        #    print(f"Unexpected action: {action.action_type}")
            
    user_actions.sort(key=lambda x: x.press_time)
    for i in range(1, len(user_actions) - 2):
        user_actions[i].set_previous(user_actions[i-1].press_time)
        user_actions[i].set_next(user_actions[i+1].press_time)
    
    return user_actions


# In[42]:


def get_user_actions_from_file(file_name):
    with open(file_name, encoding="ISO-8859-1") as f:
        lines = f.readlines()
        
    keyboard_actions = get_keyboard_actions(lines)
    user_actions = get_user_actions(keyboard_actions)
    for uaction in user_actions:
        uaction.set_user_id(users_to_id[file_name.split('_')[1]])
    return user_actions


# In[43]:


def get_csvs_from_user_actions(user_actions):
    csvs = dict.fromkeys(keys, '')

    for key, value in csvs.items():
        csvs[key] = 'subject,duration,prev_time,next_time'

    for uaction in user_actions:
        key = uaction.key_type.lower()
        if key in keys:
            from_previous = uaction.press_time - uaction.previous_time if uaction.previous_time is not None else None
            to_next = uaction.next_time - uaction.press_time if uaction.next_time is not None else None

            if uaction.duration is not None and from_previous is not None and to_next is not None and uaction.duration < 1.0 and from_previous < 1.0 and to_next < 1.0:
                csvs[key] = csvs[key] + f'\n{uaction.user_id},{uaction.duration},{from_previous},{to_next}'
    return csvs


# In[44]:


pylogger_files = []
for file in os.listdir():
    if file.startswith('pylogger') and file.endswith('.log'):
        pylogger_files.append(file)

users = set()
for file_name in pylogger_files:
    if file_name is not impostor_file_name:
        splitted = file_name.split('_')
        users.add(splitted[1])

ids = list(range(len(users)))
users_to_id = dict(zip(users,ids))

pylogger_files = []
for file in os.listdir():
    if file.startswith('pylogger') and file.endswith('.log') and file is not impostor_file_name:
        pylogger_files.append(file)

all_user_actions = []
for file_name in pylogger_files:
    all_user_actions.append(get_user_actions_from_file(file_name))
all_user_actions = sum(all_user_actions, [])
csvs = get_csvs_from_user_actions(all_user_actions)

uactions_imp = get_user_actions_from_file(impostor_file_name)
csv_imp = get_csvs_from_user_actions(uactions_imp)


# In[46]:


dfs = {}
dfs_imp = {}
for key in keys:
    TESTDATA = StringIO(f"""{csvs[key]}""")
    dfs[key] = pd.read_csv(TESTDATA, sep=",")
    
    TESTDATA_imp = StringIO(f"""{csv_imp[key]}""")
    dfs_imp[key] = pd.read_csv(TESTDATA_imp, sep=",")


# In[47]:


# Split into attributes and labels
Xs = {}
ys = {}
Xs_imp = {}
ys_imp = {}
for key in keys:
    Xs[key] = dfs[key].drop('subject', axis=1)
    ys[key] = dfs[key]['subject']
    Xs_imp[key] = dfs_imp[key].drop('subject', axis=1)
    ys_imp[key] = dfs_imp[key]['subject']


# In[48]:


skfs = {}
svm_scores = {}
knn_scores = {}
svc_ms = {}

for key in keys:
    svm_scores[key] = []
    knn_scores[key] = []

    skfs[key] = StratifiedKFold(n_splits=4, random_state=101, shuffle=True)
    skfs[key].get_n_splits(Xs, ys)
    
    if len(Xs[key]) >= 3 and len(set(ys[key])) >= 3:
        for train_index, test_index in skfs[key].split(Xs[key], ys[key]):
            X_train, X_test = Xs[key].loc[train_index], Xs[key].loc[test_index]
            y_train, y_test = ys[key][train_index], ys[key][test_index]

            svc_m = SVC().fit(X_train, y_train)
            svc_ms[key] = svc_m
            knn_m = KNeighborsClassifier(n_neighbors=5).fit(X_train, y_train)

            svm_scores[key].append(accuracy_score(y_test, svc_m.predict(X_test)))
            knn_scores[key].append(accuracy_score(y_test, knn_m.predict(X_test)))


# In[49]:


avg_keys = {}
for key, values in knn_scores.items():
    amount = 0
    ssum = 0
    for value in values:
        ssum = ssum + float(value)
        amount = amount + 1.
    if amount != 0:
        avg_keys[key] = float(ssum) / float(amount)
        
avg_keys = dict((k, v) for k, v in avg_keys.items() if v >= 0.55)
score_amount = 0.
score_sum = 0.
for key, values in svm_scores.items():
    if key in avg_keys:
        for value in values:
            score_sum = score_sum + float(value)
            score_amount = score_amount + 1.
            
avg = float(score_sum) / float(score_amount)
score_amount = 0.
score_sum = 0.
for key, values in knn_scores.items():
    if key in avg_keys:
        for value in values:
            score_sum = score_sum + float(value)
            score_amount = score_amount + 1.
avg = float(score_sum) / float(score_amount)


# In[50]:


def get_prediction_for_user(user_id):
    predicted_impostor = 0
    predicted_not_impostor = 0
    for key in avg_keys:    
        for row in csv_imp[key].split('\n'):
            if row != 'subject,duration,prev_time,next_time':
                rowValues = row.split(',')
                rowValuesNumb = [[float(rowValues[1]), float(rowValues[2]), float(rowValues[3])]]
                if int(user_id) == int(svc_ms[key].predict(rowValuesNumb)[0]):
                    predicted_impostor = predicted_impostor + 1
                else:
                    predicted_not_impostor = predicted_not_impostor + 1
    percentage_for_user = float(predicted_impostor) / float(predicted_impostor + predicted_not_impostor)
    return percentage_for_user
    


# In[51]:


output = impostor_file_name.split('_')[1] + '\n'
for key, value in users_to_id.items():
    output = output + f"{key}: {get_prediction_for_user(value)}\n"
    
with open('pylogger_output.txt', 'w') as file:
   file.write(output)

