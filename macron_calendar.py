"""
MACRON Calendar v1.0
Integracion con Calendar y Reminders de macOS
"""
import subprocess
import datetime

def add_reminder(title, notes=""):
    script = f'tell application "Reminders" to make new reminder with properties {{name:"{title}", body:"{notes}"}}'
    try:
        subprocess.run(["osascript", "-e", script], check=True, capture_output=True)
        return True
    except:
        return False

def add_calendar_event(title, start_date, notes=""):
    start_str = start_date.strftime("%Y-%m-%d %H:%M:%S")
    script = f'tell application "Calendar" to tell calendar "Home" to make new event with properties {{summary:"{title}", start date:date "{start_str}", description:"{notes}"}}'
    try:
        subprocess.run(["osascript", "-e", script], check=True, capture_output=True)
        return True
    except:
        return False

if __name__ == "__main__":
    print("Modulo de Calendar cargado")
