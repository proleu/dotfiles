# CLAUDE.md - Repository Guide for Automated Agents

## Monorepo Structure Guidelines
- Assets: /image, /package, /templates, /service, /iac, /dotfiles
- Random bs: /analysis
- Generally ignore, avoid if possible: /src /third_party, /pipelines
- Template asset types using [cruft](https://cruft.github.io/cruft/)
- Use Justfile for managing commands and recipes [just](https://just.systems/man/en/)

## Security Guidelines

- **CRITICAL**: NEVER create or push signed commits. For security reasons, only the human user is permitted to sign and push commits.
- Raise an immediate warning if any operation might result in a signed commit.

## Python Packages
- Manage commands with a Justfile
- Init/sync environment: `just init` or `just sync`
- Build: `just build`
- Lint: `just lint`
- Typecheck: `just typecheck`
- Run all tests: `just test`
- Run single test: `pipenv run pytest tests/path/to/test_file.py::TestClass::test_function -v`
- Format code: `just format`
- Full verification: `just verify`

## Python
- Use Python 3.11 or later
- **Dependency management**: Use uv for package management and virtual environments
  - Define project dependencies in `pyproject.toml`
- Follow PEP 8 guidelines
- Line length: 150 characters
- **Linting and formatting**: Use ruff
- **Static type checking**: Use mypy
  - Many projects will use beartype and jaxtyping as well
- **Testing**: Use pytest
- **Logging**: Use Python's built-in logging module
- **Configuration**: Use Hydra for YAML configuration of model training and inference
- **Versioning**: Use Justfile for version management of assets
- Import order: standard library, third-party, known first-party
- No local imports, no unused imports, no wildcard imports
- Strong typing: disallow_untyped_defs=true
- Format command: `just format` if justfile is present
- **Type hints**: Use Python 3.11 conventions:
  - Use builtin types when available
  - Use `|` operator instead of `Union` or `Optional` (e.g., `str | None` not `Optional[str]`)
  - Follow the [mypy cheat sheet](https://mypy.readthedocs.io/en/stable/cheat_sheet_py3.html)
- **Naming conventions**:
  - Constants: CAPITAL_SNAKE_CASE
  - Classes: PascalCase
  - Functions/methods: snake_case
  - Acronymic classes: Spell out full name (e.g., `MultipleSequenceAlignment` not `MSA`)
- **Docstrings**: Use Google style docstrings
  ```python
  def example_function(param1: str, param2: int) -> bool:
      """Short description of function.
      
      Longer description if needed.
      
      Args:
          param1: Description of param1
          param2: Description of param2
              
      Returns:
          Description of return value
          
      Raises:
          ValueError: When something goes wrong
      """
  ```


## Error Handling
- Use proper exception handling with specific exception types
- Log errors appropriately

## Version Management
- Package versions in Justfile: `VERSION:='x.y.z'`%                                                                                                                                                                                                                                                                                 
- Use semantic versioning
