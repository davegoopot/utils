#!/usr/bin/env python3
"""Tests for track_sleep.py module using pytest."""

import os
import tempfile

import pytest

from track_sleep import append_sleep_data


@pytest.fixture
def temp_csv_file(monkeypatch, tmp_path):
    """Fixture to create a temporary CSV file path and patch CSV_FILE constant."""
    csv_path = tmp_path / "sleep.csv"
    monkeypatch.setattr("track_sleep.CSV_FILE", str(csv_path))
    return csv_path


def test_append_to_new_file(temp_csv_file):
    """Test appending to a non-existent file creates it with header."""
    append_sleep_data("01-Jan-24", "y", 80)
    
    contents = temp_csv_file.read_text()
    expected = "Date woke,Taped,Sleep Score\n01-Jan-24,y,80\n"
    assert contents == expected


def test_append_to_existing_file_with_trailing_newline(temp_csv_file):
    """Test appending to a file that has a trailing newline."""
    # Create file with trailing newline
    temp_csv_file.write_text("Date woke,Taped,Sleep Score\n01-Jan-24,y,80\n")
    
    append_sleep_data("02-Jan-24", "n", 75)
    
    contents = temp_csv_file.read_text()
    expected = "Date woke,Taped,Sleep Score\n01-Jan-24,y,80\n02-Jan-24,n,75\n"
    assert contents == expected


def test_append_to_existing_file_without_trailing_newline(temp_csv_file):
    """Test appending to a file that does NOT have a trailing newline."""
    # Create file WITHOUT trailing newline
    temp_csv_file.write_text("Date woke,Taped,Sleep Score\n01-Jan-24,y,80")
    
    append_sleep_data("02-Jan-24", "n", 75)
    
    contents = temp_csv_file.read_text()
    # This should NOT have the new data appended to the last line
    # Each row should be on its own line
    expected = "Date woke,Taped,Sleep Score\n01-Jan-24,y,80\n02-Jan-24,n,75\n"
    assert contents == expected
