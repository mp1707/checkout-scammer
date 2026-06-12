# Improvements — Code-Review Checkout Scammer

Stand: 2026-06-12. Review der gesamten Codebase (~6.500 Zeilen GDScript) gegen die eigenen
Regeln aus `AGENTS.md`/`architecture.md` sowie allgemeine Godot-4-Best-Practices.

## Umsetzungsstatus (2026-06-12)

**Alle Punkte sind umgesetzt**, mit drei bewussten Abweichungen:

- ✅ P1.1–P1.5, P2.6–P2.15, P3.16–P3.21 implementiert (Details siehe unten; die Punkte bleiben
  als Begründungs-Doku stehen).
- ⚠️ **P3.18 (Godot-Theme statt Label-Overrides): bewusst nicht migriert.** Die Panels brauchen
  label-spezifische Font-Varianten (bold/compact/title), die ein einfaches Default-Font-Theme
  nicht abbildet — das bräuchte Theme-Type-Variations pro Label-Rolle. Aufwand/Nutzen ist für
  den Prototyp ungünstig; `CheckoutThemeResource` bleibt der Träger.
- ⚠️ **P3.20 (VfxSpawner-Service): bewusst minimal gelöst.** Es gibt genau eine Code-Spawn-Stelle
  (`CheckoutTable._spawn_coin_burst`, jetzt typisiert auf `CoinBurstVfx`); ein eigener Service
  wäre Indirektion ohne zweiten Nutzer. Pooling kann später an dieser einen Stelle ansetzen.
- ⚠️ **P3.21 (Lint in CI): advisory.** Der gdformat-Check läuft in CI mit `continue-on-error`,
  bis das Team einmal lokal `gdformat scripts tests` ausgeführt und committet hat — dann die
  Zeile im Workflow entfernen.

**Wichtig vor dem nächsten Arbeiten:** Projekt einmal im Godot-Editor öffnen (Re-Import) und
`tools/run_tests.sh` ausführen. Der Renderer wurde auf `gl_compatibility` umgestellt (P3.17) —
bitte einmal visuell gegenprüfen; Revert wäre eine Zeile in `project.godot`. Beim Refactoring
wurde zusätzlich entdeckt und behoben: mehrere Szenen hatten NodePath-Exports **ohne**
`node_paths`-Header (game_app, hud_root, product_scatter_view, scanner_station, bag_zone,
coupon_actor) — die Werte wurden nie aufgelöst, die Code-Fallbacks waren dort tragend.

**Gesamteindruck:** Die Architektur-Trennung Simulation / Presentation / Application ist sauber
umgesetzt, die Simulation ist UI-frei und deterministisch testbar, Content liegt konsequent in
Resources mit Validierung. Das Fundament ist gut. Die dringendsten Probleme sind durchgängiges
Duck-Typing trotz typisierter Klassen, die doppelte Verdrahtung Szene/Code, der zu groß
gewordene `RunController` und fehlende Projekt-Hygiene (README, Test-Runner, CI, Linting).

---

## P1 — Dringend

### 1. Duck-Typing und Reflection ersetzen durch echte Typen

Das größte strukturelle Problem. Es gibt **66 Aufrufe** über `has_method()`/`call(...)` und
diverse `actor.get("property")`-Zugriffe, obwohl die Zielklassen `class_name` haben und die
Referenzen teils sogar typisiert exportiert sind. Beispiele:

- `checkout_table.gd:39` — `product_scatter_view.call("display_slots", slots)`, obwohl die
  Variable als `ProductScatterView` exportiert ist. Direkt `product_scatter_view.display_slots(slots)` aufrufen.
- `checkout_table.gd:85-86` — `scanner_station.call("play_success_feedback", scan_count)` trotz
  `@export var scanner_station: ScannerStation`.
- `run_controller.gd:664-717` — `_get_actor_id`, `_get_actor_bool`, `_get_actor_vector`,
  `_get_product_instance` lesen Properties per `actor.get("...")` aus `Node2D`-Referenzen.
- `scale_station.gd:165,197`, `scanner_station.gd:59-76` — gleiche Muster.
- `hud_root.gd:121,145` — Signal-Connects per String: `connect("popup_closed", Callable(self, "close_coupon_popup"))`.

Folgen: kein Compile-Time-Check, keine Autocompletion, Tippfehler in Strings schlagen erst zur
Laufzeit (oder gar nicht sichtbar) fehl, Refactoring/Umbenennen ist gefährlich. Das widerspricht
direkt der AGENTS.md-Regel „statisches Typing konsequent".

**Empfehlung:**
- Signale überall typsicher verbinden: `checkout_table.actor_bag_drop_requested.connect(_on_actor_bag_drop_requested)`
  statt `_connect_signal_once(obj, "signal_name", cb)` mit String. Die beiden identischen
  `_connect_signal_once`-Helper (in `run_controller.gd` und `checkout_table.gd`) können dann entfallen.
- Für Produkt-/Coupon-Actors eine gemeinsame typisierte Basis einführen (z. B. `class_name TableActor extends Node2D`
  mit `actor_id`, `slot_index`, `is_held`, `movement_direction`, `get_contact_area()`), oder
  alternativ überall `actor as ProductActor` / `actor as CouponActor` casten und auf `null` prüfen.
  Damit verschwinden alle `_get_actor_*`-Reflection-Helper.
- Popups (`coupon_popup`, `sticker_popup`) mit `class_name` versehen und in `HudRoot` typisiert
  instanziieren statt über `has_signal`/`has_method`-Ketten.

### 2. `_resolve_child_references()`-Fallback-Ketten entfernen

Fast jede Szene hat **73 `get_node_or_null`-Fallbacks** der Form:

```gdscript
if product_sprite == null:
    product_sprite = get_node_or_null("SpriteRoot/ProductSprite") as Sprite2D
```

Das dupliziert die Szenenstruktur als Strings im Code (zweite Quelle der Wahrheit) und
verdeckt kaputtes Szenen-Wiring still — exakt das, was `architecture.md` verbietet
(„Node-Pfade werden nicht quer durch die Szene gesucht") und AGENTS.md als „stille Fallbacks"
ablehnt. Wird ein Node in der Szene umbenannt, fällt der Code lautlos auf `null`-No-Ops zurück
(siehe Punkt 3) und Features verschwinden kommentarlos.

**Empfehlung:** Eine Quelle der Wahrheit wählen — `@export`-Referenzen, im Editor zugewiesen.
Fehlende Referenzen in `_ready()` laut melden (`assert` oder `push_error`), nicht stumm
weiterlaufen. Die `_resolve_child_references()`-Funktionen ersatzlos streichen. Für Pflicht-Nodes
in einer eigenen Szene ist auch `@onready var x: T = $Path` legitim (Pfad bricht dann sichtbar).

### 3. Stille Null-No-Ops durch laute Fehler ersetzen

Durchgängiges Muster: `if hud_root == null: return`, `if checkout_table == null: return` usw.
Im Prototyp-Alltag bedeutet das: Eine fehlkonfigurierte Szene spielt sich „fast normal",
nur dass z. B. kein HUD-Update oder kein Payout passiert — die schwerste Art Bug zu finden.

**Empfehlung:** Konfigurationsfehler (fehlende Exports, fehlender Registry) einmal in `_ready()`/
`configure()` hart prüfen und mit `push_error`/`assert` melden. Danach dürfen die Hot-Paths den
Zustand voraussetzen. Null-Checks nur dort behalten, wo `null` ein gültiger Laufzeitzustand ist
(z. B. `current_customer` zwischen Kunden).

### 4. `run_controller.gd` (717 Zeilen) aufteilen

AGENTS.md sagt: ab ~150 Zeilen Aufteilung prüfen, keine God Objects. Der `RunController` ist
mit 717 Zeilen fast das Fünffache und vereint: Run-/Tages-Lifecycle, Scan-Handling,
Waage-Handling, Coupon-Kauf-UI-Flow, Sticker-Drag-Flow, Dialog-Zustandsmaschine,
Tooltip-Textbau, Actor-Property-Reflection.

**Empfehlung** (pragmatischer Schnitt, keine neue Architektur nötig):
- `RunFlowController` / Zustandsmaschine: Tag/Kunde/Win/Lose/Dialog-Kind (`_start_run`,
  `_start_customer`, `_advance_after_customer`, `_finish_day`, `_on_dialog_closed`).
- `CheckoutInteractionHandler`: Scan-/Bag-/Trash-/Scale-Events → Systeme aufrufen
  (`_on_product_scan_contact_started`, `_charge_weighed_product`, …).
- `ShopHandler` (Coupons/Upgrades/Sticker-Kauf und zugehörige HUD-Updates inkl. Tooltips).
- Die Tooltip-/Label-Textproduktion (`_build_assortment_upgrade_tooltip`) gehört eher in die
  Presentation-Schicht als in den Application-Controller.

### 5. README + dokumentierter Test-Runner + CI

Es gibt kein README, `docs/` ist leer, und nirgends steht, wie man die Tests ausführt
(die Tests erweitern `SceneTree`, laufen also vermutlich via
`godot --headless --script tests/unit/phase_2_simulation_test.gd`). Neue Devs müssen das
reverse-engineeren.

**Empfehlung:**
- Kurzes `README.md`: Godot-Version, wie starten, wie Tests laufen, Verweis auf
  `architecture.md`/`AGENTS.md`/`gdd.md`.
- Test-Aufrufe als Skript (`tools/run_tests.sh`) festschreiben.
- Minimale CI (GitHub Actions mit Godot-Headless-Image): Content-Validierung + Unit-Tests pro
  Push. Gerade die `ContentRegistry`-Validierung ist wertvoll und sollte automatisch laufen.

---

## P2 — Wichtig (Wartbarkeit & Verständlichkeit)

### 6. Code-Duplikate konsolidieren

- `_get_next_customer_context()` und `_is_activation_due()` existieren **identisch** in
  `coupon_system.gd:159-173` und `upgrade_system.gd:60-74`. → In eine gemeinsame Stelle ziehen
  (z. B. statische Helper auf `RunState` oder ein kleines `RunSchedule`-Utility: „nächster
  Kunde/Tag" und „Aktivierung fällig?" sind Run-Kalender-Logik).
- `_connect_signal_once()` doppelt (`run_controller.gd:650`, `checkout_table.gd:227`) — entfällt
  ohnehin mit Punkt 1.
- `_get_product_instance(actor)` dreifach (`run_controller.gd`, `checkout_table.gd`,
  `scale_station.gd`) — entfällt mit typisierten Actors.

### 7. Tote Signale entfernen

`run_controller.gd:4-8` deklariert `product_scan_requested`, `bag_drop_requested`,
`trash_drop_requested`, `coupon_purchase_requested`, `assortment_upgrade_requested` — niemand
verbindet sich damit (weder Code noch Szenen noch Tests). Sie werden zudem **vor** der
Input-Sperre-Prüfung emittiert, wären also als „Intent-Hooks" auch noch irreführend. Entfernen
oder bewusst dokumentieren, wofür sie reserviert sind.

### 8. Hardcodierte Content-Daten aus dem Code holen

`customer_generator.gd:189-239`: Die geskripteten Erst-Tag-Kunden inkl. Produkt-ID-Konstanten
(`PRODUCT_ID_APPLE`, …) sind fest im Code. Das verstößt gegen zwei eigene Regeln („keine
globalen String-IDs frei im Code", „neue Produkte ohne Code-Änderung"). Ein neues
Startsortiment erfordert aktuell einen Code-Edit + die Content-Validierung sieht diese IDs nicht
(Tippfehler fällt erst zur Laufzeit per `push_error` auf).

**Empfehlung:** `ScriptedCustomerResource` (Tag, Kundennummer, Array von
`ProductVariantResource`-Referenzen) unter `content/customers/` (Ordner existiert schon und ist
leer) + Validierung in der `ContentRegistry`.

### 9. Strings/Ints durch Enums ersetzen

- `scan_system.gd:6-12`: `FAILURE_*` sind String-Konstanten → `enum FailureReason` (typo-sicher,
  match-bar, schneller).
- `run_controller.gd:43,521`: `_dialog_kind: int` und Parameter `dialog_kind: int` obwohl
  `enum DialogKind` existiert → als `DialogKind` typisieren.

### 10. HudRoot: 90 Zeilen Text-Layout-Eigenbau ersetzen

`hud_root.gd:246-333` misst Textbreiten, zählt umbrochene Zeilen per eigenem Wortumbruch-
Algorithmus und berechnet Panelgrößen von Hand. Das repliziert, was Godot selbst kann, und
driftet zwangsläufig vom tatsächlichen Label-Rendering ab (der eigene Umbruch entspricht nicht
exakt `TextServer`-Umbruch).

**Empfehlung:** `Label.autowrap_mode = WORD_SMART` + `custom_minimum_size.x`-Clamp setzen und
die Größe aus `label.get_combined_minimum_size()` bzw.
`font.get_multiline_string_size(...)` beziehen; Panel über Container-Layout wachsen lassen.
Nebenbei: `_join_tooltip_lines()` in `run_controller.gd:629` ist ein Handbau von
`"\n".join(lines)`.

### 11. Magic Numbers zentralisieren

- `hud_root.gd:141` — Sticker-Popup-Position `Vector2(532.0, 134.0)` hart im Code. Gehört in
  die Szene (Marker/Container) oder als `@export`.
- Z-Index-Ebenen verstreut: `40` (Waage), `100` (Drag), `120` (Finish-Fly) → eine
  `ZLayers`-Konstantenklasse oder zumindest benannte Konstanten pro Script.
- `product_actor.gd:251` — Kollisionsgröße `Vector2(32, 32)` hardcodiert; bricht still, wenn
  Sprites eine andere Größe bekommen.

### 12. Sprach-Mix in UI-Texten auflösen

`run_controller.gd:10-16` mischt Englisch („Thanks, byyyyyeeeeee", „You win!") und Deutsch
(Tooltips: „Coupons wirken ab dem naechsten Kunden…"), inkl. ASCII-Umschreibung („naechsten").
Auch wenn Lokalisierung noch kein Ziel ist: Eine Sprache wählen und die Strings an einer Stelle
sammeln (z. B. `UiTexts`-Konstanten oder Godot-`tr()`+CSV vorbereiten). UI-Texte gehören zudem
eher in die Presentation-Schicht als in den RunController.

### 13. HudRoot: unnötige Indirektion bei den Panels

`hud_root.gd:4-5` preloadet die Panel-Scripts als `GDScript`-Konstanten und exportiert die
Referenzen als `Control`, obwohl beide Klassen `class_name LeftStatusPanel` /
`RightUpgradePanel` haben. → Direkt `@export var right_upgrade_panel: RightUpgradePanel`,
die `_get_*_panel()`-Casts und Preload-Konstanten streichen.

### 14. Naming: `close_coupon_popup()` schließt jedes Popup

`hud_root.gd:157` — die Methode verwaltet `_active_popup` generisch (auch Sticker-Popup),
heißt aber `close_coupon_popup`. → `close_active_popup()`.

### 15. Test-Suite modernisieren

- Tests heißen nach Implementierungsphasen (`phase_2_simulation_test.gd`,
  `phase_4_run_controller_test.gd`) statt nach Verhalten/Feature. In 6 Monaten sagt „Phase 2"
  niemandem mehr etwas. → `simulation_systems_test.gd`, `run_controller_flow_test.gd` o. ä.,
  bzw. pro System eine Datei (die 513-Zeilen-Datei testet 8 Systeme).
- Hand-gerollte Assertion-Helfer ohne Framework. Erwägenswert: **gdUnit4** oder **GUT**
  (bessere Fehlermeldungen, Einzeltest-Ausführung, CI-Integration). Wenn bewusst
  framework-frei: zumindest den gemeinsamen Assertion-Code in eine Basisklasse ziehen.

---

## P3 — Empfehlenswert (Performance & Polish)

### 16. `_find_product_actor_at_global_position` nicht über den ganzen Baum

`checkout_table.gd:275-288` sucht rekursiv durch **alle** Kinder des CheckoutTable (inkl.
Scanner, VFX, Zonen), um den Actor unter dem Sticker-Drop zu finden. `ProductScatterView`
kennt seine Actors bereits (`_actors_by_slot`). → API `product_scatter_view.find_actor_at(global_point)`
plus den Waage-Actor prüfen. Aktuell unkritisch (kleine Bäume), aber gegen die eigene
Performance-Regel und unnötig fragil (findet potenziell auch bereits „finishende" Actors).

### 17. Renderer prüfen: Forward+ für ein 2D-Pixel-Art-Spiel

`project.godot` nutzt „Forward Plus". Für ein reines 2D-Spiel in 640×360 ist das der
schwerste Renderer (Overhead, höhere GPU-Anforderungen, kein Web-Export). →
`gl_compatibility` (oder mind. „Mobile") evaluieren; für dieses Spiel ist das in der Regel
ein kostenloser Gewinn an Kompatibilität und Energieverbrauch.

### 18. Theme statt rekursiver Label-Overrides

`hud_root.gd:227` (`_apply_label_theme`) läuft rekursiv über den Baum und setzt per-Label
`add_theme_*_override`. Godot hat dafür `Theme`-Resources: ein Theme auf dem HUD-Root mit
Default-Font/-Größe/-Farbe erledigt das deklarativ, ohne Code, und gilt automatisch auch für
später hinzugefügte Labels (Popups!). Aktuell bekommen dynamisch instanziierte Popups das
Theme nur, wenn sie es selbst setzen. Es existiert bereits `content/ui/checkout_theme.tres`
(eigene Resource) — prüfen, ob ein echtes Godot-`Theme` der konsistentere Träger wäre.

### 19. `await create_timer` im Kunden-Abschluss härten

`run_controller.gd:472` wartet mit `await get_tree().create_timer(...)` und prüft danach den
Zustand erneut. Das funktioniert, ist aber das fragilste Muster für Lifecycle-Bugs (Restart
während des Awaits, doppelte Aufrufe). Robuster: ein (Scene-)`Timer`-Node oder die Verlagerung
in eine explizite kleine Zustandsmaschine (passt zu Punkt 4). Mindestens: Kommentar, warum die
Re-Checks nötig sind.

### 20. VFX-Pooling vorbereiten

`checkout_table.gd:234` instanziiert pro Verkauf einen frischen Coin-Burst. AGENTS.md fordert
„so bauen, dass Pooling später möglich ist" — aktuell ist das Spawnen an drei Stellen verteilt
(CheckoutTable, ScaleStation-VFX, Popup-Effekte). Ein kleiner `VfxSpawner`-Service (auch ohne
Pooling) würde die Stelle zentralisieren, an der Pooling später eingebaut wird.

### 21. Linting/Formatting einführen

Kein `gdlint`/`gdformat` (gdtoolkit) und keine Pre-Commit-Hooks im Repo. Bei der vorhandenen
Disziplin wäre das günstig abzusichern: `gdformat --check` + `gdlint` in CI (siehe Punkt 5),
verhindert Stil-Drift, gerade wenn mehrere Agenten/Devs committen.

---

## Positiv hervorzuheben

Damit die Liste nicht den falschen Eindruck erweckt — diese Dinge sind überdurchschnittlich gut:

- **Schichtentrennung**: Simulation (`RefCounted`-Systeme) ist komplett UI-frei und in Tests
  ohne Szenen ausführbar; Presentation mutiert keinen Run-State.
- **Content-Pipeline**: Resources + `ContentRegistry` mit umfassender Validierung (fehlende/
  doppelte IDs, kaputte Referenzen, Wertebereiche) — genau richtig.
- **Determinismus**: `CustomerGenerator` mit stabilen Seeds inkl. eigenem stabilem String-Hash;
  Tests prüfen die Seed-Stabilität explizit.
- **Geld als Integer-Cents** durchgängig — keine Float-Geldbeträge.
- **Statisches Typing** ist (abseits der Duck-Typing-Stellen aus Punkt 1) konsequent, inklusive
  typisierter Dictionaries und Signal-Parameter.
