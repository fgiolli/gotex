# Gotex Online

Un MMORPG simple con vista desde arriba (top-down), hecho en **Godot 4.3**, que se juega **offline en el celular**.
El mundo está "poblado" por otros jugadores simulados que cazan monstruos, suben de nivel, vuelven al pueblo y escriben en el chat. Así se siente como un MMO sin necesitar internet.

## Cómo instalarlo en el celular (Android)

1. Entra a la pestaña **Releases** del repositorio (o **Actions → Build Android APK → Artifacts**).
2. Descarga `GotexOnline.apk` desde el celular.
3. Ábrelo y acepta "instalar apps de origen desconocido" si Android lo pide.
4. ¡A jugar! No necesita conexión. La partida se guarda sola.

Cada `push` al repositorio compila un APK nuevo con GitHub Actions (`.github/workflows/android.yml`).

## Cómo se juega

| Control | Acción |
|---|---|
| Joystick (mitad izquierda de la pantalla) | Moverte |
| **ATACAR** | Fija el monstruo más cercano y lo ataca (mantenlo para seguir peleando) |
| **GIRO** | Ataque en área alrededor tuyo (cuesta 20 MP) |
| **POCIÓN** | Cura 50% de la vida |
| **HOLA** | Saluda; los jugadores cercanos te responden |
| **TIENDA / MISIÓN** | Aparece al acercarte a un NPC |
| Tocar el minimapa | Menú con tus estadísticas y opción de borrar partida |

En PC: `WASD`/flechas para moverte, `Espacio` atacar, `Q` giro, `E` poción, `F` hablar, `T` saludar, `M`/`Esc` menú.

## El mundo

- **Pueblo de Gotex** (centro): zona segura, te curas rápido. Aquí están **Mara la Comerciante** (pociones y mejoras de espada/armadura) y el **Capitán Rolo** (misiones).
- **Pradera Verde** (Nv 1-3): slimes.
- **Bosque Oscuro** (Nv 4-7): lobos.
- **Ruinas Antiguas** (Nv 8-12): esqueletos.
- **Tierras Malditas** (Nv 13+, esquinas del mapa): demonios, y el **Rey Demonio** (Nv 20) en la esquina sureste.

Al morir reapareces en el pueblo y pierdes el 10% de tu oro.

## Abrirlo en Godot

Abre la carpeta con Godot 4.3 o superior y pulsa *Play*. Para exportar tú mismo a Android necesitas las plantillas de exportación y el SDK de Android configurados en el editor; el preset ya está en `export_presets.cfg`.

Todo el arte se dibuja por código (no hay imágenes), así que el proyecto es muy liviano.

## Estructura

```
main.tscn              escena principal
scripts/main.gd        mundo: mapa, aparición de monstruos, eventos, guardado
scripts/game_data.gd   datos: zonas, monstruos, nombres y frases del chat
scripts/entity.gd      base de personajes (vida, daño, dibujo)
scripts/player.gd      jugador
scripts/enemy.gd       monstruos
scripts/bot.gd         jugadores simulados
scripts/npc.gd         comerciante y capitán
scripts/hud.gd         controles táctiles, barras, minimapa, chat y ventanas
scripts/ground.gd, decor.gd, effect.gd, floating_text.gd   gráficos
```
