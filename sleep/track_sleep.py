#!/usr/bin/env python3
"""Sleep tracking script - appends sleep data to sleep.csv and displays contents."""

import csv
from datetime import datetime

CSV_FILE = "sleep.csv"


def get_today_date():
    """Return today's date in DD-Mon-YY format."""
    return datetime.now().strftime("%d-%b-%y")


def get_user_input():
    """Prompt user for taped status and sleep score."""
    while True:
        taped = input("Was your mouth taped? (y/n): ").strip().lower()
        if taped in ('y', 'n'):
            break
        print("Please enter 'y' or 'n'.")
    
    while True:
        try:
            score = int(input("Enter sleep score: ").strip())
            if 0 <= score <= 100:
                break
            print("Please enter a score between 0 and 100.")
        except ValueError:
            print("Please enter a valid number.")
    
    return taped, score


def append_sleep_data(date, taped, score):
    """Append a new row to the sleep CSV file."""
    file_exists = False
    try:
        with open(CSV_FILE, 'r', newline='') as f:
            file_exists = True
    except FileNotFoundError:
        pass
    
    # Open in append mode with newline='' to let csv writer handle line endings
    with open(CSV_FILE, 'a', newline='') as f:
        writer = csv.writer(f)
        # Write header if file didn't exist
        if not file_exists:
            writer.writerow(['Date woke', 'Taped', 'Sleep Score'])
        writer.writerow([date, taped, score])


def display_file_contents():
    """Read and print the entire contents of the CSV file."""
    try:
        with open(CSV_FILE, 'r', newline='') as f:
            contents = f.read()
            print("\n" + contents)
    except FileNotFoundError:
        print(f"\n{CSV_FILE} not found.")


def main():
    """Main function to run the sleep tracking workflow."""
    print("Sleep Tracking App")
    print("-----------------")
    
    date = get_today_date()
    taped, score = get_user_input()
    
    append_sleep_data(date, taped, score)
    display_file_contents()


if __name__ == "__main__":
    main()
