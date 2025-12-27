# Terraform Instructions

## Variables

- Siempre incluir `type` y `description`
- Agregar `validation` cuando aplique
- Marcar secrets con `sensitive = true`

## Recursos

- Naming: `{tipo}_{propósito}`
- Usar `for_each` sobre `count` cuando sea posible
- Tags obligatorios: Environment, Project, ManagedBy

## Outputs

- Siempre incluir `description`
- Solo exponer valores necesarios

## Validación

```bash
terraform fmt -recursive
terraform validate
```
