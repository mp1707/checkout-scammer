# Project Settings fuer Pixel-Font Rendering

Dieses Dokument haelt die verbindlichen Godot-Settings fuer Checkout Scammer und zukuenftige Projekte mit `PixelOperator8.ttf` fest. Der wichtigste Kontext: Im Godot-Editor kann die Schrift klar aussehen, waehrend sie im gestarteten Spiel unleserlich wird, wenn das Spiel erst in eine niedrige Viewport-Aufloesung rendert und danach hochskaliert.

## Ziel

- Interne Authoring-Aufloesung: `640x360`.
- Entwicklungsfenster: `1280x720`, also exakt `2x`.
- Pixel-Sprites bleiben scharf.
- Dynamische TTF-Pixel-Fonts wie `PixelOperator8.ttf` bleiben auch im gestarteten Spiel lesbar.
- Freie Fenster-Skalierung darf keine krummen Faktoren wie `3.2x` erzeugen.

## Wichtigste Regel

Fuer dieses Projekt muss Stretch Mode auf `canvas_items` stehen, nicht auf `viewport`.

`viewport` rendert die komplette Szene zuerst in die interne Aufloesung, hier `640x360`, und skaliert danach das fertige Bild. Das ist fuer reine Pixel-Sprite-Spiele oft okay, macht aber kleine dynamische TTF-Pixel-Fonts blockig oder unlesbar. Der Editor zeigt die Szene anders an und kann dadurch klar aussehen, obwohl der Game-Run falsch wirkt.

`canvas_items` skaliert Canvas-Items auf die finale Fensteraufloesung. Dadurch wird der Font in der finalen Ausgabe gerendert, waehrend Sprites ueber nearest filtering weiterhin harte Pixel behalten.

## Project Settings

Diese Werte muessen in `project.godot` stehen:

```ini
[display]

window/dpi/allow_hidpi=true
window/size/mode=0
window/size/viewport_width=640
window/size/viewport_height=360
window/size/window_width_override=1280
window/size/window_height_override=720
window/size/resizable=false
window/size/maximize_disabled=true
window/stretch/mode="canvas_items"
window/stretch/aspect="keep"
window/stretch/scale=1.0
window/stretch/scale_mode="integer"

[rendering]

textures/canvas_textures/default_texture_filter=0
2d/snap/snap_2d_transforms_to_pixel=true
2d/snap/snap_2d_vertices_to_pixel=true
```

### Warum diese Werte

- `allow_hidpi=true`: Verhindert Low-DPI/Retina-Fallen auf macOS und erlaubt eine scharfe Ausgabe auf HiDPI-Displays.
- `viewport_width=640`, `viewport_height=360`: Die feste interne Design-Aufloesung.
- `window_width_override=1280`, `window_height_override=720`: Default-Run-Fenster ist exakt `2x`.
- `resizable=false`: Verhindert zufaellige Fensterfaktoren wie `1366x768` oder `2048x1152`.
- `maximize_disabled=true`: Verhindert maximierte krumme Fensterfaktoren.
- `stretch/mode="canvas_items"`: Kritisch fuer lesbare dynamische TTF-Pixel-Fonts.
- `stretch/aspect="keep"`: Seitenverhaeltnis bleibt erhalten.
- `stretch/scale_mode="integer"`: Nur ganze Skalierungsfaktoren, mit Letterboxing/Pillarboxing wenn noetig.
- `default_texture_filter=0`: Global nearest filtering fuer Canvas-Texturen.
- `snap_2d_transforms_to_pixel=true`: 2D-Transforms landen auf ganzen Pixeln.
- `snap_2d_vertices_to_pixel=true`: 2D-Vertices landen auf ganzen Pixeln.

## Runtime Guard

Das Projekt nutzt einen kleinen Autoload-Service:

```ini
[autoload]

PixelDisplayService="*res://scripts/autoload/pixel_display_service.gd"
```

Der Service setzt beim Start dieselben Werte noch einmal auf dem Root-Window:

```gdscript
root_window.content_scale_size = Vector2i(640, 360)
root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
root_window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
root_window.content_scale_factor = 1.0
```

Ausserhalb der Editor-Einbettung erzwingt er ausserdem ein `1280x720` Fenster und deaktiviert Resize/Maximize. Das ist wichtig, weil in Godot oft direkt eine einzelne Szene gestartet wird. Der Fix darf daher nicht nur in `boot.gd` liegen.

## Font Import Settings

Fuer `assets/fonts/PixelOperator8.ttf` muessen diese Import-Werte gelten:

```ini
antialiasing=0
generate_mipmaps=false
hinting=0
subpixel_positioning=0
keep_rounding_remainders=false
oversampling=0.0
multichannel_signed_distance_field=false
```

### Warum diese Werte

- `antialiasing=0`: Keine geglaetteten Kanten bei Pixel-Fonts.
- `generate_mipmaps=false`: Keine unscharfen Zwischenstufen.
- `hinting=0`: Keine Font-Hinting-Korrektur, die Pixel-Glyphen veraendert.
- `subpixel_positioning=0`: Keine Subpixel-Positionen fuer Glyphen.
- `keep_rounding_remainders=false`: Keine Positionsreste, die Text ueber mehrere Glyphen unruhig machen.
- `oversampling=0.0`: Keine automatische hochaufgeloeste Font-Rasterung mit spaeterer Skalierung.
- `multichannel_signed_distance_field=false`: Kein MSDF fuer diese Pixel-Schrift.

## Font Groessen

`PixelOperator8.ttf` soll nur in klaren Vielfachen genutzt werden:

- Kleine UI/Receipt-Zeilen: `8`
- Normale UI: `16`
- Titel/grosse Zahlen: `24`
- Sehr grosse Titel: `32`

Diese Groessen vermeiden krumme Glyphenraster. Problematische Zwischenwerte sind z. B. `9`, `10`, `11`, `14`, `18`, `20`, `28`.

Alle Fontgroessen gehoeren in Theme-Resources, nicht lokal in einzelne Szenen. Fuer Checkout Scammer ist das `CheckoutThemeResource`.

## Editor Game View

Die lokale Editor-Datei `.godot/editor/project_metadata.cfg` ist nicht versioniert, kann aber beim Debuggen relevant sein:

```ini
[game_view]

embed_on_play=false
embed_size_mode=1
```

Empfehlung:

- Fuer Pixel-Font-Checks lieber ein echtes Spiel-Fenster starten, nicht die eingebettete Game View.
- Wenn Game View benutzt wird, muss die eingebettete Groesse auf Fixed Size stehen.
- Screenshots mit physischer Groesse `2048x1152` bei `640x360` intern sind verdachtig, weil das `3.2x` ist. Das ist kein Integer-Scale.

## Sprite Import Settings

Fuer Pixel-Art-Sprites gilt:

- Filter: Off/Nearest.
- Mipmaps: Off.
- Keine automatische Skalierung in der Szene.
- Produkt-Runtime-Assets nutzen die `32px` Atlas-Regionen aus `assets/textures/products/products_sheet.png`.
- Produkte haben kein separates Highlight-/Outline-Sheet.
- Coupon-Actors nutzen vorerst das gemeinsame Coupon-Sprite aus demselben Sheet.

Wenn ein Sprite scharf im Editor, aber matschig im Spiel wirkt, zuerst pruefen:

- Ist die Import-Textur auf nearest?
- Hat der Node eine krumme Scale wie `0.9` oder `1.25`?
- Liegt der Parent auf halben Pixeln?
- Wird das Fenster mit einem nicht-ganzzahligen Faktor skaliert?

## Layout Regeln

- Control-Positionen und Groessen sollen ganze Pixelwerte haben.
- Text und Parent-Control duerfen nicht auf `x.5` oder `y.5` liegen.
- Keine freie Font-Skalierung ueber Node-Scale.
- Textgroessen immer ueber Theme-Font-Size setzen.
- Pixel-Sprites nicht ueber Node-Scale vergroessern, sondern passende Asset-Region oder passende Fenster-Skalierung nutzen.

## Debug Checklist

Wenn die Schrift im Editor lesbar ist, aber im Spiel nicht:

1. Pruefen, ob `window/stretch/mode="canvas_items"` aktiv ist.
2. Pruefen, ob `PixelDisplayService` als Autoload geladen wird.
3. Pruefen, ob die Ausgabe ein ganzzahliger Faktor von `640x360` ist: `1280x720`, `1920x1080`, `2560x1440`, `3840x2160`.
4. Pruefen, ob das Fenster frei resized oder maximiert wurde.
5. Pruefen, ob der Font-Import Antialiasing, Subpixel, Hinting, Mipmaps und Oversampling deaktiviert hat.
6. Pruefen, ob die Textgroesse `8`, `16`, `24` oder `32` ist.
7. Pruefen, ob Label oder Parent-Control auf ganzen Pixeln liegen.
8. Pruefen, ob der Text lokal ueber `scale` vergroessert oder verkleinert wird.

## Bekannte Falle

Nicht diese Kombination verwenden:

```ini
window/stretch/mode="viewport"
window/stretch/aspect="keep"
window/stretch/scale_mode="integer"
```

Auch wenn das fuer Pixel-Art logisch klingt, rendert es die TTF-Schrift in der niedrigen internen Aufloesung und skaliert danach das ganze Bild. Das war die Ursache fuer den Unterschied zwischen klarer Editor-Ansicht und schlechter Spiel-Ansicht.
