// Ejecutar con playwright-cli run-code --filename=tests/browser-smoke.js
// sobre la aplicación abierta. Usa un contexto aislado, sin modificar datos reales.
async (page) => {
  const origin = await page.evaluate(() => location.origin);
  if (!['http://127.0.0.1:4173', 'https://up-to-date-app.vercel.app'].includes(origin)) {
    throw new Error('Abre primero la vista previa de AlDía o su web publicada.');
  }
  const context = await page.context().browser().newContext({ viewport: { width: 390, height: 844 } });
  const p = await context.newPage();
  const checks = [];
  const check = (name, value) => {
    if (!value) throw new Error(name);
    checks.push(name);
  };
  const navigate = (name) => p.locator('.bottom-nav').getByRole('button', { name }).click();
  try {
    await p.goto(origin);
    await p.getByRole('button', { name: 'Agregar mi primer servicio' }).click();
    await p.getByLabel('Nombre del servicio').fill('Luz pruebas');
    await p.getByRole('button', { name: 'Guardar servicio' }).click();
    check('Registro de servicio', await p.locator('.welcome').count() === 0);

    await p.getByRole('button', { name: 'Nuevo recibo', exact: true }).click();
    await p.getByLabel('Monto (S/)').fill('86.40');
    await p.getByLabel('Fecha de vencimiento').fill('2026-10-15');
    await p.getByRole('button', { name: 'Guardar recibo' }).click();
    check('Registro de recibo', (await p.locator('.big-amount').innerText()).includes('86.40'));
    await p.reload();
    check('Persistencia tras recargar', (await p.locator('.big-amount').innerText()).includes('86.40'));

    await p.getByRole('button', { name: 'Nuevo recibo', exact: true }).click();
    await p.getByLabel('Monto (S/)').fill('90');
    await p.getByLabel('Fecha de vencimiento').fill('2026-10-20');
    await p.getByRole('button', { name: 'Guardar recibo' }).click();
    check('Duplicado rechazado', (await p.getByRole('alert').innerText()).includes('ya tiene un recibo'));
    await p.getByRole('button', { name: 'Cerrar', exact: true }).click();

    await p.locator('.bill-row').first().click();
    await p.getByRole('button', { name: 'Marcar como pagado' }).click();
    check('Pago actualiza total', (await p.locator('.big-amount').innerText()).includes('0.00'));
    await navigate('Historial');
    await p.locator('.bill-row').first().click();
    await p.getByRole('button', { name: 'Volver a pendiente' }).click();
    await navigate('Resumen');
    check('Deshacer pago', (await p.locator('.big-amount').innerText()).includes('86.40'));

    await p.locator('.bill-row').first().click();
    await p.getByRole('button', { name: 'Editar recibo', exact: true }).click();
    await p.getByLabel('Monto (S/)').fill('95.20');
    await p.getByRole('button', { name: 'Guardar recibo' }).click();
    check('Edición de recibo', (await p.locator('.big-amount').innerText()).includes('95.20'));
    await navigate('Calendario');
    await p.getByRole('button', { name: /15 de octubre/ }).click();
    check('Filtro por día', await p.locator('.bill-row').count() === 1);
    check('Sin desbordamiento en móvil', await p.evaluate(() => document.documentElement.scrollWidth <= innerWidth));

    await p.getByRole('button', { name: 'Ajustes y respaldos', exact: true }).click();
    const downloading = p.waitForEvent('download');
    await p.getByRole('button', { name: 'Descargar respaldo' }).click();
    const backup = await downloading;
    check('Exportación de respaldo', backup.suggestedFilename().startsWith('aldia-'));
    await p.getByRole('button', { name: 'Cerrar', exact: true }).click();

    await navigate('Servicios');
    await p.getByRole('button', { name: 'Eliminar', exact: true }).click();
    await p.getByRole('button', { name: 'Cancelar', exact: true }).click();
    check('Cancelar eliminación', await p.locator('.service-card').count() === 1);
    await p.getByRole('button', { name: 'Eliminar', exact: true }).click();
    await p.getByRole('button', { name: 'Confirmar', exact: true }).click();
    check('Eliminación en cascada', await p.evaluate(() => JSON.parse(localStorage.getItem('aldia_v1')).bills.length === 0));

    await p.getByRole('button', { name: 'Explorar con datos de ejemplo' }).click();
    await navigate('Resumen');
    check('Aumento inusual demostrado', (await p.locator('.insight-item').innerText()).includes('41.5%'));
    await p.evaluate(async () => { await navigator.serviceWorker.ready; });
    await p.reload();
    await context.setOffline(true);
    await p.reload();
    check('Recarga sin conexión', await p.getByRole('heading', { name: 'Resumen', exact: true }).isVisible());
    check('Datos conservados sin conexión', await p.evaluate(() => JSON.parse(localStorage.getItem('aldia_v1')).bills.length === 16));
    await context.setOffline(false);

    await p.evaluate(() => localStorage.setItem('aldia_v1', 'corrupt'));
    await p.reload();
    check('Datos corruptos no sobrescritos', await p.evaluate(() => localStorage.getItem('aldia_v1') === 'corrupt'));
    await p.getByRole('button', { name: 'Abrir ajustes' }).click();
    await p.getByRole('button', { name: 'Borrar todos los datos' }).click();
    await p.getByRole('button', { name: 'Confirmar', exact: true }).click();
    await p.getByRole('button', { name: 'Agregar mi primer servicio' }).click();
    await p.getByLabel('Nombre del servicio').fill('Después de recuperar');
    await p.getByRole('button', { name: 'Guardar servicio' }).click();
    check('Recuperación tras reinicio confirmado', await p.locator('.welcome').count() === 0);
    return { passed: checks.length, checks };
  } finally {
    await context.setOffline(false);
    await context.close();
  }
}
