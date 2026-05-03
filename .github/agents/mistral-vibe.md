# Mistral Vibe Agent Configuration

This file documents the expected behavior for the Mistral Vibe coding agent when working on this repository.

## Python Environment

- **Always use Python with uv**: Use `uv run` for all Python commands, including running scripts and tests.
- **Never .gitignore uv.lock**: The `uv.lock` file must be committed to git for repeatable builds.

## Development Practices

- **Use Red-Green TDD**: Follow Test-Driven Development:
  1. Write a failing test first (Red)
  2. Implement the fix (Green)
  3. Refactor if needed
- **Testing Framework**: Use `pytest` for all tests. Do not use `unittest`.

## Commands

- Run tests: `uv run pytest`
- Run specific test file: `uv run pytest path/to/test_file.py -v`
- Install dependencies: `uv pip install package_name`
