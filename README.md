# ERP Familia

Sistema de gestión para una empresa familiar dedicada a la producción y distribución de frutas.

Flujo principal: `LOTE → ENVÍO → RECEPCIÓN → VENTA`.

## Arquitectura

- GitHub: fuente del código e historial.
- Vercel: despliegues automáticos.
- Supabase: autenticación y base de datos.

## Configuración local

1. Copiar `.env.example` como `.env.local`.
2. Agregar la URL y la clave pública de Supabase.
3. Ejecutar `npm install` y `npm run dev`.

Las credenciales nunca deben subirse al repositorio.
