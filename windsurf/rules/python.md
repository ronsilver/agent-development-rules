---
trigger: glob
globs: ["*.py", "requirements*.txt", "pyproject.toml"]
---

# Python Best Practices

## Formato

- Usar Black para formateo
- Line length: 88

## Type Hints

```python
def get_user(user_id: int) -> User | None:
    ...

def process(items: list[str]) -> dict[str, int]:
    ...
```

## Docstrings

```python
def calculate(value: float, rate: float = 0.1) -> float:
    """Calculate the result with rate.
    
    Args:
        value: Base value.
        rate: Rate to apply (default 10%).
    
    Returns:
        Calculated result.
    """
```

## Estructura

```
project/
├── src/
│   └── package/
│       ├── __init__.py
│       └── main.py
├── tests/
├── requirements.txt
└── pyproject.toml
```

## Dependencias

```
# requirements.txt - versiones específicas
fastapi==0.104.1
pydantic==2.5.2
```

## Paths

Usar `pathlib`:
```python
from pathlib import Path
config = Path(__file__).parent / "config.yaml"
```

## Testing

```bash
pytest tests/ -v
pytest --cov=src
```

## Linting

```bash
black .
ruff check .
mypy src/
```

## Virtual Environments

```bash
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```
