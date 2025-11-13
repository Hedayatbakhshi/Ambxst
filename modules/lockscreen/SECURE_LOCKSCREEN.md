# Secure Lockscreen Implementation

## Resumen

La implementación segura del lockscreen en Ambxst utiliza el protocolo Wayland Session Lock (`WlSessionLock`) en lugar de una simple capa overlay. Esto previene que matar el proceso de Quickshell desbloquee la pantalla.

## Arquitectura

### Componentes principales:

1. **shell.qml - WlSessionLock**
   - Gestiona el `WlSessionLock` directamente en el ShellRoot
   - Crea superficies de bloqueo para cada pantalla usando `WlSessionLockSurface`
   - Binding bidireccional: `locked: GlobalStates.lockscreenVisible`
   - Cuando `GlobalStates.lockscreenVisible = true` → compositor bloquea
   - Cuando `GlobalStates.lockscreenVisible = false` → compositor desbloquea

2. **LockScreenSurface.qml**
   - UI renderizada en cada `WlSessionLockSurface`
   - Contiene el input de password, avatar, player, etc.
   - Maneja autenticación PAM
   - Cuando auth exitosa: `GlobalStates.lockscreenVisible = false`

3. **LockScreen.qml** (legacy - NO USAR)
   - Componente antiguo usando `PanelWindow` + `WlrLayershell`
   - **NO SEGURO** - se mantiene por compatibilidad pero no debería usarse

## Autenticación PAM

### Binario ambxst-auth

El lockscreen utiliza un binario compilado en C que realiza la autenticación PAM:

- **Ubicación**: `modules/lockscreen/auth.c`
- **Compilación**: `modules/lockscreen/build.sh`
- **Requiere**: PAM headers (`libpam`)

### Instalación

#### En NixOS

El flake incluye el binario automáticamente. Solo necesitas importar el módulo:

```nix
# En tu configuration.nix
{ inputs.ambxst.url = "github:Axenide/Ambxst";
  imports = [ inputs.ambxst.nixosModules.default ];
}
```

#### En sistemas non-NixOS

El script `install.sh` compila el binario localmente y lo copia a `~/.local/bin/`. No requiere configuración adicional.

### ¿Por qué no necesita permisos especiales?

El binario `ambxst-auth` **no necesita capabilities ni setuid** porque:

1. No lee `/etc/shadow` directamente
2. Llama a PAM, que usa su propio helper privilegiado (`/usr/bin/unix_chkpwd`)
3. El helper de PAM ya tiene setuid root configurado por el sistema
4. Tu binario solo se comunica con PAM y recibe el resultado

```
ambxst-auth → pam_authenticate() → pam_unix.so → unix_chkpwd (setuid) → /etc/shadow
```

## Seguridad: ¿Por qué es seguro?

### Protocolo WlSessionLock

`WlSessionLock` es un protocolo Wayland diseñado específicamente para lockscreens seguros:

- Cuando `locked: true`, el compositor **bloquea todas las demás ventanas y captura de input**
- Si el cliente (Quickshell) se mata/crashea, el compositor **mantiene el bloqueo** y muestra un fallback lock
- Solo se desbloquea cuando el cliente llama explícitamente `locked: false`

Esto es diferente de usar una simple overlay layer (como `WlrLayershell.layer: WlrLayer.Overlay`):
- ❌ Overlay: Solo es una ventana encima - matar el proceso = desbloqueo
- ✅ Session Lock: El compositor mantiene el bloqueo incluso si el proceso muere

### Flujo de bloqueo/desbloqueo

**Bloquear:**
```qml
// Desde GlobalShortcuts o cualquier componente
GlobalStates.lockscreenVisible = true
  └─> WlSessionLock.locked = true (binding automático)
      └─> Compositor bloquea todo
```

**Desbloquear (después de auth exitosa):**
```qml
// Desde LockScreenSurface tras PAM auth exitosa
GlobalStates.lockscreenVisible = false
  └─> WlSessionLock.locked = false (binding automático)
      └─> Compositor desbloquea
```

**IMPORTANTE:** El binding automático asegura que el compositor siempre se sincroniza con el estado de UI.

## Implementación técnica

### Solución al parpadeo blanco

El lockscreen implementa un sistema de estados para prevenir flashes blancos:

```qml
property bool captureReady: false  // Screen capture completada
property bool ready: false          // Listo para animar

color: (captureReady && !unlocking) ? "transparent" : "black"
```

**Flujo de entrada:**
1. Superficie se crea con fondo negro
2. Captura de pantalla inmediata
3. `captureReady = true` → fondo transparente
4. `ready = true` → inicia animaciones (blur, slide-in)

**Flujo de salida:**
1. Auth exitosa → `unlocking = true`, `ready = false`
2. Animación de salida (elements slide-out)
3. Fondo vuelve a negro
4. Después de `Config.animDuration` → unlock real

### Animaciones

**Entrada (slide-in):**
- Player: desliza desde izquierda `x: -width → 0`
- Password: desliza desde abajo `y: height → 0`
- Blur: `0 → 1` con zoom `1.0 → 1.1`
- Duración: `Config.animDuration` (OutCubic)

**Salida (slide-out):**
- Player: desliza hacia izquierda `x: 0 → -width`
- Password: desliza hacia abajo `y: 0 → height`
- Blur: `1 → 0` con zoom `1.1 → 1.0`
- Duración: `Config.animDuration` antes de unlock

### Captura de pantalla

```qml
ScreencopyView {
    captureSource: {
        if (Window.window?.screen) return Window.window.screen;
        return Quickshell.screens[0]; // Fallback
    }
}
```

La captura se dispara en `Component.onCompleted` y usa la pantalla del `Window` actual o la primera disponible como fallback.

## Uso

### Bloquear la pantalla
```qml
GlobalStates.lockscreenVisible = true
```

### Desbloquear (solo desde LockScreenSurface tras auth)
```qml
GlobalStates.lockscreenVisible = false
```

### Verificar si está bloqueada
```qml
if (GlobalStates.lockscreenVisible) {
    // Pantalla bloqueada
}
```

## Integración con sistema existente

- `GlobalStates.lockscreenVisible` mantiene el estado de bloqueo
- `GlobalShortcuts` cambia el estado directamente
- El PAM auth existente funciona sin cambios
- Las animaciones y efectos visuales se preservan
- `WlSessionLock.locked` binding sincroniza automáticamente con GlobalStates

## Comparación con "end-4/dots-hyprland"

Ambas implementaciones usan la misma arquitectura base:
- `WlSessionLock` + `WlSessionLockSurface`
- Mismo patrón de unlock antes de quit
- PAM para autenticación

Diferencias:
- end-4: Usa `Quickshell.Services.Pam.PamContext` directamente
- Ambxst: Usa script bash con PAM (más flexible para faillock, etc.)
- end-4: Usa singleton separado para contexto
- Ambxst: `WlSessionLock` directamente en shell.qml (más simple)

## Prueba de seguridad

Para verificar que el lockscreen es seguro:

```bash
# 1. Iniciar Ambxst
qs -p shell.qml

# 2. Bloquear pantalla usando tu shortcut de Hyprland configurado en:
#    ~/.config/hypr/hyprland.conf
#    Ejemplo: bind = $mainMod, L, global, ambxst:lockscreen

# 3. Intentar matar el proceso desde otra terminal/TTY
killall quickshell

# Resultado esperado:
# - El proceso de Quickshell muere
# - El compositor muestra un lock básico/fallback
# - La pantalla NO se desbloquea
# - Solo se puede desbloquear reiniciando el compositor o desde otro lockscreen
```

### Cómo configurar el shortcut en Hyprland

Agrega en `~/.config/hypr/hyprland.conf`:

```conf
# Lockscreen seguro
bind = $mainMod, L, global, ambxst:lockscreen
```

Luego recarga Hyprland: `hyprctl reload`

## Referencias

- [Ejemplo oficial Quickshell](https://github.com/quickshell-mirror/quickshell-examples/tree/master/lockscreen)
- [end-4/dots-hyprland Lock.qml](https://github.com/end-4/dots-hyprland)
- [Wayland Session Lock Protocol](https://wayland.app/protocols/ext-session-lock-v1)
