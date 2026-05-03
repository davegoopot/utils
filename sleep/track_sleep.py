#!/usr/bin/env python3
"""Sleep tracking script - updates sleep.csv with new entries."""

import csv
from datetime import datetime
import os

CSV_FILE = os.path.join(os.path.dirname(__file__), "sleep.csv")


def get_taped():
    """Ask if mouth was taped."""
    while True:
        response = input("Was your mouth taped? (y/n): ").strip().lower()
        if response in ("y", "n"):
            return response
        print("Please enter 'y' or 'n'.")


def get_sleep_score():
    """Ask for sleep score."""
    while True:
        try:
            score = int(input("Enter sleep score: ").strip())
            return score
        except ValueError:
            print("Please enter a valid number.")


def get_date():
    """Get today's date in the format used by the CSV."""
    return datetime.now().strftime("%d-%b-%y")


def update_sleep_csv(date, taped, score):
    """Append a new row to sleep.csv."""
    file_exists = os.path.exists(CSV_FILE)
    
    # Read existing content and strip trailing newlines
    if file_exists:
        with open(CSV_FILE, "r") as f:
            content = f.read()
        # Strip trailing whitespace including \r\n
        content = content.rstrip()
    else:
        content = ""
    
    # Write back with new row
    with open(CSV_FILE, "w", newline="") as f:
        writer = csv.writer(f, lineterminator="\n")
        
        # Write header if file was empty
        if not content:
            writer.writerow(["Date woke", "Taped", "Sleep Score"])
        else:
            # Write existing content (without trailing newline)
            f.write(content + "\n")
        
        writer.writerow([date, taped, score])


def print_file_contents():
    """Print the entire contents of sleep.csv to console."""
    with open(CSV_FILE, "r") as f:
        print("\n" + f.read(), end="")


def main():
    print("=== Sleep Tracking ===")
    date = get_date()
    taped = get_taped()
    score = get_sleep_score()
    
    update_sleep_csv(date, taped, score)
    print_file_contents()


if __name__ == "__main__":
    main()
