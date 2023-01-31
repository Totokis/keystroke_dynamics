import json
import platform

from flask import Flask

import time

import pylogger
import user_predictor

app = Flask(__name__)


@app.route('/')
def hello():
    return "Hello"


@app.route('/run/<int:seconds>')
def run_me(seconds:int):
    return run_everything(seconds)


@app.route("/username")
def get_name():
    return json.dumps(platform.node())


def run_everything(seconds:int):
    listener = pylogger.start_listener()

    timer = seconds
    while timer != 0:
        time.sleep(1)
        timer = timer - 1
        print(f"CLOSE IN: {timer}'s !")

    file_name = pylogger.close_listener(listener)

    output = user_predictor.get_user(file_name)

    # output = dict(sorted(output.items(), key=lambda x: x[1],reverse=True))
    return json.dumps(output)


if __name__ == '__main__':
    app.run()
