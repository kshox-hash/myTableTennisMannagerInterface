# Prueba completa antes de lanzar (≈ 30 min)

Simular un campeonato real desde la web (`myttm.cl/admin`) y seguirlo en el APK
con **dos cuentas de jugador** (idealmente dos celulares, o uno + la web).
Marcar cada paso; si algo falla, anotar la pantalla y la versión que aparece en
Ajustes.

## 1. Preparación (web, organizador)
- [ ] Crear un campeonato **puntuable**, nivel regional, con 2 categorías:
  - A: "Todo competidor" mixto, **grupos + llave**, 6 cupos
  - B: "Sub-18" mixto, **todos contra todos**
- [ ] Copiar el **link del campeonato** y abrirlo en el celular → debe abrir la app.

## 2. Inscripción (app, jugador)
- [ ] El detalle muestra "Puntúa · nivel regional".
- [ ] Inscribirse en A desde la app; la otra cuenta en A y B.
- [ ] "Mis campeonatos" en el Inicio cuenta 1 y abre ese campeonato.
- [ ] En la web, inscribir a mano 4 jugadores más (o importar) y marcar **pagos y check-in**.
- [ ] En la app aparece "Inscripción pagada ✓".
- [ ] Lista de inscritos: máximo 8 y "Ver los N inscritos".

## 3. Grupos y partidos
- [ ] Generar grupos en la web → a la app llega el aviso y aparece "Tu grupo".
- [ ] Partidos / Jugadores / Mesas: la barra de categorías arranca en la mía y filtra.
- [ ] Asignar una mesa → aviso "Te toca" y "EN MESA" en cyan en el Inicio.
- [ ] Generar un **QR de árbitro**, escanearlo con la otra cuenta y anotar el partido.
- [ ] Cargar un resultado normal y uno **W.O. por lesión** → la app dice "W.O. · Lesión".
- [ ] Las fotos de perfil (Google) se ven en grupo, partidos, llave e historial.

## 4. Llave y final
- [ ] Generar la llave → "Ver llave completa" y "Mi recorrido".
- [ ] Jugador eliminado: el Inicio sigue mostrando "CAMPEONATO EN CURSO".
- [ ] Categoría B (todos contra todos): al terminar dice "Ver tabla del grupo", no llave.
- [ ] Terminar A → ventana de celebración con podio.

## 5. Casos de borde
- [ ] Finalizar una categoría **antes de tiempo** → "Finalizada antes de tiempo".
- [ ] **Cancelar** otro campeonato de prueba → desaparece del Inicio y del calendario.
- [ ] Sin internet (modo avión): mensaje "Sin conexión" y botón Reintentar.
- [ ] Letra grande del celular al máximo: el Inicio y las tablas no se rompen.
- [ ] Recuperar contraseña (requiere `RESEND_API_KEY` en Render).
- [ ] Eliminar una cuenta de prueba desde Ajustes.

## 6. Actualización obligatoria
- [ ] En Render poner `APP_LATEST_BUILD` mayor al build actual → sugiere actualizar.
- [ ] Poner `APP_MIN_BUILD` mayor → la app bloquea con "Actualiza MyTTM".
- [ ] Volver ambos a 0.
