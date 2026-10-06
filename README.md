# AlDía

**Tus recibos, bajo control.** Web app móvil e instalable para organizar los
pagos recurrentes del hogar y detectar aumentos inusuales en sus montos.
No procesa pagos ni necesita una cuenta o conexión con bancos.

**Aplicación publicada:** https://up-to-date-app.vercel.app

**Video de uso:** [demostración móvil](docs/evidence/demo.mp4).

**Diseño de referencia:** [cuatro vistas editables en Figma](https://www.figma.com/design/I7Nhgw2uD5ufPbrutX14US).
`docs/evidence/figma-reference.png` corresponde al diseño, no a la aplicación
ejecutándose. Las demás capturas de interfaces muestran el MVP publicado.

## MVP

- Servicios y recibos: crear, editar y eliminar, con confirmación al borrar.
- Resumen mensual: total, pagado, pendiente y avance por monto.
- Calendario: vencimientos y filtro por día.
- Historial y estado pagado/pendiente; un recibo por servicio y mes.
- Comparación con los últimos tres recibos anteriores del mismo servicio.
- Persistencia local, exportación y restauración de respaldo JSON validado.
- PWA instalable y disponible sin conexión después de la primera carga.
- Recordatorios dentro de la app y avisos del navegador cuando está activa.

El ejemplo incorporado contiene 4 servicios y 16 recibos ficticios. Solo se
carga si la persona elige **Explorar con datos de ejemplo** y queda identificado.

## Ejecutar

Requiere Node.js 22.12 o superior (también compatible con Node.js 24).

```sh
npm ci
npm run dev
```

```sh
npm test
npm run build
npm run preview
```

Para repetir las 17 comprobaciones de navegador, con `playwright-cli` disponible:

```sh
playwright-cli open http://127.0.0.1:4173
playwright-cli run-code --filename=tests/browser-smoke.js
```

Estas comprobaciones usan un contexto aislado y no alteran los datos del usuario.

Vercel detecta Vite automáticamente: `npm run build`, salida `dist`.
No necesita variables de entorno ni un backend.

## Reglas sencillas

Los montos se almacenan en céntimos enteros. La variación se calcula así:

`(monto actual - promedio de los tres anteriores) / promedio × 100`

- Menor al 10 %: habitual (también las disminuciones).
- Del 10 % al 25 %, incluidos ambos límites: aumento.
- Mayor al 25 %: aumento inusual.
- Menos de tres antecedentes o promedio cero: no se compara.

No se incluyen el recibo actual, recibos de otros servicios ni meses futuros.
Una variación del precio no demuestra un cambio del consumo o un error del proveedor.

## Estructura

- `src/App.jsx`: cuatro vistas, formularios, detalle y respaldos.
- `src/model.js`: validaciones, cálculo, estados y datos de demostración.
- `src/styles.css`: diseño responsive, foco visible y movimiento reducido.
- `vite.config.js`: instalación y caché sin conexión.
- `tests/model.test.js`: pruebas de reglas y datos.
- `docs/evidence/`: capturas y video de uso del MVP.

## Límites deliberados

Los datos permanecen en el navegador del dispositivo: no se sincronizan ni se
envían a un servidor. Borrar los datos del navegador los elimina; se recomienda
descargar respaldos. El MVP admite hasta 500 servicios y 10 000 recibos.

Las notificaciones se revisan al abrir o mantener activa la app, con permiso del
usuario. **No se programan notificaciones con la app cerrada.** Para esa capacidad
se necesitaría un backend con notificaciones push. En iOS, la disponibilidad
depende de la versión y de la instalación en la pantalla de inicio.

No incluye OCR, fotografías, autenticación, pagos, cuotas bancarias ni sincronización.
Las pruebas móviles se realizan por emulación en Chromium, no en dispositivos físicos.

La tipografía Manrope se sirve localmente para no depender de Google Fonts al
trabajar sin conexión. Su licencia está en `public/Manrope-LICENSE.txt`.
