# Checkout Scammer – Design Dokument

## Meta

- Plattform: Steam
- Engine: Godot

## Core Player Craving und Juice-Source

- Ein Produkt über den Kassenscanner ziehen
- Das satisfying „Beep“-Geräusch hören
- Coin-Animation sehen
- Geld direkt hochzählen sehen
- Der Scanner-Moment ist der wichtigste Kern des Spiels

## Perspektive und Art-Style

- 2D Pixel-Art
- Minimalistisch wie Scritchy Scratch
- 1-Screen-Gameplay
- Abstrakt, ohne sichtbaren Player-Sprite
- Kein vollständig sichtbarer Kunde
- Der Kunde wird nur durch eine Hand angedeutet
- UI-Stil angelehnt an Scritchy Scratch / Balatro
- Top-Down-Ansicht
- Der Kassentisch ist das zentrale Spielfeld
- Links und rechts davon befinden sich Menüleisten für Status, Geld und Upgrades

## Layout

- Der Screen ist in drei Hauptbereiche aufgeteilt:
  - Linke Menüleiste: ca. 15% Breite
  - Mittlerer Viewport / Kassentisch: ca. 70% Breite
  - Rechte Menüleiste: ca. 15% Breite

### Linke Menüleiste

- Zeigt:
  - Tag
  - Kunde, z.B. `1/3`
  - Mietziel / „Rent due tonight“
  - Aktuelles Geld / „Cash in Drawer“

### Mittlerer Viewport / Kassentisch

- Der mittlere Bereich ist der Kassentisch.
- Das Spielfeld soll wie ein abstrakter Kassentisch wirken, nicht wie ein realistischer Supermarkt.
- Der Tisch darf klare, simple Shapes haben.
- Reale Objekte werden nur sparsam angedeutet.

### Scanner

- Der Scanner ist links im Kassentisch eingelassen.
- Er sitzt am linken Rand des mittleren Viewports.
- Er ist vertikal mittig auf dem Tisch platziert.
- Der Scanner ist quadratisch.
- Der Scannerstrahl ist vertikal.
- Der Scanner funktioniert nur, wenn ein Produkt von rechts nach links über den Scanner gezogen wird.
- Wird ein Produkt von links nach rechts über den Scanner gezogen, passiert nichts.
- Dadurch fühlt sich der Scan wie eine bewusste Kassierbewegung an.

### Fließband / Conveyor Belt

- Rechts neben dem Scanner liegt das Fließband.
- Produkte kommen von rechts über das Fließband herein.
- Das Fließband reicht visuell aus dem mittleren Viewport heraus und wird dort abgeschnitten.
- Dadurch entsteht der Eindruck, dass neue Produkte von außerhalb des sichtbaren Bereichs kommen.
- Es werden immer maximal 4 Produkte gleichzeitig auf dem Fließband angezeigt.
- Ein Kunde hat weiterhin 10 Produkte.
- Initial fahren die ersten 4 Produkte ins Bild.
- Sobald ein Produkt vom Fließband genommen wurde, rutscht ein neues Produkt nach.
- Das wiederholt sich, bis alle 10 Produkte des Kunden verarbeitet wurden.
- Wenn keine Produkte mehr im Kunden-Queue sind, bleibt das Fließband leer.

### Tüte

- Über dem Scanner befindet sich die Tüte.
- Gescannten Produkte werden nach dem Scan in die Tüte gelegt.
- Wenn ein Produkt in die Tüte gelegt wird, gilt es als verarbeitet.
- Die Produktsprites verschwinden dann einfach.
- Das zuletzt abgelegte Produkt bleibt sichtbar auf der Tüte liegen.
- Dadurch kann man es nochmal nehmen und erneut scannen.
- Wird ein weiteres Produkt abgelegt, verschwindet das vorherige sichtbare Produkt.

### Müll-Loch

- Rechts unten im Eck des Kassentisches befindet sich das Müll-Loch.
- Es liegt unter dem Fließband.
- Es ist ein rundes Loch im Tisch mit Label `Trash`.
- Produkte oder Coupons können dort hineingeworfen werden.
- Wird ein Coupon in den Müll geworfen, wird er nicht gescannt.
- Das ist eine versteckte Scam-Mechanik.

### Kundenhand und Mood-Ring

- Rechts oben über dem Fließband ist eine Kundenhand sichtbar.
- Die Hand deutet den Kunden an, ohne einen vollständigen Kunden zu zeigen.
- Die Hand trägt einen Mood-Ring.
- Der Mood-Ring zeigt die aktuelle Suspicion farblich an:
  - Grün: niedrige Suspicion
  - Gelb: erhöhte Suspicion
  - Orange: hohe Suspicion
  - Rot: sehr hohe Suspicion
- Es gibt keine plumpe Suspicion-Progressbar mit Zahl.
- Der Ring ist die kreative, diegetische Anzeige des Suspicion-Meters.

### Rechte Menüleiste

- Zeigt Upgrades.
- Enthält:
  - Coupon-Button
  - Sortiment-Level-Up-Button
  - Platz für spätere Upgrades

## Game Setting

- Der Spieler ist Convenience-Store-/Kiosk-Besitzer und Kassierer.
- Ziel: Jeden Tag die Miete zahlen können und so viel Geld wie möglich einnehmen, um Upgrades zu kaufen.
- Twist: Man merkt bereits am ersten Tag, dass man durch normales Scannen und Abkassieren die Miete nicht zahlen kann.
- Die Summe des normalen Produktwerts reicht knapp nicht aus, um die Miete zu zahlen.
- Man muss also kreativ werden und Kunden betrügen, indem man Produkte mehrfach scannt.

## Grundstruktur / Runs

- Ein Run besteht aus 8 Geschäftstagen.
- Ein Geschäftstag besteht aus 3 Kunden.
- Ein Kunde hat 10 zufällige Produkte.
- Für den Prototyp wird die Produktanzahl hardcoded auf 10 gesetzt.
- Der erste Tag hat 3 gescriptete Kunden.
- Diese 3 Kunden bringen bei ehrlichem Spiel knapp nicht genug Geld ein.
- Dadurch lernt der Spieler die Scam-Mechanik.

## Kunden-Produktfluss

- Ein Kunde hat intern eine Queue aus 10 Produkten.
- Zu Beginn eines Kunden fahren die ersten 4 Produkte von rechts auf das Fließband.
- Nur diese 4 Produkte sind gleichzeitig sichtbar.
- Wenn ein Produkt vom Fließband genommen wird, rutscht das nächste Produkt aus der Queue nach.
- Dadurch bleibt das Spielfeld übersichtlich.
- Der Spieler verarbeitet alle 10 Produkte nacheinander.
- Die Reihenfolge innerhalb der sichtbaren 4 Produkte ist frei wählbar.
- Produkte können:
  - gescannt werden
  - in die Tüte gelegt werden
  - mehrfach gescannt werden
  - in den Müll geworfen werden, falls das Produkt oder Objekt dafür gedacht ist

## Suspicion-System

- Jeder Kunde hat ein internes Suspicion-Meter.
- Das Suspicion-Meter ist die Wahrscheinlichkeit, beim Betrügen erwischt zu werden.
- Es startet pro Kunde bei 10%.
- Nach einem Double Scan steigt es auf 50%.
- Danach steigt es auf 75%.
- Danach steigt es auf 90%.
- Bei 90% bleibt es.
- Neuer Kunde = neues Suspicion-Meter bei 10%.
- Die aktuelle Suspicion wird über den Mood-Ring an der Kundenhand angezeigt.

## Erwischen / Strafe

- Wird man erwischt, erscheint eine Textbox:

`Kunde: Hey, do you want to scam me? I want compensation!`

- Die Textbox muss mit Enter weggeklickt werden.
- Die Wirkung:
  - Das aktuelle Produkt verschwindet visuell.
  - Der Wert des Produkts wird vom Geld abgezogen.
  - Dadurch hat man dieses Produkt praktisch verschenkt.
- Danach geht der Kunde weiter normal.

## Tagesende

- Zwischen Geschäftstagen, also immer nach 3 Kunden, wird die Miete bezahlt.
- Kann man die Miete nicht zahlen, verliert man sofort.
- Eine spätere Schuldenmechanik ist möglich, aber out of scope für den Prototyp.

## Upgrades

- In der rechten Menüleiste gibt es temporäre und permanente Upgrades:
  - Coupons
  - Sortiment-Level-Up

## Coupons

- Der Coupon-Button öffnet ein Popup-Menü.
- Dort erscheinen Coupons nur für Produkte, die bereits im Sortiment sind.
- Beispiel:

`Coupon: Apfel -20%`

- Mouseover-Tooltip:

`Kunden kaufen mehr Äpfel.`

- Coupons erhöhen die Chance, dass Kunden bestimmte Produkte kaufen.
- Dadurch kann man die Chance auf wertvollere Produkte erhöhen.
- Beispiel:
  - Am Anfang gibt es viele 0,50$ Produkte.
  - Es gibt wenige 1$ Produkte.
  - Ein Coupon sorgt dafür, dass Kunden mehr 1$ Produkte kaufen.
  - Dadurch verdient man insgesamt mehr Geld.

### Coupon-Scam

- Wenn ein Kunde Produkte kauft, die durch einen Coupon beeinflusst wurden, kommt der passende Coupon mit aufs Fließband.
- Der Spieler kann den Coupon ehrlich scannen.
- Dann wird der Rabatt angewendet.
- Der Spieler kann den Coupon aber auch in das Müll-Loch werfen.
- Dadurch erhält der Spieler den Vorteil des Coupons:
  - Kunden kaufen wertvollere Produkte
- Aber der Nachteil wird negiert:
  - Der Rabatt wird nicht angewendet
- Diese Mechanik soll nicht stark erklärt werden.
- Der Spieler soll sie selbst herausfinden.

## Sortiment-Level-Up

- Der Sortiment-Level-Up-Button zeigt immer den Preis der nächsten Stufe an.
- Ähnlich wie die Münzverbesserung bei Scritchy Scratch.
- Der Button ist ausgegraut, wenn man nicht genug Geld hat.
- Wenn man genug Geld hat, kann man das Sortiment mit einem Klick hochleveln.
- Dadurch wird der Produktpool erweitert.
- Mouseover zeigt:
  - Welche Produkte im nächsten Level enthalten sind
  - Was diese Produkte wert sind
- Am Anfang hat man nur Billigprodukte.
- Durch Sortiment-Level-Ups arbeitet man sich langsam zu wertvolleren Produkten hoch.

## Win / Lose

- Win:
  - Am Ende von Tag 8 die Miete zahlen können
- Lose:
  - Tagesmiete nicht bezahlen können
- Kein Zeitdruck
- Später kann das Spiel endlos skalieren, aber das ist out of scope für den Prototyp.

## Sortiment einfach gedacht

- Kein detailliertes Sortiment-Management.
- Keine Stückzahlen.
- Kein Lagerbestand.
- Keine Einkaufspreise.
- Produkte werden nicht einzeln verwaltet.
- Stattdessen gibt es:
  - Startsortiment
  - Sortimentserweiterungen über den Level-Up-Button

## Start-Sortiment

- Für den Anfang gibt es nur wenige Produktlinien:
  - Snacks
  - Getränke
  - Obst
- Diese drei Kategorien reichen für den ersten Prototyp.

## Mögliche spätere Produktlinien

Out of scope für den Prototyp:

- Bürobedarf
- Hygieneartikel
- Kühlware
- Luxusartikel

## Core-Gameplay-Loop

- Kunde startet.
- Die ersten 4 Produkte fahren von rechts auf das Fließband.
- Der Spieler nimmt ein Produkt vom Fließband.
- Der Spieler zieht das Produkt von rechts nach links über den vertikalen Scannerstrahl.
- Scan löst aus:
  - Beep
  - Coin-Animation
  - Geld zählt hoch
  - Scanner-Feedback
- Danach legt der Spieler das Produkt in die Tüte.
- Wenn ein Produkt vom Band genommen wurde, fährt das nächste Produkt nach.
- Der Spieler verarbeitet alle 10 Produkte des Kunden.
- Produkte können mehrfach gescannt werden.
- Mehrfaches Scannen erhöht die Suspicion.
- Die Suspicion wird über den Mood-Ring an der Kundenhand angezeigt.
- Nach dem letzten verarbeiteten Produkt erscheint nach einer Sekunde eine Textbox:

`Thanks, byyyyyeeeeee`

- Die Textbox muss mit Enter weggeklickt werden.
- Danach kommt der nächste Kunde.
- Nach 3 Kunden endet der Geschäftstag.
- Am Tagesende wird die Miete bezahlt.
- Upgrades können jederzeit gekauft werden und wirken ab dem nächsten Kunden.

## Scan-Regeln

- Ein Scan zählt nur, wenn:
  - ein Produkt aktiv gehalten wird
  - das Produkt den vertikalen Scannerstrahl berührt
  - die Bewegung von rechts nach links passiert
- Kein Scan zählt, wenn:
  - das Produkt von links nach rechts gezogen wird
  - das Produkt nur auf dem Scanner liegt
  - das Produkt nicht aktiv gezogen wird
- Dadurch wird der Scan-Moment klarer und absichtlicher.

## Drag-&-Drop-Regeln

- Produkt wird angeklickt oder gedrückt gehalten.
- Dadurch haftet es am Cursor.
- Während des Drags kann es über den Scanner gezogen werden.
- Danach kann es abgelegt werden:
  - in der Tüte
  - im Müll-Loch
  - optional zurück auf dem Fließband, falls nötig
- Beim Ablegen in der Tüte gilt das Produkt als verarbeitet.
- Beim Ablegen im Müll-Loch verschwindet das Produkt oder der Coupon.
- Das letzte Produkt in der Tüte bleibt sichtbar und kann erneut aufgenommen werden.

## Juice-Fokus

- Das Scannen der Produkte ist der wichtigste Kern des Spiels.
- Scannen muss sich extrem satisfying anfühlen.
- Der Spieler soll auch nach 200 Produkten noch Lust auf den nächsten Scan haben.

### Scan-Juice

- Angenehmer Beep-SFX
- Pitch-Eskalation bei Double-, Triple- und Multi-Scans
- Coin-Animation am Cursor
- Geld zählt links in der Menüleiste animiert hoch
- Kurzer Screen Shake bei Double Scans
- Visuelles Feedback am Scanner
- Kurzes Aufleuchten des vertikalen Scannerstrahls
- Kleine Partikel entlang des Scannerstrahls
- Produkt wobbelt oder squasht kurz beim erfolgreichen Scan

### Conveyor-Juice

- Neue Produkte fahren weich von rechts rein.
- Das Fließband hat subtile Bewegung.
- Wenn ein Produkt vom Band genommen wird, rückt das nächste Produkt nach.
- Die Bewegung soll mechanisch und satisfying wirken.
- Nicht zu realistisch, eher abstrakt und toy-like.

### Suspicion-Juice

- Der Mood-Ring färbt sich sichtbar um.
- Bei steigender Suspicion kann der Ring kurz pulsieren.
- Bei hoher Suspicion kann die Kundenhand minimal unruhig wirken.
- Kein komplexes Animationssystem nötig.
- Kleine visuelle Andeutungen reichen.

## Prototyp-Fokus

Für den ersten spielbaren Prototyp ist wichtig:

- 1 Screen
- Linke Statusleiste
- Mittlerer Kassentisch
- Rechte Upgrade-Leiste
- Conveyor Belt rechts neben Scanner
- Maximal 4 sichtbare Produkte
- 10 Produkte pro Kunde
- Scanner links, quadratisch, vertikaler Strahl
- Scannen nur von rechts nach links
- Tüte über dem Scanner
- Müll-Loch rechts unten
- Kundenhand rechts oben mit Mood-Ring
- Geld zählt direkt hoch
- Double-Scan erhöht Suspicion
- Miete am Tagesende
- Lose bei nicht bezahlbarer Miete
- Coupon- und Sortiment-Upgrade als einfache Buttons