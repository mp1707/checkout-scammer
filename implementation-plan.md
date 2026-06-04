# Checkout Scammer - Implementierungsplan

Stand: 2026-06-04

Dieser Plan beschreibt die Umsetzung des spielbaren Prototyps aus `gdd.md`.
`architecture.md` bleibt dabei die verbindliche technische Grundlage. Wenn eine
Aufgabe unten im Konflikt mit `architecture.md` steht, gilt `architecture.md`
und die Aufgabe muss vor der Umsetzung geklaert oder angepasst werden.

## Arbeitsweise

- [ ] Vor jeder groesseren Codex-Session `architecture.md` lesen.
- [ ] Bei Gameplay-Aenderungen zusaetzlich `gdd.md` lesen.
- [ ] Pro Session genau eine Phase oder einen klar abgegrenzten Teil einer Phase bearbeiten.
- [ ] Am Ende jeder Session den Fortschritt in diesem Dokument abhaken.
- [ ] Keine neuen Autoloads, Ordnergrundmuster, Datenfluss-Patterns oder UI-Architekturen ohne Rueckfrage einfuehren.
- [ ] Platzhalter fuer fehlende Tisch-, Scanner-, Band-, Tueten-, Trash- und Kundenhand-Assets als editierbare Szenen bauen, nicht als versteckte Runtime-Zeichnung.
- [ ] Produkt- und Coin-Assets aus dem bestehenden Asset-Ordner verwenden.
- [ ] Technische Schuld nur bewusst und markiert einbauen, inklusive Grund und spaeterem Ersatzpfad.

## Aktueller Projektstand

- [x] Godot-Projektbasis vorhanden.
- [x] `PixelDisplayService` als kleiner Autoload vorhanden.
- [x] `CheckoutThemeResource` und `content/ui/checkout_theme.tres` vorhanden.
- [x] Pixel-Font und 9-Slice-Panel-Asset vorhanden.
- [x] Scanner-Beep vorhanden.
- [x] Coin-VFX-Source-Asset vorhanden.
- [x] Produkt-Black-Outline-Spritesheet vorhanden.
- [x] Produkt-White-Outline-Highlight-Assets vorhanden und in den Startprodukt-Resources referenziert.

## Phasenuebersicht

1. [x] Phase 1: Datenfundament, Content und Validierung
2. [ ] Phase 2: Pure Simulation und Unit-Tests
3. [ ] Phase 3: Editor-Szenen, Platzhalter und Interaktionsoberflaeche
4. [ ] Phase 4: Run-Integration, HUD, Upgrades und kompletter Loop
5. [ ] Phase 5: Juice, Balancing, QA und Prototyp-Abschluss

## Phase 1 - Datenfundament, Content und Validierung

Ziel: Alle konfigurierbaren Inhalte und Runtime-Daten sauber typisieren, ohne
Gameplay-Regeln in UI oder Szenen zu ziehen.

Empfohlener Session-Scope: eine Codex-Session.

### Ordner und Basistypen

- [x] Ordnerstruktur aus `architecture.md` anlegen, soweit noch nicht vorhanden:
  `content/balance`, `content/coupons`, `content/products/lines`,
  `content/products/variants`, `content/upgrades`, `scripts/application`,
  `scripts/gameplay/state`, `scripts/gameplay/requests`,
  `scripts/gameplay/systems`, `scripts/gameplay/generation`,
  `tests/content`, `tests/unit`.
- [x] `GameBalanceResource` erstellen.
- [x] `ProductLineResource` erstellen.
- [x] `ProductVariantResource` erstellen.
- [x] `CouponResource` erstellen.
- [x] `UpgradeResource` erstellen.
- [x] `SuspicionCurveResource` erstellen.
- [x] Bestehende `CheckoutThemeResource` nur erweitern, wenn Phase-1-Content das wirklich braucht.

### Runtime-Daten

- [x] `RunState` als mutable Runtime-State erstellen.
- [x] `CustomerState` erstellen.
- [x] `ProductInstance` erstellen.
- [x] `CouponInstance` erstellen.
- [x] `BeltSlot` erstellen.
- [x] `ScanRequest` erstellen.
- [x] `ScanResult` erstellen.
- [x] `PayoutOutcome` erstellen.
- [x] Geldwerte zentral und konsistent modellieren, bevorzugt als Integer-Cents statt Float-Dollar.

### Start-Content

- [x] `GameBalanceResource` mit Prototypwerten anlegen:
  Startgeld `10$`, Tagesmiete `40$`, 8 Tage, 3 Kunden pro Tag,
  10 Produkte pro Kunde, 4 sichtbare Belt-Slots.
- [x] Produktlinien `snacks`, `drinks`, `fruit` anlegen.
- [x] Startprodukte aus `gdd.md` als `ProductVariantResource` anlegen:
  Kaugummi, Chips, Schokoriegel, Wasser, Limo, Energy Drink, Apfel,
  Banane, Orange.
- [x] Produktpreise und Generator-Gewichtungen in Resources pflegen, nicht als lose Konstanten.
- [x] Produkttexturen aus den vorhandenen Product-Assets referenzieren.
- [x] Falls Atlas-Regionen aus Spritesheet-Text-Mapping generiert werden muessen:
  Import-/Generator-Tool in `tools/import` planen oder bauen, nicht manuell verstreuen.
- [x] Erste Coupons fuer vorhandene Produkte oder Produktlinien anlegen.
- [x] Sortiment-Level-Up-Content mit Kosten und freigeschalteten Produkten anlegen.
- [x] Suspicion-Stufen `10%`, `50%`, `75%`, `90%` als Resource anlegen.

### ContentRegistry und Validierung

- [x] `ContentRegistry` in `scripts/application` erstellen.
- [x] Content-Ladepfade zentral im Registry halten.
- [x] Doppelte IDs validieren.
- [x] Fehlende Referenzen validieren.
- [x] Fehlende Texturen validieren.
- [x] Ungueltige Preise, Gewichtungen und Sortiment-Level validieren.
- [x] Coupons nur gegen existierende Produkte oder Produktlinien validieren.
- [x] Upgrade-Freischaltungen gegen existierende Produktvarianten validieren.
- [x] Content-Validierung als fruehen Test oder Tool ausfuehrbar machen.

### Phase-1-Akzeptanz

- [x] Content kann zentral geladen werden, ohne UI-Szenen zu instanziieren.
- [x] Validierung meldet kaputten Content sichtbar und verdeckt ihn nicht durch Fallbacks.
- [x] Neue Produkte, Coupons und Upgrade-Werte sind in Resources editierbar.
- [x] Alle neuen GDScript-Dateien nutzen `class_name`, typisierte Variablen,
  typisierte Parameter und typisierte Rueckgabewerte.

## Phase 2 - Pure Simulation und Unit-Tests

Ziel: Der Core-Loop ist als UI-unabhaengige Simulation testbar. Noch kein
fertiger Bildschirm noetig.

Empfohlener Session-Scope: ein bis zwei Codex-Sessions, je nach Testaufwand.

### CustomerGenerator

- [ ] Deterministischen Seed-Eingang definieren.
- [ ] Gleicher Seed erzeugt gleiche Kunden- und Produktfolge.
- [ ] Erster Tag mit drei gescripteten Kunden modellieren.
- [ ] Spaetere Kunden aus Produktpool, Sortiment-Level und Coupon-Gewichtungen generieren.
- [ ] Coupons beeinflussen Produktgewichtungen, ohne Runtime-Definitionen zu mutieren.

### BeltSystem

- [ ] Kunden-Queue aus 10 Produkten verwalten.
- [ ] Maximal 4 sichtbare Belt-Slots bereitstellen.
- [ ] Optionalen Coupon als erstes sichtbares Belt-Objekt abbilden.
- [ ] Coupon zaehlt nicht gegen die 10 Produkte.
- [ ] Nachruecken aus der Queue nach Produkt-/Coupon-Verarbeitung testen.
- [ ] Freie Auswahl innerhalb sichtbarer Slots erlauben.
- [ ] Verarbeitete Slots sauber entfernen, ohne UI-Nodes zu kennen.

### ScanSystem

- [ ] `ScanRequest` aus Actor-ID, gehaltenem Zustand, Scannerkontakt und Bewegungsrichtung auswerten.
- [ ] Nur Bewegung von rechts nach links als gueltigen Scan werten.
- [ ] Links-nach-rechts, Liegenbleiben auf Scanner und nicht gehaltene Produkte ignorieren.
- [ ] Ersten Scan eines Produkts immer sicher werten.
- [ ] Mehrfachscan als Betrugsversuch markieren.
- [ ] Rotation/Hit-Details als erweiterbare Felder modellieren, auch wenn sie im Prototyp noch einfach bewertet werden.

### SuspicionSystem

- [ ] Suspicion pro Kunde bei `10%` starten.
- [ ] Caught-Roll ab zweitem Scan desselben Produkts ausfuehren.
- [ ] Nicht erwischter Double-Scan erhoeht Suspicion auf `50%`.
- [ ] Danach auf `75%`, dann `90%`, danach Deckel bei `90%`.
- [ ] Coupon-Scam loest keinen Caught-Roll aus.
- [ ] Mood-Ring-State aus Suspicion ableiten: gruen, gelb, orange, rot.
- [ ] Rolls deterministisch testbar machen.

### EconomySystem

- [ ] Produktbasiswert aus `ProductVariantResource` berechnen.
- [ ] Offenen Betrag pro gehaltenem Produkt erhoehen.
- [ ] Coupon-Rabatt nur anwenden, wenn Coupon ehrlich aktiviert wurde.
- [ ] Coupon-Scam-Vorteil erhalten: Gewichtungsbonus ja, Rabatt nein.
- [ ] Payout erst beim Drop in die Tute berechnen und dem Run-State gutschreiben.
- [ ] Trash verwirft offenen Produktbetrag.
- [ ] Rundung und Anzeigeformat aus Integer-Cents ableiten.

### CouponSystem und UpgradeSystem

- [ ] Coupon-Kauf prueft Geld und vorhandenes Sortiment.
- [ ] Coupon wirkt ab dem naechsten Kunden.
- [ ] Coupon beim letzten Kunden eines Tages wirkt am ersten Kunden des Folgetags.
- [ ] Coupon laeuft am Tagesende aus.
- [ ] Sortiment-Level-Up prueft Geld.
- [ ] Sortiment-Level-Up wirkt ab dem naechsten Kunden.
- [ ] Upgrade-Button-Zustand aus State ableiten, nicht im UI entscheiden.

### Tests

- [ ] Unit-Test fuer `CustomerGenerator`: gleiche Seeds, gleiche Folgen.
- [ ] Unit-Test fuer `BeltSystem`: sichtbare Slots, Coupon-Slot, Nachruecken.
- [ ] Unit-Test fuer `ScanSystem`: Richtung, Kontakt, gehalten/nicht gehalten.
- [ ] Unit-Test fuer `SuspicionSystem`: Roll, Stufen, Deckel.
- [ ] Unit-Test fuer `EconomySystem`: Scan-Betrag, Coupon-Rabatt, Trash, Payout.
- [ ] Unit-Test fuer `CouponSystem`: Delay, Tagesdauer, Scam-Regeln.
- [ ] Unit-Test fuer `UpgradeSystem`: Kauf, Kosten, Wirkung ab naechstem Kunden.

### Phase-2-Akzeptanz

- [ ] Ein kompletter Kundenablauf kann in Tests simuliert werden, ohne eine Szene zu laden.
- [ ] Simulation mutiert nur Runtime-State, keine Definition-Resources.
- [ ] UI-Abhaengigkeiten in Simulation sind nicht vorhanden.
- [ ] Content-Validierung und Unit-Tests laufen reproduzierbar.

## Phase 3 - Editor-Szenen, Platzhalter und Interaktionsoberflaeche

Ziel: Der 1-Screen-Prototyp steht als editierbare Szenenstruktur. Fehlende
Environment-Assets werden durch klare Platzhalter-Szenen ersetzt.

Empfohlener Session-Scope: ein bis zwei Codex-Sessions, weil viele Szenen
angelegt und im Editor pruefbar bleiben muessen.

### Application- und Root-Szenen

- [ ] `GameApp`-Script in `scripts/application` erstellen.
- [ ] `RunController`-Script in `scripts/application` erstellen.
- [ ] Spielszene in `scenes/application` oder `scenes/gameplay` anlegen und von `boot.tscn` erreichbar machen.
- [ ] Root-Layout bei `640x360` in drei Bereiche aufteilen:
  linke Statusleiste ca. 15%, Kassentisch ca. 70%, rechte Upgrade-Leiste ca. 15%.
- [ ] Exportierte Referenzen statt fragiler Querpfade verwenden.

### Platzhalter-Szenen fuer fehlende Assets

- [ ] `CheckoutTable` als sichtbare Tisch-Szene anlegen.
- [ ] `ScannerStation` als quadratischer Scanner links im Kassentisch anlegen.
- [ ] Vertikalen Scannerstrahl als editierbaren Node sichtbar machen.
- [ ] Scanner-Hitbox als `Area2D` mit sichtbarer `CollisionShape2D` anlegen.
- [ ] `ConveyorBeltView` rechts neben Scanner anlegen.
- [ ] Vier Belt-Slot-Marker sichtbar und editierbar platzieren.
- [ ] Spawn- und Exit-Marker fuer Belt-Bewegungen anlegen.
- [ ] `BagZone` ueber dem Scanner anlegen.
- [ ] `TrashZone` rechts unten unter dem Band anlegen.
- [ ] `CustomerHandView` rechts oben ueber dem Band mit Mood-Ring-Platzhalter anlegen.
- [ ] Alle Platzhalter so kapseln, dass spaetere echte Assets die Szene ersetzen oder befuellen koennen, ohne Gameplay-Systeme umzubauen.

### ProductActor und Drag

- [ ] `ProductActor`-Scene in `scenes/gameplay/products` anlegen.
- [ ] `ProductActor`-Script in `scripts/gameplay/actors` anlegen.
- [ ] ProductActor zeigt Black-Outline-Produkttexture als normalen Zustand.
- [ ] Highlight-Zustand nutzt White-Outline-Asset, sobald vorhanden.
- [ ] Separaten Schatten-Anker im ProductActor anlegen, kein baked Runtime-Schatten als Standardprodukt.
- [ ] Drag-Input, Hover, Auswahl und Rotation im ProductActor sammeln.
- [ ] ProductActor sendet Intents/Signals, mutiert aber keinen Run-State.
- [ ] Betrag-Label-Anker am Produkt vorbereiten.
- [ ] Wobble/Squash-Anker oder AnimationPlayer vorbereiten.

### Conveyor, Drop-Zonen und Scannerkontakte

- [ ] `ConveyorBeltView` instanziiert nur vorbereitete Product-/Coupon-Actor-Scenes in vorhandene Slot-Marker.
- [ ] Slots, Spawn und Exit kommen aus der Szene, nicht aus magischen Script-Koordinaten.
- [ ] `ScannerStation` meldet Kontakte lokal an Parent/Controller.
- [ ] `BagZone` meldet Drop-Intent.
- [ ] `TrashZone` meldet Drop-Intent.
- [ ] Optionales Zuruecklegen aufs Band nur vorbereiten, wenn es den Core-Loop nicht verkompliziert.

### HUD und UI-Grundstruktur

- [ ] `HudRoot`-Scene mit linker Statusleiste und rechter Upgrade-Leiste anlegen.
- [ ] Linke Statusleiste zeigt Tag, Kunde, Mietziel, Cash in Drawer.
- [ ] Rechte Leiste enthaelt Coupon-Button, Sortiment-Level-Up-Button und Platzhalter fuer spaetere Upgrades.
- [ ] Dialog-Layer fuer Caught-Dialog, Customer-Bye und Win/Lose vorbereiten.
- [ ] Popup-Szene fuer Coupon-Auswahl vorbereiten.
- [ ] Tooltip-Anker fuer Coupon- und Sortiment-Buttons vorbereiten.
- [ ] Panels ueber 9-Slice-Panel-Architektur aus `architecture.md` stylen.
- [ ] Fontgroessen nur ueber Theme/Resource-Werte verwenden.

### Phase-3-Akzeptanz

- [ ] Szene ist bei `640x360` lesbar und alle wichtigen Marker/Zonen sind im Editor sichtbar.
- [ ] Code baut keine kompletten Gameplay- oder UI-Baeume aus dem Nichts.
- [ ] ProductActor, Scanner, Bag, Trash und HUD kommunizieren ueber Signals, Exports oder Controller-APIs.
- [ ] Platzhalter sind klar als Platzhalter erkennbar und spaeter austauschbar.

## Phase 4 - Run-Integration, HUD, Upgrades und kompletter Loop

Ziel: Der Prototyp ist von Start bis Win/Lose spielbar, mit einfachen
Platzhaltervisuals und echter Simulation darunter.

Empfohlener Session-Scope: ein bis zwei Codex-Sessions.

### RunController-Integration

- [ ] Boot startet die spielbare Szene.
- [ ] `GameApp` laedt Content und startet den Run.
- [ ] `RunController` besitzt den aktuellen `RunState`.
- [ ] `RunController` verbindet Simulation-Systeme mit Presentation.
- [ ] Kundenstart folgt dem Datenfluss aus `architecture.md`.
- [ ] State-Updates werden an HUD und Gameplay-Views verteilt.
- [ ] UI sendet Intents; RunController entscheidet und mutiert Runtime-State.

### Kunden- und Belt-Loop

- [ ] Neuer Kunde erzeugt Queue aus 10 Produkten.
- [ ] Falls Coupon aktiv: Coupon als erstes sichtbares Belt-Objekt anzeigen.
- [ ] Erste vier sichtbare Objekte fahren von rechts ein.
- [ ] Entferntes Objekt laesst naechstes Objekt nachruecken.
- [ ] Leeres Band nach verarbeitetem Kunden korrekt darstellen.
- [ ] Nach letztem Produkt nach kurzer Pause Customer-Bye-Dialog zeigen.
- [ ] Dialog wird mit Enter geschlossen.
- [ ] Danach naechster Kunde oder Tagesende.

### Scan-, Bag- und Trash-Loop

- [ ] Produkt kann vom Band aufgenommen werden.
- [ ] Rechts-nach-links-Scan ueber Scanner loest `ScanSystem` aus.
- [ ] Erster Scan erhoeht offenen Betrag am Cursor.
- [ ] Weitere Scans desselben gehaltenen Produkts fuehren Caught-Roll aus.
- [ ] Bei Erfolg erhoeht sich offener Betrag weiter.
- [ ] Bei Caught erscheint Dialog:
  `Kunde: Hey, do you want to scam me? I want compensation!`
- [ ] Caught-Dialog wird mit Enter geschlossen.
- [ ] Bei Caught verschwindet aktuelles Produkt, offener Betrag wird geloescht, kein Geld wird abgezogen.
- [ ] Drop in Tute bucht offenen Betrag in Cash in Drawer.
- [ ] Drop in Trash verwirft Produkt oder Coupon korrekt.
- [ ] In die Tute gelegte Produkte koennen nicht wieder aufgenommen werden.

### Suspicion und Mood-Ring

- [ ] Mood-Ring zeigt Suspicion farblich.
- [ ] Ring aktualisiert sich nach Mehrfachscan.
- [ ] Neuer Kunde setzt Suspicion wieder auf Startwert.
- [ ] Keine numerische Suspicion-Progressbar anzeigen.

### Tagesende, Win und Lose

- [ ] Nach 3 Kunden endet der Geschaeftstag.
- [ ] Tagesmiete wird bezahlt.
- [ ] Bei unzureichendem Geld: Lose-State zeigen.
- [ ] Bei ausreichendem Geld: naechster Tag startet.
- [ ] Aktive Tages-Coupons laufen am Tagesende aus.
- [ ] Nach bezahlter Miete am Ende von Tag 8: Win-State zeigen.

### Coupons und Sortiment-Upgrades

- [ ] Coupon-Button oeffnet Popup.
- [ ] Popup zeigt nur Coupons fuer freigeschaltete Produkte.
- [ ] Coupon-Kauf zieht Kosten ab.
- [ ] Coupon-Kauf waehrend aktivem Kunden wirkt ab naechstem Kunden.
- [ ] Coupon beim letzten Kunden wirkt am ersten Kunden des naechsten Tages.
- [ ] Ehrlich gescannter Coupon aktiviert Rabatt fuer passende Produkte dieses Kunden.
- [ ] In Trash geworfener Coupon aktiviert keinen Rabatt, Gewichtungsvorteil bleibt aber erhalten.
- [ ] Coupon-Scam erzeugt keine Suspicion.
- [ ] Sortiment-Level-Up-Button zeigt naechsten Preis.
- [ ] Button ist disabled, wenn Geld nicht reicht.
- [ ] Level-Up-Kauf wirkt ab naechstem Kunden.
- [ ] Tooltip zeigt naechste Produkte und Werte.

### Phase-4-Akzeptanz

- [ ] Ein kompletter Run kann gespielt werden.
- [ ] Der Spieler kann normal verkaufen, mehrfach scannen, erwischt werden, Coupons kaufen/scammen und Sortiment upgraden.
- [ ] Tagesmiete, Lose und Win funktionieren.
- [ ] HUD zeigt Zustand korrekt, mutiert aber keinen Gameplay-State direkt.

## Phase 5 - Juice, Balancing, QA und Prototyp-Abschluss

Ziel: Der spielbare Prototyp fuehlt sich am Scanner gut an, ist bei `640x360`
lesbar und laesst sich stabil weiterentwickeln.

Empfohlener Session-Scope: eine Codex-Session fuer Juice/Polish, eine fuer QA
und offene Fixes.

### Scan-Juice

- [ ] Scanner-Beep beim erfolgreichen Scan abspielen.
- [ ] Pitch-Eskalation fuer Double-, Triple- und Multi-Scans einbauen.
- [ ] Scannerstrahl kurz aufleuchten lassen.
- [ ] Scannerflash am vorbereiteten VFX-Anker abspielen.
- [ ] Coin-VFX am Cursor oder Produktanker mit vorhandenem Coin-Asset abspielen.
- [ ] Offener Verkaufsbetrag gut lesbar ueber gehaltenem Produkt darstellen.
- [ ] Produkt-Wobble oder Squash beim erfolgreichen Scan abspielen.
- [ ] Kurzer Screen-Shake bei Double-Scan oder hoeher pruefen, ohne Lesbarkeit zu stoeren.

### Conveyor- und Drop-Juice

- [ ] Neue Produkte fahren weich von rechts ein.
- [ ] Nachruecken wirkt mechanisch und klar.
- [ ] Drop in Tute hat kurze Verkaufsanimation.
- [ ] Geld in linker Leiste zaehlt sichtbar hoch.
- [ ] Trash-Drop laesst Produkt/Coupon sauber verschwinden.
- [ ] VFX so kapseln, dass spaeter Pooling moeglich ist.

### Suspicion- und Dialog-Juice

- [ ] Mood-Ring pulsiert bei Suspicion-Anstieg.
- [ ] Hand-Platzhalter bekommt kleine Unruhe bei hoher Suspicion.
- [ ] Caught-Dialog und Customer-Bye-Dialog sind lesbar, kurz und per Enter steuerbar.
- [ ] Kein erklaerender Overload fuer Coupon-Scam einbauen.

### UI-Polish

- [ ] Alle Panels nutzen die 9-Slice-Panel-Architektur.
- [ ] Linke und rechte Sidebar bleiben bei `640x360` lesbar.
- [ ] Buttons zeigen klare enabled/disabled-Zustaende.
- [ ] Tooltips passen in den Viewport.
- [ ] Fontgroessen bleiben auf `11`, `22`, `33`, `44`.
- [ ] Keine UI-Texte ueberlappen.
- [ ] Pixel-Snap und nearest filtering bleiben erhalten.

### Balancing und Content-Finish

- [ ] Tag 1 ist bei ehrlichem Spiel knapp nicht schaffbar.
- [ ] Double-Scan-Risiko ist spuerbar, aber nicht unfair.
- [ ] Coupon-Preise, Rabatte und Gewichtungsboni grob spielbar einstellen.
- [ ] Sortiment-Level-Up-Kosten grob spielbar einstellen.
- [ ] Gescriptete erste drei Kunden testen.
- [ ] Seed-basierte spaetere Kunden testen.

### QA und Abschluss

- [ ] Content-Validierung ausfuehren.
- [ ] Unit-Tests ausfuehren.
- [ ] Spiel bei `640x360`-Authoring und `1280x720`-Run-Fenster visuell pruefen.
- [ ] Alle Platzhalter-Szenen im Editor auffindbar und austauschbar halten.
- [ ] Keine teuren Node-Suchen oder Asset-Ladevorgaenge im Scan-/Payout-Flow.
- [ ] Keine Gameplay-State-Mutation aus UI-Scripts.
- [ ] Keine Definition-Resources als mutable Runtime-State missbrauchen.
- [ ] Offene technische Schuld in diesem Dokument oder direkt am betroffenen Code markieren.

### Phase-5-Akzeptanz

- [ ] Der Scanner-Moment fuehlt sich als Kern des Spiels befriedigend an.
- [ ] Der Prototyp ist ohne echte Tisch-/Scanner-/Band-/Tueten-/Trash-/Hand-Assets spielbar.
- [ ] Fehlende Assets sind durch saubere Platzhalter-Szenen ersetzt.
- [ ] Die Code- und Szenenstruktur bleibt kompatibel mit `architecture.md`.
- [ ] Der naechste Entwicklungsschritt kann mit echten Assets oder erweitertem Content beginnen, ohne zentrale Systeme umzubauen.

## Definition of Done fuer den ersten spielbaren Prototyp

- [ ] 1-Screen-Gameplay mit linker Statusleiste, Kassentisch und rechter Upgrade-Leiste.
- [ ] Vier sichtbare Belt-Objekte und 10 Produkte pro Kunde.
- [ ] Scanner links im Kassentisch, quadratisch, mit vertikalem Strahl.
- [ ] Scans zaehlen nur rechts nach links.
- [ ] Tute ueber Scanner finalisiert Verkauf.
- [ ] Trash-Zone rechts unten verwirft Produkte oder Coupons.
- [ ] Kundenhand mit Mood-Ring zeigt Suspicion.
- [ ] Offener Verkaufsbetrag folgt gehaltenem Produkt.
- [ ] Cash in Drawer steigt erst beim Drop in die Tute.
- [ ] Mehrfachscan kann Caught-Dialog ausloesen.
- [ ] Miete am Tagesende, Lose bei Nichtzahlung, Win nach Tag 8.
- [ ] Coupon-Button und Sortiment-Level-Up-Button funktionieren.
- [ ] Produkt- und Coin-Assets werden verwendet.
- [ ] Fehlende Environment-Assets sind als editorseitige Platzhalter-Szenen vorhanden.
- [ ] Pure Gameplay-Logik ist durch Tests abgedeckt.
- [ ] Content-Validierung meldet kaputte IDs, Referenzen, Texturen und Balancing-Werte.
