# Plan y registro de pruebas — Atrás del sistema en HUELUM VS. GOYA

**PR:** [#160](https://github.com/gabrielhuav/PolitecnicoOpenWorld/pull/160) · **Issue:** [#1](https://github.com/xime-ngrn/PolitecnicoOpenWorld-Examen/issues/1) · **SHA base:** `7ed3253` · **SHA probado:** `c461a770`

## Preparación del entorno para ejecutar o reproducir los casos
> Para cualquier usuario que ejecute un caso o reproduzca las pruebas como revisor, se propone una lista para que la ejecución (tanto del proyecto y de las pruebas) sea sin errores.

### 1. Instalar la versión correcta
1. Cambiar a la rama del PR y confirmar el SHA que se va a probar:

    ```powershell
    git fetch origin
    git checkout fix/1-sf-system-native-back-dialog
    git rev-parse --short HEAD
    ```

2. Abrir en Android Studio la carpeta interna PolitecnicoOpenWorld/ y esperar a que termine la sincronización de Gradle.
3. Conectar el celular con depuración USB activada, seleccionarlo arriba y pulsar ▶ Run 'app'.
4. No aceptar la notificación Project update recommended / Start AGP Upgrade Assistant: el examen prohíbe actualizar dependencias.

### 2. Compilar y correr las pruebas unitarias
* El repositorio original ignora gradle/wrapper/gradle-wrapper.jar (dentro del .gitignore), así que ./gradlew falla con GradleWrapperMain. Para arreglar esto, se debe usar el panel Gradle de Android Studio: PolitecnicoOpenWorld → Tasks → other → testAndroidHostTest y testDebugUnitTest (ejecutar).
* Si las pruebas fallan con el error *no se ha encontrado o cargado la clase principal ...GradleWorkerMain*, la ruta del usuario de Windows tiene espacios o acentos (error detectado al tener dentro de una carpeta con un espacio el gradle *C:/Xime Noguerón*). Solución: File → Settings → Build, Execution, Deployment → Build Tools → Gradle → Gradle user home = D:\gradle-home, luego Sync Project with Gradle Files y volver a correr.
* Reporte de resultados: PolitecnicoOpenWorld\shared\build\reports\tests\testAndroidHostTest\index.html (buscar SfSystemBackTest).

### 3. Habilitar `adb` en la terminal para obtener parámetros de prueba.
* Color adb en el *PATH* desde una terminal, ejecutando el comando:
    ``` powershell
            Set-Alias adb "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
            adb devices
    ```
* Si esa ruta no existe, consultar sdk.dir con Get-Content local.properties y usar <sdk.dir>\platform-tools\adb.exe (escribiendo las barras normales).

### 4. Obtener datos del dispositivo para las fichas
 
| Dato | Con `adb` | Desde el celular (Samsung) |
|---|---|---|
| Modelo | `adb shell getprop ro.product.model` | Ajustes → Acerca del teléfono |
| Versión de Android | `adb shell getprop ro.build.version.release` | Ajustes → Acerca del teléfono → Información de software |
| Nivel de API | `adb shell getprop ro.build.version.sdk` | No se muestra; usar el comando |
| Versión de la app | `adb shell dumpsys package <paquete> \| findstr versionName` | Ajustes → Aplicaciones → POW → Versión |
| Paquete de la app | `adb shell pm list packages \| findstr pow` | — |
 
### 5. Alternar el tipo de navegación
 
Los casos alternan la navegación del sistema para cubrir ambos modos del botón Atrás: **TC-01 botones, TC-02 gestos, TC-03 botones, TC-04 gestos, TC-05 botones, TC-06 gestos**.
 
- **Samsung:** Ajustes → Pantalla → **Barra de navegación** → *Botones* o *Gestos de deslizamiento*.
- **Otras marcas / emulador:** Ajustes → Sistema → Gestos → Navegación del sistema.
- **Atrás con botones:** tocar ◁ (en Samsung puede estar a la derecha según el orden configurado).
- **Atrás con gestos:** deslizar desde el borde izquierdo o derecho hacia el centro.

## Matriz de trazabilidad

| Criterio / riesgo | Casos |
|---|---|
| AC1 — Atrás en pelea sin conexión abre el diálogo, congela la pelea y cada opción funciona | TC-01, TC-03, TC-06 |
| AC2 — Atrás con el diálogo abierto lo cierra; pulsaciones repetidas sin salida ni crash | TC-02 |
| AC3 — En línea el diálogo muestra solo Salir / Seguir peleando | `SfSystemBackTest` (sin prueba manual, ver ENV-04) |
| R1 — Orden de prioridad del handler y estado coherente tras el ciclo de vida | TC-03, `SfSystemBackTest` |
| R2 — Interferencia con otras pantallas | TC-04 |
| R3 — Pausa / guardado de arcade | TC-01, TC-03, TC-04 |
| R4 — Pulsaciones rápidas | TC-02 |
| R5 — Comportamiento según la configuración del dispositivo (gestos / botones, idioma) | TC-01 a TC-06 (alternan navegación), TC-06 (idioma) |
| Accesibilidad del diálogo de salida | TC-05 |

## TC-01 · Ruta feliz — Atrás durante una pelea offline

| Campo | Valor |
|---|---|
| Criterio / riesgo | AC1(Atrás abre el diálogo y congela la pelea; "Seguir peleando" reanuda), R3 (pausa del combate) |
| Autor / fecha | Moreno Noguerón Ximena / 30/09/2026 |
| SHA / versión app  | `c461a770` (base `7ed3253`) / package:ovh.gabrielhuav.pow |
| Dispositivo / API / config. | Samsung A155M / Android 16 (API 36.0) / navegación por **botones** |
| Precondiciones y datos | App instalada desde la rama `fix/1-sf-system-native-back-dialog` con ▶ Run desde Android Studio. Sin conexión en línea (modo offline). Modo **Titulación por combate**, peleador **Estudianta**, rival **Por defecto**, dificultad **Fácil**, escenario **Por defecto**. |

**Pasos**
1. Menú principal → HUELUM VS. GOYA → elegir peleador, rival, dificultad y escenario.
2. Esperar a que inicie el round y dejar que el reloj baje unos segundos hasta que empiece la pelea. Verificar el valor del reloj.
3. Pulsar Atrás del sistema (botón ◁ o gesto hacia afuera).
4. Observar el reloj del round durante 5 s con el diálogo abierto.
5. Pulsar "Seguir peleando".

**Resultado esperado:** en el paso 3 aparece el mismo diálogo de salida que abre la ✕; en el paso 4 el reloj no avanza; en el paso 5 el combate continúa donde estaba. El reloj no debe de modificarse, debe continuar desde donde se quedó.

**Resultado real:** El reloj se pausa justo al pulsar el botón Atrás del sistema, aunque nos quedemos dentro del cuadro de confirmación este se mantiene sin modificación, al seleccionar la opción *Seguir peleando* continúa con el mismo temporizador, vida y acción realizada por cada personaje.
**Estado:** Aprobado · **Evidencia:** [E_01](../resources/evidences/E_01.mp4) · **Defecto / decisión:** Ninguno.

---

## TC-02 · Límite — Atrás con el diálogo abierto y pulsaciones repetidas
 
| Campo | Valor |
|---|---|
| Criterio / riesgo | AC2 (Atrás con el diálogo abierto lo cierra; pulsaciones repetidas sin salida ni crash), R4 (doble navegación o crash) |
| Autor / fecha | Moreno Noguerón Ximena / 30/09/2026 |
| SHA / versión app  | `c461a770` (base `7ed3253`) / package:ovh.gabrielhuav.pow |
| Dispositivo / API / config. | Samsung A155M / Android 16 (API 36.0) / navegación por **gestos** |
| Precondiciones y datos | App instalada desde la rama `fix/1-sf-system-native-back-dialog`. Sin conexión en línea. Mismos datos que TC-01: modo ⟨…⟩, peleador ⟨…⟩, rival ⟨…⟩, dificultad ⟨…⟩, escenario ⟨…⟩. `adb logcat -c` antes de empezar. |
 
**Pasos**
1. Iniciar la pelea. Deslizar desde el borde (Atrás por gesto): se abre el diálogo.
2. Deslizar desde el borde otra vez.
3. Con la pelea de nuevo en curso, ejecutar tres Atrás seguidos en menos de 1 s.
4. Observar el estado final durante 5 s.
**Resultado esperado:** en el paso 1 aparece el diálogo con **Cambiar personaje**, **Salir** y **Seguir peleando**. En el paso 2 el diálogo se cierra y el combate continúa. En el paso 3 no hay crash ni salida al menú principal. En el paso 4 el estado es coherente: diálogo abierto o pelea en curso, nunca pantalla en blanco.

**Resultado real:** en el paso 1 aparece el diálogo con **Cambiar personaje**, **Salir** y **Seguir peleando**. En el paso 2 el diálogo se cierra y el combate continúa. En el paso 3 no hay crash ni salida al menú principal, en cambio se muestra el diálogo, se cierra y se vuelve a abrir. En el paso 4 el estado es coherente: diálogo abierto o pelea en curso, nunca pantalla en blanco.
**Estado:** Aprobado · **Evidencia:** [E-02](../resources/evidences/E_02.mp4) · **Defecto / decisión:** Ninguno.
 
---
 
## TC-03 · Navegación y estado — "Cambiar personaje", sesión de arcade y ciclo de vida
 
| Campo | Valor |
|---|---|
| Criterio / riesgo | AC1 (opción "Cambiar personaje"), R3 (guardado de la sesión de arcade), R1 (estado coherente tras el ciclo de vida) |
| Autor / fecha | Moreno Noguerón Ximena / 30/09/2026 |
| SHA / versión app  | `c461a770` (base `7ed3253`) / package:ovh.gabrielhuav.pow |
| Dispositivo / API / config. | Samsung A155M / Android 16 (API 36.0) / navegación por **botones** |
| Precondiciones y datos | Sin conexión en línea. Modo **Titulación por Combate** con una partida nueva; peleador **Estudiante**. |
 
**Pasos**
1. Entrar a Titulación por Combate → Nueva partida → iniciar el primer combate.
2. Tocar ◁: se abre el diálogo. Pulsar **Cambiar personaje**.
3. Observar a qué pantalla se regresa.
4. Volver a entrar a Titulación por Combate.
5. Elegir CONTINUAR (si aparece) e iniciar el combate. Tocar ◁ para abrir el diálogo.
6. Con el diálogo abierto, pulsar Inicio (○), esperar 5 s y regresar a la app desde Recientes.
**Resultado esperado:** en el paso 3 se regresa a la selección de personaje **sin salir** del modo de pelea. En el paso 4 aparece el diálogo de **nueva partida o CONTINUAR**, porque "Cambiar personaje" guarda la sesión igual que "Salir". En el paso 6, al volver, el combate sigue detenido: el diálogo está abierto o se muestra la pausa, sin pelea corriendo por detrás.
 
**Resultado real:** en el paso 3 se regresa a la selección de personaje sin salir del modo de pelea. Sin embargo, al elegir un nuevo personaje se reinicia la partida para incluir a dicho personaje, empezando una partida desde 0. Si se sale hasta el inicio y se regresa a Titulación por Combate sí se muestra el continuar partida, dado que no se cambió el personaje.
**Estado:** Aprobado · **Evidencia:** [E_03](../resources/evidences/E_03.mp4), [E-03_02](../resources/evidences/E_03_2.mp4) · **Defecto / decisión:** Al seleccionar "Cambiar personaje", el motor reinicia el estado de la escena de combate para instanciar las nuevas entidades, invocar sus métodos del ciclo de vida y vincular la secuencia de sprites (animaciones de movimiento y ataque).

 
---
 
## TC-04 · Regresión — Funciones cercanas conservan su comportamiento
 
| Campo | Valor |
|---|---|
| Criterio / riesgo | R2 (interferencia con otras pantallas), R3 (guardado de arcade con la ✕) |
| Autor / fecha | Moreno Noguerón Ximena / 30/09/2026 |
| SHA / versión app  | `c461a770` (base `7ed3253`) / package:ovh.gabrielhuav.pow |
| Dispositivo / API / config. | Samsung A15 / Android 16 (API 36.0) / navegación por **gestos** |
| Precondiciones y datos | Sin conexión en línea. Titulación por Combate con una partida iniciada (primer combate). Comparar contra el video de la versión base (E-04). |
 
**Pasos**
1. En la pelea, tocar la **✕** de la pantalla: aparece el diálogo. Pulsar **Salir**.
2. Volver a entrar a Titulación por Combate y elegir CONTINUAR.
3. En la selección de personaje (fuera del combate), deslizar desde el borde.
4. En el menú principal, entrar a Juego libre (mapa del mundo) y deslizar desde el borde.
**Resultado esperado:** en el paso 1 la ✕ abre el diálogo y "Salir" regresa al menú principal, igual que en la base. En el paso 2 aparece CONTINUAR y se retoma la partida. En el paso 3 el Atrás conserva el comportamiento de la versión base (fuera de alcance de este PR). En el paso 4 aparece el diálogo de salida propio del mapa del mundo, sin cambios.
 
**Resultado real:** en el paso 1, al darle ✕ se abre el cuadro de diálogo con las 3 opciones agregadas en dicho caso. Al entrar a Titulación por Combate y darle en Continuar pero realizar el gesto de salida, vuelve a salir el cuadro de diálogo implementado. Al entrar a juego libre (mapa del mundo) y salir con el mismo gesto, aparece el cuadro de diálogo original del juego, que contiene solo 2 opciones (Salir o Volver al Menú). 
**Estado:** Aprobado · **Evidencia:** [E-24](../resources/evidences/E_04.mp4) · **Defecto / decisión:** El alcance se limita a interceptar el evento del botón nativo de Regresar (Back) exclusivamente durante el modo "Titulación por Combate". Se logró la paridad funcional con el botón de salida ✕ existente en la interfaz del juego, desplegando el modal de confirmación correspondiente. Las escenas fuera de este alcance mantienen el comportamiento por defecto del sistema sin regresiones.
 
---
 
## TC-05 · Accesibilidad — Diálogo de salida con texto ampliado y TalkBack
 
| Campo | Valor |
|---|---|
| Criterio / riesgo | Accesibilidad del control afectado (diálogo de salida con tres botones) |
| Autor / fecha | Moreno Noguerón Ximena / 30/09/2026 |
| SHA / versión app  | `c461a770` (base `7ed3253`) / package:ovh.gabrielhuav.pow |
| Dispositivo / API / config. | Samsung A15 / Android 16 (API 36.0) / navegación por **botones** · Tamaño de fuente al máximo · TalkBack activo en los pasos 4–6 |
| Precondiciones y datos | Sin conexión en línea. Mismos datos que TC-01. |
 
**Pasos**
1. Ajustes → Pantalla → **Tamaño y estilo de fuente** → tamaño al máximo. Reabrir la app.
2. Iniciar una pelea y tocar ◁.
3. Verificar que los tres botones y el texto del diálogo se lean completos, sin cortes ni encimados.
**Resultado esperado:** con fuente máxima, los tres botones son legibles y tocables.

**Resultado real:** los controles táctiles del combate (joystick y botones X/Y/B/A) no se modifican, tampoco el botón ✕, sin embargo, el cuadro de diálogo no se muestra corresctamente debido al tamaño de fuente que se tiene en el dispositivo, dificultando la visualización correcta de las 3 opciones.
**Estado:** Observación identificada · **Evidencia:** [E-25](../resources/evidences/E_05.mp4) · **Defecto / decisión:** La lógica del flujo y la integridad de los controles del combate (joystick, botones X/Y/B/A y botón ✕) funcionan según lo esperado; sin embargo, la interfaz del cuadro de diálogo carece de adaptabilidad (auto-scaling / responsive layout) ante escalados de fuente a nivel de sistema. Se mantiene como un caso abierto para el desarrollo UI/UX para implementar restricciones de escalado de texto o un contenedor adaptable.
 
---
 
## TC-06 · Compatibilidad — Idioma del sistema en inglés
 
> Como TC-01 a TC-05 ya alternan la navegación por botones y por gestos, la condición distinta de este caso es el **idioma**. El cambio reutiliza el texto existente `sf_change_character`, que tiene versión en español y en inglés.
 
| Campo | Valor |
|---|---|
| Criterio / riesgo | R5 (comportamiento distinto según la configuración del dispositivo), AC1 en otro idioma |
| Autor / fecha | Moreno Noguerón Ximena / 30/09/2026 |
| SHA / versión app  | `c461a770` (base `7ed3253`) / package:ovh.gabrielhuav.pow |
| Dispositivo / API / config. | Samsung A15 / Android 16 (API 36.0) / navegación por **gestos** · Idioma del sistema: **English (United States)** |
| Precondiciones y datos | Sin conexión en línea. Mismos datos que TC-01. |
 
**Pasos**
1. Ajustes → Administración general → Idioma → agregar **English** y ponerlo primero.
2. Reabrir la app e iniciar una pelea.
3. Deslizar desde el borde y verificar los textos del diálogo.
4. Pulsar **Keep fighting** (o el texto equivalente) y confirmar que el combate continúa.
5. Abrir el diálogo otra vez y pulsar la opción de cambiar personaje.
 
**Resultado esperado:** el diálogo aparece en inglés con sus tres opciones, sin textos en español mezclados, y cada opción se comporta igual que en TC-01 y TC-03.

**Resultado real:** La localización al idioma inglés se ejecuta correctamente en la interfaz del cuadro de diálogo. Títulos y etiquetas de botones cambian de forma consistente sin presentar inconsistencias lingüísticas, conservando el comportamiento y flujo de navegación evaluados previamente.
**Estado:** Aprobada · **Evidencia:** [E-26](../resources/evidences/E_06.mp4) · **Defecto / decisión:** El botón continúa con su funcionalidad de forma correcta, además de que incluye el cambio a inglés de forma automática, sin interpolar texto en español.
 
---
 
## Hallazgos del entorno
 
| ID | Hallazgo | Impacto | Resolución / decisión |
|---|---|---|---|
| ENV-01 | `./gradlew` falla con `GradleWrapperMain`: el repositorio ignora `gradle-wrapper.jar` en `.gitignore`. | No se puede usar el wrapper desde la terminal. | Preexistente en `main`. Se usó el panel Gradle de Android Studio; el CI usa `setup-gradle` con `gradle-version: wrapper`. |
| ENV-02 | Las pruebas fallan con `GradleWorkerMain` porque la ruta del usuario de Windows contiene espacio y acento. | No se ejecutaban las pruebas unitarias locales. | Corregido: *Gradle user home* = `D:\gradle-home`. Después: 221 pruebas aprobadas. |
| ENV-03 | `adb` no se reconoce en PowerShell. | No se podían usar comandos de ADB. | `Set-Alias adb` a `platform-tools\adb.exe` del SDK. |
| ENV-04 | `google-services.json` no está presente (Firebase deshabilitado en el build). | No se puede probar el modo en línea. | Limitación registrada: la regla "sin Cambiar personaje en línea" queda cubierta por `SfSystemBackTest`, no por prueba manual. |
---