# AGENTS.md

Arbeitsregeln fuer Codex und andere Agenten in diesem Godot-Projekt.

## Verbindliche Projektgrundlage

- Vor groesseren Aenderungen immer `architecture.md` und bei Gameplay-Fragen `gdd.md` lesen.
- Die Architektur in `architecture.md` ist verbindlich.
- Abweichungen von `architecture.md` duerfen nur nach vorheriger Rueckfrage an Marco eingebaut werden.
- Wenn eine kurzfristige Vereinfachung noetig ist, muss sie klar als technische Schuld markiert werden, inklusive Grund und spaeterem Ersatzpfad.
- Jede Empfehlung, jedes Snippet und jede Implementierung soll saubere, skalierbare Godot-Entscheidungen priorisieren.

## Projektstil

- Engine: Godot 4.6.
- Sprache: GDScript mit konsequentem statischem Typing.
- Interne Aufloesung: `640x360`.
- Pixel-Art-Defaults respektieren: nearest filtering, Pixel-Snap, klare Rastermasse.
- Szenen sind Authoring-Flaechen. Layouts, Slots, Drop-Zonen, Hitboxen, Marker, AnimationPlayer und UI-Struktur sollen im Godot-Editor sichtbar und bearbeitbar bleiben.
- Code erzeugt keine kompletten Gameplay- oder UI-Baeume von Grund auf. Code steuert vorhandene Szenen, befuellt vorbereitete Container und instanziiert nur fertige `PackedScene`s.
- Die UI folgt der Balatro-artigen 9-Slice-Panel-Architektur aus `architecture.md`.

## GDScript

- Statisches Typing konsequent verwenden:
  - Variablen typisieren.
  - Funktionsparameter typisieren.
  - Rueckgabewerte typisieren.
  - Signal-Parameter typisieren.
- Wiederverwendbare Typen mit `class_name` versehen.
- Keine untypisierten Dictionary-Strukturen als Ersatz fuer echte `Resource`-, State- oder `RefCounted`-Datenobjekte verwenden.
- Keine globalen String-IDs frei im Code verstreuen. Stabile IDs gehoeren in Resources, Konstanten oder Validierung.
- Runtime-Daten und Resource-Definitionen sauber trennen.
- Explizite, kleine Datenklassen bevorzugen, z. B. `ScanRequest`, `ScanResult`, `PayoutOutcome`, `CouponInstance`, `RunState`.
- Nullbarkeit bewusst behandeln. Keine stillen Fallbacks, die Content-Fehler verdecken.

## Scenes und Nodes

- Eine Scene, eine Aufgabe.
- Keine God Objects.
- Wenn ein Script mehrere Verantwortlichkeiten hat oder grob ueber 150 Zeilen waechst: Aufteilung pruefen.
- Node-Verantwortlichkeiten klar halten:
  - Presentation zeigt Zustand und sammelt Input.
  - Simulation entscheidet Regeln.
  - Application verbindet Scenes, Save/Load und Game-Lifecycle.
- Keine Gameplay-State-Mutation direkt aus UI-Code.
- Keine fragilen Node-Pfade wie `get_node("../../Foo")`, wenn Signal, `@export`, eindeutige Parent-API oder Controller sauberer ist.
- Visuals, Interaktion, Hitboxen/Drop-Zonen und Regelentscheidungen getrennt halten.
- Kurzlebige Gameplay-Zonen oder Effekte sind eigene Szenen/Components, nicht versteckte Nebenlogik in Movement- oder UI-Nodes.
- Fuer dieses Projekt konkret:
  - `ProductActor` sammelt Drag/Rotation/Input und zeigt Zustand.
  - `ScanSystem` entscheidet, ob ein Scan gueltig ist.
  - `EconomySystem`, `CouponSystem` und `ComboSystem` veraendern Gameplay-Ergebnisse.
  - UI-Komponenten senden Intents und reagieren auf State, mutieren aber nicht eigenmaechtig den Run.

## Daten und Resources

Alles Konfigurierbare als Resource modellieren, z. B.:

- Produktlinien.
- Produktvarianten.
- Coupons.
- Upgrades.
- Tages-/Run-Parameter.
- Levelkurven.
- Balancing-Werte.
- UI-Theme-Tokens.
- Spaeter weitere Items, Events, Talente, Tiers oder Progressionstypen.

Regeln:

- Definition-Resources wie `ProductLineResource`, `ProductVariantResource`, `CouponResource` oder `UpgradeResource` zur Laufzeit nicht als mutable Runtime-State missbrauchen.
- Runtime-Zustand liegt in Instanzen wie `RunState`, `CouponInstance`, `VisibleObjectSlot`, `ScanRequest`, `ScanResult`, `PayoutOutcome` oder spaeter Item-/Equipment-Instanzen.
- Neue Produkte, Coupons, Upgrades oder Balancing-Aenderungen sollen moeglichst ohne Code-Aenderung funktionieren.
- Content-Validierung ist Pflicht, sobald mehrere Resource-Typen aufeinander referenzieren.
- Resource-Ladepfade zentral ueber `ContentRegistry` oder klar definierte Loader fuehren, nicht ueber verstreute harte Pfade.
- Source-Assets und Runtime-Resources trennen.

## Produkt-Assets

- Produktassets kommen aktuell aus `assets/textures/products/products_sheet.png` plus `products_sheet.txt`.
- Es gibt keine separaten Black-/White-Outline-Produkte und kein Produkt-Highlighting.
- Coupon-Actors nutzen vorerst das gemeinsame Coupon-Sprite aus dem Produkt-Sheet.
- Produkt-Schatten nicht baked als Runtime-Standard nutzen. Schatten werden separat im `ProductActor` gebaut, damit Drag, Rotation und Tiefe korrekt wirken.
- Spritesheets plus Text-Mapping duerfen als Source erhalten bleiben. Runtime-Varianten sollten ueber `AtlasTexture` oder generierte Resources referenziert werden.

## Kopplung

- Signals und lose Kopplung bevorzugen.
- Lokale Signals fuer Parent/Child-Kommunikation.
- Controller oder Services fuer Simulation-Commands.
- Globale Events nur fuer echte cross-cutting Events verwenden, nicht als Ersatz fuer klare Ownership.
- `@export` fuer editorseitige Konfiguration nutzen, wenn der Wert im Editor gepflegt werden soll.
- UI reagiert auf State und sendet Intents; Gameplay-Systeme mutieren den Spielzustand.
- Autoloads klein halten. Sie sind Services/Koordinatoren, keine Sammelstellen fuer Feature-Logik.

## Komposition

- Komposition vor Vererbung.
- Kleine wiederverwendbare Komponenten bevorzugen.
- Keine tiefen Klassenhierarchien fuer Produkt-, Coupon-, Upgrade- oder Effektlogik.
- Spezialverhalten zuerst als Daten, Constraints, Effects oder Modifier modellieren, nicht als Subclass pro Coupon/Upgrade/Produkt.
- Wiederholbare Verhaltensteile in Components oder klar abgegrenzte Systeme auslagern.

## Performance

Auch wenn das Spiel klein startet, soll die Architektur spaeter wachsen koennen.

- Kein per-frame globales Suchen wie `get_tree().get_nodes_in_group()` fuer Gameplay-Regeln.
- Resources beim Start oder beim Szenenwechsel laden/validieren, nicht mitten im Scan-/Payout-Flow.
- Economy-, Coupon-, Combo-, XP- und Save-Logik ohne UI-Abhaengigkeit halten.
- Money Popups, Coin Bursts, Scanner-Flashes und VFX so bauen, dass Pooling spaeter moeglich ist.
- Coupon-Dauern, Combo-Fenster und Modifier-Timer lokal oder zentral verwalten, nicht verteilt in UI-Scripts.
- Keine Asset- oder Resource-Ladevorgaenge mitten im Scan-/Payout-Flow, wenn sie vorher geladen werden koennen.
- Keine teuren Node-Suchen oder Material-/Texture-Erzeugung in `_process`, wenn Caching moeglich ist.

## Tests und Validierung

- Pure Gameplay-Logik bevorzugt testbar ohne UI halten.
- Besonders frueh testen:
  - `VisibleObjectQueueSystem`: Queue, sichtbare Slots, Nachruecken.
  - `ScanSystem`: Trefferzone, Rotation, Coupon/Produkt/Obst-Sonderfaelle.
  - `CouponSystem`: Aktivierung, Dauer, Stack-Regeln.
  - `EconomySystem`: Basiswerte, Multiplikatoren, Rundung.
  - `CustomerGenerator`: stabile Ergebnisse mit Seed.
- Content-Validierung soll fehlende IDs, doppelte IDs, fehlende Texturen und kaputte Referenzen melden.
- Bei visuellen/UI-Aenderungen im Editor pruefen, ob die Szene bei `640x360` lesbar und bearbeitbar bleibt.

## Umgang mit Aenderungen

- Keine fremden Aenderungen im Git-Worktree zuruecksetzen, ausser Marco fordert es explizit.
- Bestehende Projektstruktur und Architektur respektieren.
- Neue Ordner, Autoloads, Frameworks, Plugins oder grundlegende Patterns nur einfuehren, wenn sie zur Architektur passen oder vorher abgesprochen wurden.
- Kleine, fokussierte Commits/Aenderungen bevorzugen.
- Unklare Designentscheidungen kurz rueckfragen, statt still eine neue Architekturannahme einzubauen.
