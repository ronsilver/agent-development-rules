---
trigger: glob
globs: ["*.py", "*.js", "*.ts", "*.go", "*.java", "*.cs", "*.rb"]
---

# SOLID Principles - Best Practices

## Summary

| Principle | Description | Benefit |
|-----------|-------------|---------|
| **S** - Single Responsibility | One class = One reason to change | Maintainability |
| **O** - Open/Closed | Open for extension, closed for modification | Extensibility |
| **L** - Liskov Substitution | Subtypes must be substitutable | Correctness |
| **I** - Interface Segregation | Small, specific interfaces | Flexibility |
| **D** - Dependency Inversion | Depend on abstractions, not concretions | Testability |

## S - Single Responsibility Principle (SRP)
**"A class should have one, and only one, reason to change."**

```python
# ❌ Bad - God Class
class UserService:
    def create_user(self, data):
        self.validate(data)
        self.save_db(data)
        self.send_email(data)  # Mixed responsibilities

# ✅ Good - Separated
class UserValidator: ...
class UserRepository: ...
class NotificationService: ...
```

## O - Open/Closed Principle (OCP)
**"Open for extension, closed for modification."**

Use **Strategy Pattern** or **Interfaces** to avoid modifying existing code when adding new features.

```python
# ❌ Bad - Modifying for new type
if type == 'credit': process_credit()
elif type == 'paypal': process_paypal()

# ✅ Good - Polymorphism
payment_method.process() # Works for any new PaymentMethod subclass
```

## L - Liskov Substitution Principle (LSP)
**"Subtypes must be substitutable for their base types."**

- Subclasses should not throw "Not Implemented".
- Subclasses should not strengthen preconditions or weaken postconditions.

## I - Interface Segregation Principle (ISP)
**"Clients should not be forced to depend on interfaces they do not use."**

Avoid "Fat Interfaces". Split them into smaller roles.

```go
// ❌ Bad
type Worker interface { Work(); Eat(); Sleep() }

// ✅ Good
type Workable interface { Work() }
type Eatable interface { Eat() }
```

## D - Dependency Inversion Principle (DIP)
**"Depend on abstractions, not concretions."**

Use **Dependency Injection**.

```python
# ❌ Bad - Direct dependency
class Service:
    def __init__(self):
        self.db = MySQLDatabase()

# ✅ Good - Injection
class Service:
    def __init__(self, db: DatabaseInterface):
        self.db = db
```

## Refactoring Triggers
- **God Class**: >300 lines or mixed concerns.
- **Shotgun Surgery**: Changing one thing requires edits in 5 files.
- **Circular Deps**: A <-> B.
