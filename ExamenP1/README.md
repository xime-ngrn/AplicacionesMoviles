# Primer examen parcial — Pull Request con aseguramiento de calidad

**Unidad de aprendizaje:** Desarrollo de aplicaciones móviles nativas 

**Grupo:** 7CV4 · **Periodo:** 2027-1

**Proyecto:** [gabrielhuav/PolitecnicoOpenWorld](https://github.com/gabrielhuav/PolitecnicoOpenWorld) (POW) · **Módulo:** HUELUM VS. GOYA (modo de pelea)

**Cambio:** el botón/gesto **Atrás del sistema** respeta la navegación interna del modo de pelea.

**Moreno Noguerón Ximena** · 2024630201

---
## Índice

- [Fork del proyecto](https://github.com/xime-ngrn/PolitecnicoOpenWorld-Examen)
- [Issue](https://github.com/xime-ngrn/PolitecnicoOpenWorld-Examen/issues/1)
- [Pull Request de los cambios](https://github.com/gabrielhuav/PolitecnicoOpenWorld/pull/160)
- [Documentación del Examen](https://github.com/xime-ngrn/AplicacionesMoviles/blob/main/ExamenP1/README.md)
- [Revisión de un compañero del Pull Request]()
- [Revisión de mi parte del Pull Request de un compañero](https://github.com/gabrielhuav/PolitecnicoOpenWorld/pull/165#issuecomment-5938230691)
- [Documento de desarrollo del cambio realizado](/ExamenP1/docs/DESARROLLO.md)
- [Documento de pruebas del cambio realizado](/ExamenP1/docs/PRUEBAS.md)

---

## Bitácora

### Moreno Noguerón Ximena · 2024630201

**Registro de actividades y commits**

| Fecha | Actividad | Evidencia |
|---|---|---|
| 30/09/2026 00:35 | Fork del repositorio original | [Fork](https://github.com/xime-ngrn/PolitecnicoOpenWorld-Examen) |
| 30/09/2026 10:31 | Registro del issue con criterios de aceptación | [Issue #1](https://github.com/xime-ngrn/PolitecnicoOpenWorld-Examen/issues/1) |
| 30/09/2026 14:52 | Commit del cambio en `fix/1-sf-system-native-back-dialog` | [`c461a770`](https://github.com/xime-ngrn/PolitecnicoOpenWorld-Examen/commit/c461a770424e01210d0f4f3b204f648336532749) |
| 30/09/2026 15:26 | Pruebas unitarias `SfSystemBackTest` (4/4 aprobadas) | [Desarrollo](docs/DESARROLLO.md) |
| 30/09/2026 17:55 | Commit de la base de la documentación del examen | [`bf871f1`](https://github.com/xime-ngrn/AplicacionesMoviles/commit/bf871f16e33720cae616418bfb7bad4cee3d1b56) |
| 30/09/2026 18:48 | Pull Request al repositorio original | [PR #160](https://github.com/gabrielhuav/PolitecnicoOpenWorld/pull/160) |
| 01/10/2026 12:46 | Revisión QA del PR #165 de un compañero | [Comentario en PR #165](https://github.com/gabrielhuav/PolitecnicoOpenWorld/pull/165#issuecomment-5938230691) |

**Casos ejecutados**

| Caso | Navegación | Estado | Evidencia |
|---|---|---|---|
| TC-01 · Ruta feliz | Botones | Aprobado | [E_01](resources/evidences/E_01.mp4) |
| TC-02 · Límite | Gestos | Aprobado | [E_02](resources/evidences/E_02.mp4) |
| TC-03 · Navegación y estado | Botones | Aprobado | [E_03](resources/evidences/E_03.mp4), [E_03_2](resources/evidences/E_03_2.mp4) |
| TC-04 · Regresión | Gestos | Aprobado | [E_04](resources/evidences/E_04.mp4) |
| TC-05 · Accesibilidad | Botones | Observación identificada | [E_05](resources/evidences/E_05.mp4) |
| TC-06 · Compatibilidad (inglés) | Gestos | Aprobado | [E_06](resources/evidences/E_06.mp4) |

**Revisiones**

| Revisión | Enlace |
|---|---|
| Revisión recibida en mi PR (#160) | ⟨pendiente⟩ |
| Revisión hecha al PR #165 de @AbelHunt3r (búsqueda de estaciones sin acentos): 6 casos reproducidos en Samsung A15 sobre el SHA `1b92fed`; recomendación: lista para integrar | [Comentario en PR #165](https://github.com/gabrielhuav/PolitecnicoOpenWorld/pull/165#issuecomment-5938230691) |
