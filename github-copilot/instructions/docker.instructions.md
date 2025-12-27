# Docker Instructions

## Multi-stage Builds

- Usar multi-stage para imágenes pequeñas
- Builder stage para compilación
- Final stage minimal

## Seguridad

- No correr como root: `USER nobody`
- No incluir secrets en la imagen
- Usar imágenes base específicas, no `latest`

## Layers

- Ordenar de menos a más cambiante
- Dependencias antes que código
- Combinar RUN commands relacionados

## .dockerignore

- Excluir .git, node_modules, .env
