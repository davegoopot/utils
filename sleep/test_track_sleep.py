#!/usr/bin/env python3
"""Tests for track_sleep.py module."""

import csv
import os
import tempfile
import unittest
from unittest.mock import patch

from track_sleep import append_sleep_data


class TestAppendSleepData(unittest.TestCase):
    """Tests for the append_sleep_data function."""

    def setUp(self):
        """Create a temporary directory and CSV file for testing."""
        self.temp_dir = tempfile.mkdtemp()
        self.csv_path = os.path.join(self.temp_dir, "sleep.csv")
        # Patch the CSV_FILE constant
        self.patcher = patch('track_sleep.CSV_FILE', self.csv_path)
        self.patcher.start()

    def tearDown(self):
        """Clean up temporary files and patches."""
        self.patcher.stop()
        if os.path.exists(self.csv_path):
            os.remove(self.csv_path)
        os.rmdir(self.temp_dir)

    def test_append_to_new_file(self):
        """Test appending to a non-existent file creates it with header."""
        append_sleep_data("01-Jan-24", "y", 80)
        
        with open(self.csv_path, 'r') as f:
            contents = f.read()
        
        expected = "Date woke,Taped,Sleep Score\n01-Jan-24,y,80\n"
        self.assertEqual(contents, expected)

    def test_append_to_existing_file_with_trailing_newline(self):
        """Test appending to a file that has a trailing newline."""
        # Create file with trailing newline
        with open(self.csv_path, 'w') as f:
            f.write("Date woke,Taped,Sleep Score\n01-Jan-24,y,80\n")
        
        append_sleep_data("02-Jan-24", "n", 75)
        
        with open(self.csv_path, 'r') as f:
            contents = f.read()
        
        expected = "Date woke,Taped,Sleep Score\n01-Jan-24,y,80\n02-Jan-24,n,75\n"
        self.assertEqual(contents, expected)

    def test_append_to_existing_file_without_trailing_newline(self):
        """Test appending to a file that does NOT have a trailing newline."""
        # Create file WITHOUT trailing newline
        with open(self.csv_path, 'w') as f:
            f.write("Date woke,Taped,Sleep Score\n01-Jan-24,y,80")
        
        append_sleep_data("02-Jan-24", "n", 75)
        
        with open(self.csv_path, 'r') as f:
            contents = f.read()
        
        # This should NOT have the new data appended to the last line
        # Each row should be on its own line
        expected = "Date woke,Taped,Sleep Score\n01-Jan-24,y,80\n02-Jan-24,n,75\n"
        self.assertEqual(contents, expected)


if __name__ == "__main__":
    unittest.main()
