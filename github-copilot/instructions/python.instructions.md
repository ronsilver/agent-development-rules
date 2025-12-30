# Python Instructions

## Type Hints

### Obligatorio en Funciones Públicas
```python
from typing import Optional
from collections.abc import Sequence

def get_user(user_id: int) -> User | None:
    """Retrieve user by ID."""
    ...

def process_items(items: Sequence[str]) -> dict[str, int]:
    """Process items and return counts."""
    ...

def create_order(
    user_id: int,
    items: list[OrderItem],
    *,
    priority: bool = False,
) -> Order:
    """Create a new order for user."""
    ...
```

### Tipos Complejos
```python
from typing import TypeAlias, TypedDict

# Type aliases para claridad
UserID: TypeAlias = int
JSON: TypeAlias = dict[str, "JSON"] | list["JSON"] | str | int | float | bool | None

# TypedDict para estructuras conocidas
class UserConfig(TypedDict):
    name: str
    email: str
    active: bool
```

## Formato y Linting

```bash
# Formateo
black .                    # Line length: 88

# Linting
ruff check .               # Fast linter
mypy src/                  # Type checking

# Configuración en pyproject.toml
```

## Docstrings (Google Style)

```python
def calculate_discount(
    amount: float,
    rate: float = 0.1,
    *,
    max_discount: float | None = None,
) -> float:
    """Calculate discounted amount.

    Args:
        amount: Original amount before discount.
        rate: Discount rate as decimal (default 10%).
        max_discount: Maximum discount cap, if any.

    Returns:
        Final amount after applying discount.

    Raises:
        ValueError: If amount is negative.

    Example:
        >>> calculate_discount(100, 0.2)
        80.0
    """
```

## Paths - Usar pathlib

```python
from pathlib import Path

# ✅ Correcto
config_path = Path(__file__).parent / "config.yaml"
if config_path.exists():
    content = config_path.read_text()

# ❌ Evitar
import os
config_path = os.path.join(os.path.dirname(__file__), "config.yaml")
```

## Modelos de Datos

```python
from dataclasses import dataclass
from pydantic import BaseModel, Field

# Dataclass para datos simples
@dataclass
class Point:
    x: float
    y: float

# Pydantic para validación
class UserCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    email: str = Field(..., pattern=r"^[\w.-]+@[\w.-]+\.\w+$")
    age: int = Field(..., ge=0, le=150)
```

## Estructura de Proyecto

```
project/
├── src/
│   └── package/
│       ├── __init__.py
│       ├── main.py
│       └── models.py
├── tests/
│   └── test_main.py
├── pyproject.toml
└── requirements.txt
```

## Dependencias

```
# requirements.txt - versiones específicas
fastapi==0.109.0
pydantic==2.5.3
httpx==0.26.0
```

## Async/Await

```python
import asyncio
import httpx

async def fetch_user(client: httpx.AsyncClient, user_id: int) -> User:
    """Fetch user from API."""
    response = await client.get(f"/users/{user_id}")
    response.raise_for_status()
    return User(**response.json())

async def fetch_all_users(user_ids: list[int]) -> list[User]:
    """Fetch multiple users concurrently."""
    async with httpx.AsyncClient(base_url=API_URL) as client:
        tasks = [fetch_user(client, uid) for uid in user_ids]
        return await asyncio.gather(*tasks)
```

## Comandos de Validación

```bash
# Formateo
black .
isort .

# Linting
ruff check .
mypy src/

# Testing
pytest tests/ -v
pytest --cov=src --cov-report=term-missing

# Seguridad
pip-audit
bandit -r src/
```

## Anti-Patrones

| Anti-Patrón | Solución |
|-------------|----------|
| `except Exception: pass` | Manejar errores específicos |
| Mutable default args | Usar `None` y crear en función |
| `import *` | Imports explícitos |
| Strings para paths | Usar `pathlib.Path` |
| Sin type hints | Agregar en funciones públicas |
