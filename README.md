# AlDía — versión Flutter

Aplicación para Linux y Android que reúne los recibos del hogar, muestra sus
vencimientos y compara cada monto con los tres recibos anteriores del mismo
servicio. Organiza información: **no procesa pagos ni se conecta con bancos**.

La versión web con React está en la rama [`react`](../../tree/react).

## Funciones

- Servicios y recibos: crear, editar y eliminar.
- Marcar un recibo como pagado o pendiente.
- Resumen mensual, calendario e historial por servicio.
- Comparación de montos con tres antecedentes.
- Datos guardados en un archivo JSON local, sin cuentas ni servidor.

## Regla de comparación

`variación = (monto - promedio de los 3 anteriores) / promedio × 100`

| Variación | Clasificación |
|---|---|
| Menor a 10 % (incluye disminuciones) | Habitual |
| De 10 % a 25 %, inclusive | Aumento |
| Mayor a 25 % | Aumento inusual |
| Faltan antecedentes o el promedio no es positivo | Sin base para comparar |

El aviso indica un cambio de monto. No prueba mayor consumo, fraude ni un error
del proveedor.

## Ejecutar y probar

Probado con Flutter 3.44.1 y Dart 3.12.1.

```sh
flutter pub get
flutter run -d linux
flutter analyze
flutter test
flutter test integration_test -d linux
```

## Estructura

- `lib/models`: datos de servicios y recibos.
- `lib/logic`: montos, fechas, estados y comparación.
- `lib/data`: guardado local y datos de demostración.
- `lib/state`: controlador de la aplicación.
- `lib/screens` y `lib/widgets`: interfaz.
- `test` e `integration_test`: pruebas.
- `docs/evidencias`: capturas en Linux y en un emulador Android, con datos de prueba o ficticios.

## Límites

Los datos no se cifran, no se sincronizan y pueden perderse al desinstalar la
aplicación. Android se probó en un emulador. No se evaluó con hogares reales.
