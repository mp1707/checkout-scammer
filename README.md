# Checkout Scammer

Ein 2D-Pixel-Art-Prototyp (Godot 4.6): Du stehst an der Supermarktkasse und
versuchst, Kunden unauffällig zu viel zu berechnen — ohne erwischt zu werden.

## Setup

- [Godot 4.6](https://godotengine.org/download) installieren.
- Projekt über `project.godot` im Godot-Editor öffnen (erster Import dauert kurz).
- Starten mit F5 (Hauptszene: `scenes/application/boot.tscn`).

## Tests

Alle Suiten headless ausführen:

```sh
GODOT=/pfad/zu/godot tools/run_tests.sh
```

Einzelne Suite:

```sh
godot --headless --path . --script tests/unit/simulation_systems_test.gd
```

| Suite | Inhalt |
| --- | --- |
| `tests/content/content_validation_test.gd` | Lädt und validiert alle Content-Resources (IDs, Referenzen, Wertebereiche). |
| `tests/unit/simulation_systems_test.gd` | Pure Simulation: Generator, Queue, Scan, Suspicion, Economy, Coupons, Upgrades, Sticker. |
| `tests/unit/run_controller_flow_test.gd` | Integration: komplette Spielszene headless, Scan/Payout/Waage/Sticker/Shop-Flow. |

CI (`.github/workflows/ci.yml`) führt Tests plus `gdlint`/`gdformat` bei jedem Push aus.

## Projektüberblick

| Pfad | Inhalt |
| --- | --- |
| `scripts/application/` | Bootstrapping, ContentRegistry, RunController + Flow-/Interaktions-/Shop-Handler. |
| `scripts/gameplay/systems/` | UI-freie Simulation (Scan, Economy, Coupons, …) — ohne Szenen testbar. |
| `scripts/gameplay/actors/` | `TableActor`-Basis plus Produkt-/Coupon-Actors (Drag, Rotation, Feedback). |
| `scripts/gameplay/components/` | Tisch-Komponenten: Scanner, Waage, Zonen, Scatter-View, Kassendisplay. |
| `scripts/ui/` | HUD, Panels, Popups, Tooltips, zentrale UI-Texte (`ui_texts.gd`). |
| `content/` | Alle konfigurierbaren Inhalte als `.tres`-Resources (Produkte, Coupons, Balance, geskriptete Kunden). |
| `scenes/` | Authoring-Flächen — Layout, Slots, Hitboxen und Referenzen werden im Editor gepflegt. |

Verbindliche Architektur- und Arbeitsregeln: [architecture.md](architecture.md), [AGENTS.md](AGENTS.md), Gameplay-Design: [gdd.md](gdd.md).
