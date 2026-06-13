# Checkout Scammer - Architektur

Stand: 2026-06-12

Diese Datei ist die verbindliche technische Grundlage fuer Checkout Scammer. Aenderungen an dieser Architektur brauchen vorherige Ruecksprache mit Marco, wenn sie Ownership, Datenfluss, Szenenstruktur, Autoloads, UI-Architektur oder zentrale Gameplay-Systeme betreffen.

## Ziele

- Godot 4.6, 2D Pixel-Art, interne Authoring-Aufloesung `640x360`.
- Ein 1-Screen-Spiel mit klaren, editorseitig bearbeitbaren Bereichen: linke Statusleiste, Kassentisch, rechte Upgrade-Leiste.
- Der Scanner-Moment ist der wichtigste Kern: Drag von rechts nach links, Beep, Geldfeedback im Kassendisplay, Scannerflash, Produktfeedback.
- Gameplay-Regeln bleiben testbar und UI-unabhaengig.
- Szenen bleiben Authoring-Flaechen. Layouts, Slots, Drop-Zonen, Hitboxen, Marker, AnimationPlayer und UI-Struktur muessen im Godot-Editor sichtbar und bearbeitbar bleiben.
- Code erzeugt keine kompletten Gameplay- oder UI-Baeume von Grund auf. Code steuert vorhandene Szenen, befuellt vorbereitete Container und instanziiert nur fertige `PackedScene`s.
- Konfigurierbare Inhalte liegen als `Resource`-Definitionen in `content/`, nicht als verstreute Konstanten im Code.
- Runtime-State ist getrennt von Definition-Resources.

## Schichten

### Application

Ordner: `scripts/application`, `scenes/application`

Verantwortung:

- Bootstrapping, Szenenwechsel, Run-Lifecycle, Save/Load.
- Content laden und validieren.
- Simulation-Systeme koordinieren.
- UI-Intents entgegennehmen und daraus Simulation-Commands ausloesen.

Haupttypen:

- `GameApp`: Einstiegspunkt der Spielszene; laedt und validiert Content.
- `RunController`: duenne Verdrahtungsschicht. Verbindet Presentation-Signale mit den Handlern, haelt selbst keine Spiellogik.
- `RunContext`: gemeinsamer Zustand einer Session (Registry, RunState, Systeme, Presentation-Referenzen) fuer alle Handler.
- `RunFlowController`: Run-/Tages-/Kunden-Lifecycle, Win/Lose und Dialog-Zustandsmaschine.
- `CheckoutInteractionHandler`: uebersetzt Tisch-Intents (Scan, Wiegen, Bag, Trash, Sticker) in Simulation-Aufrufe und Feedback.
- `ShopHandler`: Coupon-Kauf, Sortiment-Upgrade, Sticker-Popup.
- `HudStateUpdater`: synchronisiert Run-State in das HUD (Summary, Buttons, Tooltips).
- `ContentRegistry`: zentraler Zugriff auf Produkt-, Coupon-, Upgrade-, Balance-, Customer-Type- und UI-Resources.
- `SaveService`: spaeterer Speicher-/Ladepunkt, ohne Gameplay-Regeln.

Wenn der Datenfluss unten von "RunController" spricht, ist die Application-Schicht insgesamt gemeint; die konkrete Arbeit passiert in Flow-, Interaction- und Shop-Handler.

Autoloads bleiben klein. Der einzige direkt gesetzte Autoload in der Projektbasis ist `PixelDisplayService`, weil er die in `project-settings.md` definierten Window-/Scale-Regeln bei jedem Szenenstart erzwingt.

### Simulation

Ordner: `scripts/gameplay/systems`, `scripts/gameplay/generation`

Simulation trifft Regelentscheidungen und mutiert Runtime-State. Sie hat keine Abhaengigkeit auf UI-Nodes.

Kernsysteme:

- `VisibleObjectQueueSystem`: Kunden-Queue, vier sichtbare Objekt-Slots, Nachruecken erst nach Verarbeitung, Coupon-Objekt als optionaler erster sichtbarer Eintrag.
- `ScanSystem`: Scan-Gueltigkeit, Scannerzone, Bewegungsrichtung, Rotation/Hit-Details, wiegbare-Produkte-Ablehnung und gemeinsamer Charge-/Caught-Pfad fuer Scan und Wiegen.
- `EconomySystem`: Festpreiswerte, Gewichtspreise, Rabatte, Sticker-Multiplikatoren, Rundung, Payout.
- `CouponSystem`: Aktivierung, Verzoegerung bis zum naechsten Kunden, Dauer bis Tagesende, Coupon-Scam.
- `ComboSystem`: spaetere Multi-Scan-/Juice-/Reward-Fenster.
- `SuspicionSystem`: Caught-Rolls, kundentyp-spezifische Suspicion-Stufen, dreistufiger Customer-Signal-Zustand und Start-Suspicion-Boni.
- `UpgradeSystem`: Sortiment-Level, Upgrade-Kosten, Wirkung ab naechstem Kunden.
- `StickerSystem`: Tagesinventar, Refill, Verbrauch und Anwendbarkeit von Stickern auf Produkte.
- `CustomerGenerator`: deterministische Kundentyp-, Produkt- und Obst-Gewichtsfolgen per Seed. Der erste Kunde eines Runs ist immer Jimmy; danach werden Kundentypen zufaellig aus `CustomerTypeResource`-Content gezogen, ohne denselben Typ direkt zu wiederholen.
- `RunSchedule`: gemeinsame Kalender-Helfer ("wirkt ab dem naechsten Kunden") fuer Coupons und Upgrades.

Simulation arbeitet mit expliziten Datenobjekten wie `ScanRequest`, `ScanResult`, `PayoutOutcome`, `VisibleObjectSlot`, `RunState`, `CustomerState`, `ProductInstance`, `CouponInstance`, `StickerResource`, `StickerInstance` und `StickerInventoryEntry`. `CustomerState` referenziert den aktiven `CustomerTypeResource`; `RunState` haelt den letzten Kundentyp und den gestapelten Start-Suspicion-Bonus fuer den naechsten Kunden.

### Presentation

Ordner: `scenes/gameplay`, `scenes/ui`, `scripts/gameplay/actors`, `scripts/gameplay/components`, `scripts/ui`, `scripts/vfx`

Presentation zeigt Zustand, sammelt Input und sendet Intents. Sie mutiert keinen Run-State direkt.

Wichtige Szenen:

- `TableActor` (Basisklasse): gemeinsame Drag-/Slot-/Finish-API fuer Produkt- und Coupon-Actors.
- `CheckoutTable`: mittlerer Kassentisch als Root der spielbaren Flaeche.
- `ProductScatterView`: verstreute sichtbare Objekt-Slots rechts neben dem Scanner, Spawn-von-rechts-Animationen, Slot-Marker.
- `ProductActor`: Drag, Rotation, Scannerkontakt, Schatten und Produktfeedback.
- `ScannerStation`: Scannerstrahl, Hitbox/Area2D, Flash/SFX-Anker. Der Scannerkoerper ist im Tisch-Sprite enthalten.
- `RegisterDisplay`: editorseitig platzierbares Kassendisplay im Tisch, zeigt den offenen Betrag des aktuell gebuchten Produktes.
- `BagZone`: Drop-Zone fuer finalen Verkauf.
- `TrashZone`: Drop-Zone fuer Produkt-/Coupon-Entsorgung.
- `ScaleStation`: editorseitig platzierte Waagen-Drop-Zone fuer wiegbare Produkte, mit `waage_sheet.png`-Press-Frames.
- `CustomerHandView`: typisierte Customer-Signal-View. Sie zeigt fuer den aktiven Kundentyp die drei Suspicion-Texturen gruen, gelb und rot und stellt den Mouseover-Tooltip bereit.
- `HudRoot`: linke Statusleiste, rechte Upgrade-Leiste, Dialoge, Coupon-Popup und Sticker-Popup.
- `StickerPopup` und `StickerToken`: rechtes UI-Popup mit physischen draggable Sticker-Tokens.

Node-Pfade werden nicht quer durch die Szene gesucht. Parent/Child-Kommunikation nutzt lokale Signals, `@export`-Referenzen oder kleine Controller-APIs.

### Content

Ordner: `content`

Alles Konfigurierbare wird als Resource modelliert:

- `GameBalanceResource`: Startgeld, Tagesmiete, Run-Laenge, Kunden pro Tag, Produkte pro Kunde, sichtbare Objekt-Slots.
- `ProductLineResource`: Produktlinie wie Obst oder Snacks.
- `ProductVariantResource`: einzelne Produkte mit ID, Verkaufsart, Festpreis oder Kilopreis, Gewichtsspanne, Gewichtsverteilung, Sprite-Skalierung, Gewichtung, Sortiment-Level und Texture.
- `CouponResource`: Zielprodukt/-linie, Rabatt, Kaufpreis, Gewichtungsbonus, Dauer.
- `StickerResource`: Sticker-ID, Tooltip, Texture, Multiplikator, Zielart und taeglicher Refill.
- `UpgradeResource`: Sortiment-Level-Up und spaetere Upgrades.
- `CustomerTypeResource`: Kundentyp-ID, Anzeigename, Tooltip, Preisperzentil-Bereich, Suspicion-Stufen, Caught-Strafe und drei Stage-Texturen fuer gruen/gelb/rot.
- `SuspicionCurveResource`: optionaler Migrations-/Fallback-Default. Die verbindlichen Suspicion-Werte liegen in `CustomerTypeResource`.
- `CheckoutThemeResource`: Font, 9-Slice-Panel-Texture, Fontgroessen, Endesga-64-UI-Farben.

Definition-Resources sind immutable Runtime-Definitionen. Veraenderbarer Zustand liegt in Runtime-Instanzen.

### Kundentyp-Content

`CustomerTypeResource` ist die zentrale Definition fuer Kundentypen. Sie ersetzt geskriptete Kundenfolgen als Standardweg fuer Kundenverhalten.

Pflichtfelder:

- stabile `id`, z. B. `jimmy`, `margaret`, `chad`, `doris`
- player-sichtbarer englischer `display_name`
- player-sichtbarer englischer Tooltip-Text
- `price_percentile_min` und `price_percentile_max` fuer die Produktauswahl im aktuell freigeschalteten Sortiment
- `suspicion_stage_percentages` als streng aufsteigende Werte im Bereich `0..100`
- `caught_penalty_kind` als `enum`, nicht als String
- optionale Strafwerte wie `cash_penalty_product_value_multiplier_percent` oder `next_customer_suspicion_bonus_percent`
- `green_texture`, `yellow_texture`, `red_texture`

Produkt-Preiswerte fuer Perzentile:

- Festpreis-Produkte nutzen `ProductVariantResource.price_cents`.
- Wiegbare Produkte nutzen den erwarteten Stueckpreis aus durchschnittlichem generierten Gewicht und `price_per_kg_cents`.
- Die Perzentil-Pools werden pro aktuellem Sortiment-Level berechnet, damit Sortiment-Upgrades die Grenzen automatisch verschieben.

Kundentyp-Defaults:

- Jimmy: billigste `30%`, Suspicion `0 -> 20 -> 45 -> 70`, keine Zusatzstrafe.
- Margaret: gesamtes Sortiment, Suspicion `10 -> 50 -> 75 -> 90`, keine Zusatzstrafe.
- Chad: teuerste `30%`, Suspicion `30 -> 65 -> 85 -> 95`, Produktwert-Geldabzug mit `0`-Cap.
- Doris: billigste `60%`, Suspicion `5 -> 30 -> 55 -> 75`, `+20%` Start-Suspicion fuer den naechsten Kunden pro Caught.

## Editor-Authoring-Regeln

Gameplay- und UI-Szenen sind die primaere Authoring-Flaeche. Alles, was Marco im Editor sehen, verschieben, skalieren, animieren oder als Drop-/Hit-Zone feinjustieren koennen soll, gehoert als Node in eine `.tscn`-Szene.

Verbindlich sichtbar in Szenen:

- Layout-Container fuer linke Statusleiste, Kassentisch und rechte Upgrade-Leiste.
- Slot-Marker und Spawn-/Exit-Marker fuer die verstreute Produktflaeche rechts neben dem Scanner.
- Scanner-Shape, Scannerstrahl, Scanner-Hitbox und Feedback-Anker.
- Bag- und Trash-Drop-Zonen inklusive Collision-/Area-Nodes.
- Waagen-Drop-Zone, Waagen-Sprite, DropAnchor und Press-Feedback.
- ProductActor-Root, Sprite-Anker, Schatten-Anker und Drag-Feedback-Anker.
- ProductActor-StickerLayer und vorbereitete Sticker-Visual-Scene.
- Kassendisplay-Root und Betrag-Label fuer die offene Summe des aktuell gebuchten Produktes.
- Kunden-Signal-Anker, Kundentyp-Sprite, Tooltip-Hitbox und AnimationPlayer.
- HUD-Panels, Dialoge, Coupon-/Sticker-Popups, Buttons und Tooltip-Anker.
- AnimationPlayer, Marker2D, Area2D, CollisionShape2D und VFX-Anker fuer alle wiederkehrenden Interaktionen.

Code darf:

- exportierte Node-Referenzen, `PackedScene`s und Resource-Definitionen nutzen.
- vorbereitete Container befuellen.
- fertige Product-, Coupon-, Popup- oder VFX-Scenes instanziieren.
- sichtbare Nodes mit State-Daten aktualisieren.
- lokale Signals verbinden, wenn die Ownership klar bleibt.

Code darf nicht:

- das komplette HUD, den Kassentisch, die Produktflaeche oder die Upgrade-Leiste rein zur Laufzeit bauen.
- Drop-Zonen, Hitboxen, Slot-Positionen oder Scanner-Geometrie versteckt per Code definieren, wenn sie editorseitig bearbeitbar sein sollen.
- UI-Strukturen ueber ad-hoc `new()`-Baeume erzeugen, statt vorbereitete Panel-/Popup-/Button-Szenen zu nutzen.
- Animationen oder VFX-Positionen nur als magische Zahlen im Script halten.

Wenn eine Runtime-Erzeugung noetig ist, muss sie eine vorbereitete Scene instanziieren und in einen editorseitig vorhandenen Container oder Marker einsetzen. Beispiele: neue Produkte auf vorhandenen Objekt-Slots, Coin-VFX an vorhandenen VFX-Ankern, Dialoginstanzen in einem vorhandenen Dialog-Layer.

## Szene-Ownership

Eine Szene hat genau eine Hauptaufgabe:

- `ProductActor`: sammelt Drag-/Rotate-Input, meldet Scannerkontakt und zeigt Produktzustand.
- `ScannerStation`: meldet Scannerkontakte und zeigt Scannerfeedback.
- `ProductScatterView`: zeigt Slots verstreut rechts neben dem Scanner und animiert neue Objekte von rechts herein.
- `BagZone` und `TrashZone`: melden Drop-Intents.
- `ScaleStation`: akzeptiert genau ein wiegbares Produkt visuell, spielt Waagenfeedback und meldet Drop-/Remove-Intents.
- `CustomerHandView`: zeigt den aktiven Kundentyp, wechselt dessen gruen/gelb/rot-Textur nach Suspicion-Stufe, spielt Alert-/Caught-Feedback und liefert den Kundentyp-Tooltip.
- `StickerPopup`: zeigt verfuegbare Sticker-Instanzen und sendet Drag-Release-Intents mit Sticker-ID und Drop-Position.
- `HudRoot` und Panels: zeigen Run-State und senden Button-Intents.
- `RunController`: nimmt Intents an, ruft Simulation-Systeme auf und veroeffentlicht neuen State fuer Presentation.

Keine UI-Komponente bucht Geld, scannt Produkte, veraendert Suspicion oder aktiviert Coupons eigenmaechtig.

## Gameplay-Datenfluss

### Kundenstart

1. `RunController` fordert beim `CustomerGenerator` den naechsten Kunden an.
2. `CustomerGenerator` waehlt den `CustomerTypeResource`: Run-Kunde 1 ist immer Jimmy, alle weiteren Kunden werden deterministisch zufaellig ohne direkte Typ-Wiederholung gezogen.
3. `CustomerGenerator` filtert das aktuell freigeschaltete Sortiment ueber den Preisperzentil-Bereich des Kundentyps und erzeugt daraus die Produktqueue.
4. `CustomerGenerator` erzeugt fuer wiegbare Produkte deterministische Gewichte aus Run-Seed, Tag, Kunde, Produktindex und Produkt-ID.
5. `SuspicionSystem` initialisiert die Suspicion aus der Kundentyp-Kurve plus `RunState.next_customer_suspicion_bonus_percent`, capped bei `100`, und verbraucht danach diesen Bonus.
6. `CouponSystem` bestimmt, ob ein aktiver Coupon als erstes sichtbares Objekt auftaucht.
7. `VisibleObjectQueueSystem` baut aus Coupon plus Produktqueue die sichtbaren `VisibleObjectSlot`s.
8. `ProductScatterView` instanziiert vorbereitete `PackedScene`s fuer Coupon-/Produkt-Actors in vorhandene Slot-Marker.
9. `CustomerHandView` zeigt die gruen/gelb/rot-Texturen und den Tooltip des aktiven Kundentyps.
10. `ProductActor` skaliert Obst-Sprite, Schatten und Interaction-Shape anhand des gespeicherten Gewichts.

### Scan

1. `ProductActor` wird gezogen und meldet Bewegung/Scannerkontakt.
2. `RunController` baut einen `ScanRequest` mit Actor-ID, Bewegungsrichtung, Scannerkontakt und aktuellem Runtime-State.
3. `ScanSystem` entscheidet, ob der Scan gueltig ist. Nur rechts nach links zaehlt.
4. Wiegbare Produkte werden im `ScanSystem` vor dem Caught-Roll abgelehnt.
5. Bei Mehrfachscan fragt `ScanSystem` ueber den gemeinsamen Charge-Pfad den `SuspicionSystem`-Caught-Roll gegen die Suspicion-Kurve des aktiven Kundentyps ab.
6. `EconomySystem` berechnet den offenen Festpreis-Betrag.
7. `RunController` aktualisiert Runtime-State und sendet Feedback-Events an Presentation: Beep, Scannerflash, Betrag im Kassendisplay, Customer-Signal-State.

### Wiegen

1. `ProductActor` wird auf `ScaleStation` gedroppt.
2. `ScaleStation` akzeptiert nur ein wiegbares Produkt gleichzeitig und meldet den Drop an `CheckoutTable`.
3. `RunController` setzt den aktiven Waagen-Actor und nutzt `ScanSystem.evaluate_product_charge_attempt`, also denselben First-/Duplicate-/Caught-Pfad wie beim Scan.
4. `EconomySystem` berechnet `weight_grams * price_per_kg_cents`, wendet ehrliche Coupons und aktuelle Sticker-Multiplikatoren an und addiert nur den neuen Betrag zum offenen Produktbetrag.
5. `RunController` aktualisiert Runtime-State und sendet Feedback-Events an Presentation: Waagenfeedback, Betrag im Kassendisplay, Customer-Signal-State.
6. Zum Mehrfachbuchen kann der Spieler das Obst von der Waage hochheben und erneut ablegen. Jede weitere Wiegung nutzt den Duplicate-/Caught-Pfad.
7. Beim Entfernen des Obstes von der Waage wird der Betrag im Kassendisplay ausgeblendet; der offene Betrag bleibt am Produkt.
8. Wenn ein Sticker auf das aktuell auf der Waage liegende Obst geklebt wird, berechnet `EconomySystem` den offenen Produktbetrag mit den aktuellen Stickern neu und `RunController` aktualisiert das Kassendisplay sofort.

### Caught-Strafen

1. Jeder Caught-Fall entfernt das aktuelle Produkt, loescht dessen offenen Betrag und bucht kein Geld.
2. Die typ-spezifische Zusatzstrafe kommt aus `CustomerTypeResource`.
3. Jimmy und Margaret haben keine Zusatzstrafe.
4. Chad zieht zusaetzlich einmal den einfachen Produktwert vom aktuellen Geldbestand ab. `EconomySystem` berechnet dafuer denselben Wert, der bei einem ehrlichen Scan oder einer ehrlichen Wiegung dieses Produkts entstehen wuerde; der Geldbestand wird bei `0` gecappt.
5. Doris addiert `caught_next_customer_suspicion_bonus_percent` auf `RunState.next_customer_suspicion_bonus_percent`. Mehrfaches Erwischtwerden stapelt, der beim naechsten Kunden angewendete Startwert wird bei `100` gecappt.
6. Coupon-Scam loest keinen Caught-Roll und keine Kundentyp-Strafe aus.

### Verkauf

1. `ProductActor` wird in `BagZone` gedroppt.
2. `RunController` lehnt wiegbare Produkte ohne offenen Betrag ab.
3. `RunController` fragt `EconomySystem` nach `PayoutOutcome`.
4. Offener Betrag wird dem Run-/Kunden-Total gutgeschrieben.
5. `VisibleObjectQueueSystem` markiert das Objekt als verarbeitet und rueckt erst jetzt nach.
6. `ProductActor` verschwindet ueber vorbereitete Animation/VFX.
7. Coin-VFX wird an der Tüte abgespielt, weil erst dort Geld gebucht wird.

### Trash

1. Produkt oder Coupon wird in `TrashZone` gedroppt.
2. `RunController` entscheidet anhand Runtime-Typ:
   - Produkt: verschwindet, offener Betrag wird verworfen.
   - Coupon: Coupon-Rabatt wird fuer diesen Kunden nicht aktiviert, Produktgewichtungs-Vorteil bleibt erhalten.
3. `VisibleObjectQueueSystem` rueckt erst jetzt nach.

### Sticker

1. `StickerSystem` initialisiert `RunState.sticker_inventory` aus `StickerResource.daily_refill_count`.
2. Zu Beginn eines neuen Tages ruft `RunController` `StickerSystem.refill_daily`.
3. Der Sticker-Button im rechten Panel oeffnet `StickerPopup` ueber `HudRoot`.
4. `StickerPopup` instanziiert fuer jeden verfuegbaren Sticker ein vorbereitetes `StickerToken`.
5. Beim Loslassen eines Tokens sendet UI nur Sticker-ID und globale Drop-Position.
6. `RunController` fragt `CheckoutTable.find_product_actor_at_global_position` und laesst `StickerSystem` Anwendbarkeit und Verbrauch entscheiden.
7. Aktuell darf `bio_sticker` genau einmal pro Obst angewendet werden und nicht auf Festpreis-Produkte oder Coupons.
8. Bei Erfolg wird ein `StickerInstance` an `ProductInstance.applied_stickers` gespeichert und `ProductActor` aktualisiert seinen `StickerLayer`.
9. Wenn der beklebte `ProductActor` der aktive Waagen-Actor ist, laesst `RunController` den offenen Wiegebetrag ueber `EconomySystem` neu berechnen und zeigt den aktualisierten Betrag im Kassendisplay.

## 9-Slice-UI

Alle UI-Panels nutzen `res://assets/textures/ui/panels/9slice_panel_white.png`.

Asset-Daten:

- Texture: `16x16px`
- Outer Padding: `2px`
- Corner-Slices: `5x5px`
- Side-Slices: `2x5px` bzw. `5x2px`
- Center-Slice: `2x2px`
- Content-Padding: `2px`

Verbindliche Nutzung:

- Panels sind `PanelContainer` oder spezialisierte Szenen, deren Theme/StyleBox auf dieser Texture basiert.
- `StyleBoxTexture.texture_margin_left/right/top/bottom = 7`, weil die Texture `2px` Outer Padding plus `5px` Corner-Slice enthaelt.
- Content-Margins starten bei `2`, koennen pro Panel-Typ aber als Theme-Token groesser gesetzt werden.
- Farbvarianten entstehen ueber `modulate_color`/Theme-Varianten, nicht ueber neue Panel-Bilder.
- Buttons, Dialoge, Upgrade-Karten, Statusboxen und Popups verwenden dieselbe Panel-Architektur.
- Keine komplett per Code erzeugten UI-Baeume: Container, Marker und Panel-Struktur bleiben in `.tscn`-Szenen sichtbar.

## Farbpalette

Das gesamte Spiel nutzt Endesga 64 als verbindliche Farbpalette: <https://lospec.com/palette-list/endesga-64>.

Regeln:

- UI-, Tooltip-, Panel-, Button-, Scanner-, Schatten- und Feedback-Farben kommen aus `CheckoutThemeResource`.
- Neue UI-Farben werden als explizite Theme-Tokens in `content/ui/checkout_theme.tres` gepflegt.
- Keine freien `lightened()`-/`darkened()`-Ableitungen fuer Runtime-UI-Zustaende, weil sie Zwischenfarben ausserhalb der Palette erzeugen.
- Transparenz darf fuer Overlays, Slot-Guides und Schatten genutzt werden, aber die RGB-Basisfarbe bleibt eine Endesga-64-Farbe.
- Produkt- und Environment-Sprites sollen ebenfalls mit Endesga 64 gezeichnet werden, damit Assets und UI zusammenpassen.

## Pixel- und Font-Regeln

Die verbindlichen Werte stehen in `project-settings.md` und sind in `project.godot` gesetzt.

- Renderer: `gl_compatibility` (reines 2D-Spiel; geringerer Overhead und breitere Hardware-/Export-Unterstuetzung als Forward+)
- Viewport: `640x360`
- Run-Fenster: `1280x720`
- Stretch Mode: `canvas_items`
- Stretch Aspect: `keep`
- Scale Mode: `integer`
- Globaler Texture Filter: nearest
- Pixel Snap fuer 2D-Transforms und Vertices aktiv

Font:

- Runtime-Font: `res://assets/fonts/PixelOperator8.ttf`
- Erlaubte UI-Fontgroessen: `8`, `16`, `24`, `32`
- Fontgroessen werden ueber Theme-Resources gesetzt, nicht lokal in Einzelszenen.

## Audio- und VFX-Feedback

Audio- und VFX-Feedback gehoert zur Presentation-Schicht. Gameplay-Systeme liefern nur Ergebnis- oder Feedback-Events; Szenen wie `CheckoutTable`, `ProductActor`, `ScaleStation`, `ScannerStation`, `TrashZone` und `CustomerHandView` spielen daraus editorseitig authorierte AudioPlayer, AnimationPlayer oder VFX-Anker ab.

- Wiederkehrende AudioPlayer, AnimationPlayer und VFX-Anker bleiben als sichtbare Child-Nodes in den Szenen.
- Runtime-VFX werden nur als fertige `PackedScene`s in vorhandene VFX-Container oder Marker instanziiert.
- Haeufig gespawnte VFX wie Coin-Bursts muessen leicht instanziierbar oder spaeter poolbar bleiben: keine grossen Node-/Resource-Baeume, keine Asset- oder Resource-Ladevorgaenge und keine unnoetigen AudioPlayer-Multiplikationen im Scan-/Payout-Flow.

## Asset-Pipeline

Root-Assets werden nicht als dauerhafte Asset-Ablage genutzt. Dauerhafte Ziele:

- Font: `assets/fonts/PixelOperator8.ttf`
- Scanner-SFX: `assets/audio/sfx/scanner/high_beep.mp3`
- Customer-SFX: `assets/audio/sfx/customer`
- UI-SFX: `assets/audio/sfx/ui`
- 9-Slice-Panel: `assets/textures/ui/panels/9slice_panel_white.png`
- Produkt-Spritesheet: `assets/textures/products/products_sheet.png`
- Produkt-Spritesheet-Mapping: `assets/textures/products/products_sheet.txt`
- Bio-Sticker-Sprite: Atlas-Region aus `assets/textures/products/products_sheet.png`
- Waage: `assets/textures/environment/waage_sheet.png`, 3 Frames à `96x96`
- Environment-Sprites: `assets/textures/environment`
- Customer-Type-Sprites: `assets/textures/customer`, je Kundentyp drei Stage-Texturen fuer gruen/gelb/rot. `fatwoman_*` wird in Content als Margaret/Fatlady gemappt. Doris' `oldlady_*`-Sprites duerfen abweichende Abmessungen haben und muessen resource-/editorseitig sauber ausgerichtet werden.
- Coin-/Scanner-VFX: `assets/vfx/coin`, `assets/vfx/scanner`
- Customer-/Impact-VFX: `assets/vfx/customer`, `assets/vfx/impact`

Produkt-Schatten werden nicht als Standardprodukt gebaked, sondern im `ProductActor` separat aufgebaut.

Die alten `assets/textures/environment/hand_*.png` sind durch die typisierten Customer-Sprites abgeloest. Sie werden erst entfernt, wenn keine Scene, kein Script und keine Resource sie mehr referenziert.

## Ordnerstruktur

```text
assets/
  audio/
    music/
    sfx/
      customer/
      scanner/
      ui/
  fonts/
  textures/
    customer/
    environment/
    products/
    ui/
      icons/
      panels/
  vfx/
    coin/
    scanner/
content/
  balance/
  coupons/
  customers/
  products/
    lines/
    variants/
  stickers/
  ui/
  upgrades/
docs/
scenes/
  application/
  gameplay/
    bag/
    customer/
    product_area/
    products/
    scale/
    stickers/
    scanner/
    table/
    trash/
  ui/
    dialogs/
    hud/
    panels/
    popups/
  vfx/
scripts/
  application/
  autoload/
  gameplay/
    actors/
    components/
    generation/
    requests/
    state/
    systems/
  ui/
    panels/
    theme/
  vfx/
tests/
  content/
  unit/
tools/
  content/
  import/
```

## Validierung und Tests

Fruehe Tests sollen pure Gameplay-Logik abdecken:

- `VisibleObjectQueueSystem`: Queue, sichtbare Slots, Coupon-Slot, Nachruecken erst nach Bag/Trash/Caught.
- `ScanSystem`: Scannerkontakt, Bewegungsrichtung, Mehrfachscan, Rotation/Hit-Details.
- `CouponSystem`: Aktivierung, Tagesdauer, Stack-/Delay-Regeln, Coupon-Scam.
- `EconomySystem`: Festpreiswerte, Gewichtspreise, Rabatte, Sticker-Multiplikatoren, Rundung.
- `SuspicionSystem`: deterministische Rolls mit Seed, kundentyp-spezifische Stufen, Customer-Signal-Zustand und Start-Suspicion-Boni.
- `CustomerGenerator`: gleiche Seeds erzeugen gleiche Kundentyp-, Produkt- und Gewichtsfolgen; Run-Kunde 1 ist Jimmy; direkte Typ-Wiederholungen kommen nicht vor; Preisperzentil-Pools respektieren das aktuelle Sortiment.
- `StickerSystem`: taeglicher Refill, Verbrauch, Zielvalidierung und Produkt-Multiplikatoren.

Content-Validierung ist Pflicht, sobald mehrere Resource-Typen referenziert werden:

- doppelte IDs
- fehlende Produkt-/Coupon-/Upgrade-Referenzen
- fehlende Texturen
- ungueltige Preise/Gewichtungen
- ungueltige Gewichtsspannen, Kilopreise oder Sticker-Multiplikatoren
- Produkte ausserhalb freigeschalteter Sortiment-Level
- ungueltige Kundentypen: fehlende ID/Name/Tooltip, fehlende Stage-Texturen, ungueltige Preisperzentile, ungueltige Suspicion-Stufen oder ungueltige Caught-Strafwerte

## Technische Schuld

Aktuell ist keine bewusste technische Schuld in dieser Basis vorgesehen. Falls fuer einen Prototyp bewusst vereinfacht wird, muss die Abweichung direkt im betroffenen Code oder Dokument als technische Schuld mit Grund und Ersatzpfad markiert werden.
