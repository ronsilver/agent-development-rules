---
trigger: glob
globs: ["*.py", "requirements*.txt", "pyproject.toml"]
---

# Python Best Practices

## Type Hints - MANDATORY

All new functions **MUST** have complete type hints.

```python
# ✅ Correct
def process_data(items: list[str]) -> dict[str, int]: ...
```

## Data Models
Use `pydantic` for data validation and `dataclasses` for internal structures.

```python
from pydantic import BaseModel, Field

class UserCreate(BaseModel):
    name: str = Field(..., min_length=1)
    email: str
    age: int = Field(..., ge=0)
```

## Mandatory Tooling

Before any commit or PR, you **MUST** run:
```bash
ruff format .      # Formatting (replaces black)
ruff check .       # Linting (replaces flake8, isort)
mypy src/          # Type checking
pytest             # Testing
pytest --cov=src --cov-report=term-missing  # Coverage
bandit -r src/     # Security
```

## Modern Tooling (Ruff) - 2025 Configuration

Ruff is **10-100x faster** than traditional tools and replaces: flake8, black, isort, pyupgrade, autoflake, pydocstyle.

### Installation
```bash
pip install ruff
```

### Configuration - `pyproject.toml`

**Basic Configuration**:
```toml
[tool.ruff]
# Line length (same as Black)
line-length = 88
target-version = "py311"

# Enable preview mode for latest rules (2025)
preview = true

# Exclude directories
exclude = [
    ".venv",
    "venv",
    ".git",
    "__pycache__",
    "dist",
    "build",
    ".pytest_cache",
    ".mypy_cache",
]

# Rule selection
select = [
    "E",   # pycodestyle errors
    "F",   # Pyflakes
    "B",   # flake8-bugbear (common bugs)
    "I",   # isort (import sorting)
    "UP",  # pyupgrade (modern syntax)
    "PL",  # Pylint
]
```

**Comprehensive Configuration** (recommended):
```toml
[tool.ruff]
line-length = 88
target-version = "py311"
preview = true

select = [
    # Core
    "E",     # pycodestyle errors
    "F",     # Pyflakes
    "W",     # pycodestyle warnings

    # Best practices
    "B",     # flake8-bugbear
    "C4",    # comprehensions
    "FA",    # future annotations
    "ISC",   # implicit string concatenation
    "ICN",   # import conventions
    "RET",   # return statements
    "SIM",   # simplification
    "TID",   # tidy imports
    "TC",    # type checking blocks
    "PTH",   # use pathlib

    # Documentation
    "D",     # pydocstyle

    # Type hints
    "UP",    # pyupgrade
    "ANN",   # annotations

    # Code quality
    "PL",    # Pylint
    "ARG",   # unused arguments
    "TD",    # TODO comments
    "FIX",   # FIXME comments
]

ignore = [
    "D100",  # Missing docstring in public module
    "D104",  # Missing docstring in public package
]

[tool.ruff.lint.per-file-ignores]
"tests/**/*.py" = [
    "S101",   # Allow assert in tests
    "PLR2004", # Magic values in tests
]
"__init__.py" = [
    "F401",   # Allow unused imports
]
"migrations/**/*.py" = [
    "E501",   # Allow long lines
]

[tool.ruff.lint.isort]
known-first-party = ["myapp"]
section-order = ["future", "standard-library", "third-party", "first-party", "local-folder"]

[tool.ruff.lint.pydocstyle]
convention = "google"  # or "numpy", "pep257"

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

### Ruff Commands

```bash
# Format code (replaces black)
ruff format .

# Check linting (replaces flake8)
ruff check .

# Auto-fix issues
ruff check . --fix

# Watch mode (continuous linting)
ruff check . --watch

# Show fixes without applying
ruff check . --diff

# Format check (CI/CD)
ruff format . --check
```

## Security (Bandit)

Run `bandit -r src/` to check for security issues.

### Configuration - `.bandit`
```yaml
# .bandit
exclude_dirs:
  - /tests
  - /.venv
  - /venv

skips:
  - B101  # Allow assert (covered by pytest)

tests:
  - B201  # Flask debug mode
  - B501  # SSL warnings
```

## Testing with Pytest

### Coverage Requirements

> Thresholds (90%/80%/70%) defined in **testing.md § Coverage Requirements**.

### Essential Pytest Plugins

```bash
# Install pytest with essential plugins
pip install pytest pytest-cov pytest-xdist pytest-mock pytest-asyncio
```

**Plugin purposes**:
- **pytest-cov**: Coverage reporting
- **pytest-xdist**: Parallel test execution
- **pytest-mock**: Simplified mocking
- **pytest-asyncio**: Async test support

### Configuration - `pyproject.toml`

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
python_classes = "Test*"
python_functions = "test_*"

# Coverage
addopts = [
    "--cov=src",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-fail-under=70",
    "-v",
]

# Async support
asyncio_mode = "auto"

# Markers
markers = [
    "slow: marks tests as slow",
    "integration: marks tests as integration tests",
    "unit: marks tests as unit tests",
]

[tool.coverage.run]
source = ["src"]
omit = [
    "*/tests/*",
    "*/migrations/*",
    "*/__pycache__/*",
]

[tool.coverage.report]
exclude_lines = [
    "pragma: no cover",
    "def __repr__",
    "raise AssertionError",
    "raise NotImplementedError",
    "if __name__ == .__main__.:",
    "if TYPE_CHECKING:",
]
```

### Test Examples

> For general patterns (AAA, naming, table-driven, anti-patterns), see **testing.md**.

**Fixtures** (`conftest.py`):
```python
import pytest
from myapp.database import Database

@pytest.fixture
def db():
    """Database fixture with cleanup."""
    database = Database(":memory:")
    database.init()
    yield database
    database.close()

@pytest.fixture
def client(db):
    """API client fixture."""
    from myapp.app import create_app
    app = create_app(db)
    with app.test_client() as client:
        yield client
```

**Parametrize** (multiple test cases):
```python
@pytest.mark.parametrize("input,expected", [
    (1, 2),
    (2, 4),
    (3, 6),
    (-1, -2),
])
def test_double(input, expected):
    assert double(input) == expected
```

**Mocking** (pytest-mock):
```python
def test_user_service(mocker):
    mock_repo = mocker.Mock()
    mock_repo.get_user.return_value = {"id": 123, "name": "John"}

    service = UserService(mock_repo)
    user = service.get_user(123)

    assert user["id"] == 123
    mock_repo.get_user.assert_called_once_with(123)
```

### Running Tests

```bash
pytest                                    # Run all tests
pytest --cov=src --cov-report=term-missing # With coverage
pytest -n auto                             # Parallel (pytest-xdist)
pytest -m "not slow"                       # Skip slow tests
pytest -x -l                               # Stop on first failure, show locals
```

## Path Handling
Always use `pathlib.Path`, never `os.path.join`.

```python
# ✅ Correct
path = Path(__file__).parent / "data.txt"
```
