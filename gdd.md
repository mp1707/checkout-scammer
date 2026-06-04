# Checkout Scammer – Design Dokument

## Meta

- Plattform: Steam
- Engine: Godot 4.6

## Core Player Craving und Juice-Source

- Ein Produkt über den Kassenscanner ziehen
- Das satisfying „Beep“-Geräusch hören
- Coin-Animation sehen
- Den aktuellen Verkaufsbetrag direkt am gehaltenen Produkt sehen
- Geld beim finalen Verkauf direkt hochzählen sehen
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
- Es werden immer maximal 4 Objekte gleichzeitig auf dem Fließband angezeigt.
- Ohne Coupon sind das 4 Produkte.
- Mit Coupon kann ein sichtbarer Slot durch den Coupon belegt sein.
- Ein Kunde hat weiterhin 10 Produkte.
- Initial fahren die ersten 4 Objekte ins Bild.
- Wenn ein Coupon für diesen Kunden aktiv ist, ist er das erste Objekt, gefolgt von den ersten Produkten.
- Sobald ein Produkt vom Fließband genommen wurde, rutscht ein neues Produkt nach.
- Das wiederholt sich, bis alle 10 Produkte des Kunden verarbeitet wurden.
- Wenn keine Produkte mehr im Kunden-Queue sind, bleibt das Fließband leer.

### Tüte

- Über dem Scanner befindet sich die Tüte.
- Gescannte Produkte werden in die Tüte gelegt, um den Verkauf final abzuschließen.
- Ein Scan bucht noch kein Geld in den Total-Wert.
- Solange der Spieler ein gescanntes Produkt hält, schwebt der aktuelle Verkaufsbetrag am Cursor leicht über dem Produkt.
- Beim Ablegen in der Tüte wird dieser aktuelle Verkaufsbetrag zum Total-Wert hinzugefügt.
- Danach verschwindet das Produkt in der Tüte.
- Ein in die Tüte gelegtes Produkt gilt als verkauft und kann nicht mehr aufgehoben oder erneut gescannt werden.
- Mehrfachscans passieren nur, solange der Spieler dasselbe Produkt weiter hält.

### Müll-Loch

- Rechts unten im Eck des Kassentisches befindet sich das Müll-Loch.
- Es liegt unter dem Fließband.
- Es ist ein rundes Loch im Tisch mit Label `Trash`.
- Produkte oder Coupons können dort hineingeworfen werden.
- Wird ein Coupon in den Müll geworfen, wird er nicht gescannt.
- Das ist eine versteckte Scam-Mechanik.
- Wird ein Produkt mit offenem Verkaufsbetrag in den Müll geworfen, verschwindet es und der offene Betrag wird nicht gebucht.

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
- Für den Prototyp ist die Produktanzahl auf 10 gesetzt, aber zentral im Balancing pflegbar.
- Der erste Tag hat 3 gescriptete Kunden.
- Diese 3 Kunden bringen bei ehrlichem Spiel knapp nicht genug Geld ein.
- Dadurch lernt der Spieler die Scam-Mechanik.
- Runs und zufällige Kunden werden deterministisch über einen Seed erzeugt.
- Der gleiche Seed soll die gleiche Kunden- und Produktfolge erzeugen.

## Balancing-Defaults

- Startgeld: `10$`
- Tagesmiete im Prototyp: `40$`
- Produktpreise im Startsortiment liegen grob zwischen `0,50$` und `1,80$`.
- Diese Werte sind erste Platzhalter und dürfen später beim Balancing angepasst werden.
- Wichtig: Balancing muss zentralisiert und im Godot-Editor einfach editierbar sein.
- Zentral pflegbar sein sollen mindestens:
  - Startgeld
  - Tagesmiete / Mietkurve
  - Tage pro Run
  - Kunden pro Tag
  - Produkte pro Kunde
  - sichtbare Fließband-Slots
  - Produktpreise
  - Produktgewichte für die Kundengenerierung
  - Coupon-Kosten
  - Coupon-Rabatte
  - Coupon-Gewichtungsboni
  - Sortiment-Level-Up-Kosten
  - Suspicion-Stufen

### Erste Startprodukt-Werte

- Snacks:
  - Kaugummi: `0,50$`
  - Chips: `0,80$`
  - Schokoriegel: `1,00$`
- Getränke:
  - Wasser: `0,90$`
  - Limo: `1,20$`
  - Energy Drink: `1,80$`
- Obst:
  - Apfel: `0,60$`
  - Banane: `0,70$`
  - Orange: `1,10$`

## Kunden-Produktfluss

- Ein Kunde hat intern eine Queue aus 10 Produkten.
- Zu Beginn eines Kunden fahren die ersten 4 Objekte von rechts auf das Fließband.
- Nur diese 4 Objekte sind gleichzeitig sichtbar.
- Wenn ein Coupon für diesen Kunden aktiv ist, ist der Coupon das erste Objekt und danach folgen die ersten Produkte.
- Wenn ein Produkt vom Fließband genommen wird, rutscht das nächste Produkt aus der Queue nach.
- Dadurch bleibt das Spielfeld übersichtlich.
- Der Spieler verarbeitet alle 10 Produkte nacheinander.
- Die Reihenfolge innerhalb der sichtbaren Produkt-Slots ist frei wählbar.
- Produkte können:
  - gescannt werden
  - in die Tüte gelegt werden
  - mehrfach gescannt werden
  - in den Müll geworfen werden, falls das Produkt oder Objekt dafür gedacht ist
- Jeder erfolgreiche Scan erhöht den offenen Verkaufsbetrag des aktuell gehaltenen Produkts.
- Der offene Verkaufsbetrag wird erst beim Ablegen in der Tüte zum Total-Wert gebucht.

## Suspicion-System

- Jeder Kunde hat ein internes Suspicion-Meter.
- Das Suspicion-Meter ist die Wahrscheinlichkeit, beim Betrügen erwischt zu werden.
- Es startet pro Kunde bei 10%.
- Ein Caught-Roll passiert bei jedem Produkt-Scan ab dem zweiten Scan desselben Produkts.
- Der erste Scan eines Produkts ist immer sicher.
- Coupon-Scam löst keinen Caught-Roll aus.
- Wenn ein Mehrfachscan nicht erwischt wird, steigt die Suspicion danach an.
- Nach einem erfolgreichen Double Scan steigt sie auf 50%.
- Danach steigt sie auf 75%.
- Danach steigt sie auf 90%.
- Bei 90% bleibt es.
- Mehrfachscans sind unbegrenzt möglich, bis der Spieler erwischt wird oder das Produkt verkauft.
- Neuer Kunde = neues Suspicion-Meter bei 10%.
- Die aktuelle Suspicion wird über den Mood-Ring an der Kundenhand angezeigt.

## Erwischen / Strafe

- Wird man erwischt, erscheint eine Textbox:

`Kunde: Hey, do you want to scam me? I want compensation!`

- Die Textbox muss mit Enter weggeklickt werden.
- Die Wirkung:
  - Das aktuelle Produkt verschwindet visuell.
  - Der offene Verkaufsbetrag am Cursor wird gelöscht.
  - Es wird kein Geld vom Total-Wert abgezogen.
  - Dadurch verliert der Spieler nur den noch nicht gebuchten Wert dieses Produkts.
- Danach geht der Kunde weiter normal.

## Tagesende

- Zwischen Geschäftstagen, also immer nach 3 Kunden, wird die Miete bezahlt.
- Kann man die Miete nicht zahlen, verliert man sofort.
- Eine spätere Schuldenmechanik ist möglich, aber out of scope für den Prototyp.
- Aktive Tages-Coupons laufen am Tagesende aus.

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
- Ein gekaufter Coupon gilt für den Geschäftstag, in dem er aktiviert wird.
- Wird ein Coupon während eines aktiven Kunden gekauft, wird er beim nächsten Kunden aktiviert.
- Wird ein Coupon beim letzten Kunden eines Geschäftstags gekauft, aktiviert er sich beim ersten Kunden des nächsten Geschäftstags.
- Der Mouseover-Tooltip des Coupon-Buttons erklärt diese Verzögerung.
- Beispiel:
  - Am Anfang gibt es viele 0,50$ Produkte.
  - Es gibt wenige 1$ Produkte.
  - Ein Coupon sorgt dafür, dass Kunden mehr 1$ Produkte kaufen.
  - Dadurch verdient man insgesamt mehr Geld.

### Coupon-Scam

- Wenn ein Kunde Produkte kauft, die durch einen Coupon beeinflusst wurden, kommt der passende Coupon mit aufs Fließband.
- Der Coupon ist ein Extra-Objekt und zählt nicht zu den 10 Produkten des Kunden.
- Der Coupon wird immer als erstes Objekt auf das Fließband gelegt.
- Er belegt einen sichtbaren Fließband-Slot, reduziert aber nicht die interne Produktanzahl des Kunden.
- Der Spieler kann den Coupon ehrlich scannen.
- Dann wird der Rabatt für alle danach gescannten passenden Produkte dieses Kunden angewendet.
- Der Spieler kann den Coupon aber auch in das Müll-Loch werfen.
- Dadurch erhält der Spieler den Vorteil des Coupons:
  - Kunden kaufen wertvollere Produkte
- Aber der Nachteil wird negiert:
  - Der Rabatt wird nicht angewendet
- Coupon-Scam erhöht keine Suspicion und löst keinen Caught-Roll aus.
- Diese Mechanik soll nicht stark erklärt werden.
- Der Spieler soll sie selbst herausfinden.

## Sortiment-Level-Up

- Der Sortiment-Level-Up-Button zeigt immer den Preis der nächsten Stufe an.
- Ähnlich wie die Münzverbesserung bei Scritchy Scratch.
- Der Button ist ausgegraut, wenn man nicht genug Geld hat.
- Wenn man genug Geld hat, kann man das Sortiment mit einem Klick hochleveln.
- Dadurch wird der Produktpool erweitert.
- Sortiment-Level-Ups können auch während eines aktiven Kunden gekauft werden.
- Sie wirken erst ab dem nächsten Kunden.
- Der Mouseover-Tooltip erklärt diese Verzögerung.
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
- Die ersten 4 Objekte fahren von rechts auf das Fließband.
- Falls für diesen Kunden ein Coupon aktiv ist, liegt er zuerst auf dem Fließband.
- Der Spieler nimmt ein Produkt vom Fließband.
- Der Spieler zieht das Produkt von rechts nach links über den vertikalen Scannerstrahl.
- Scan löst aus:
  - Beep
  - Coin-Animation
  - Verkaufsbetrag am Cursor erhöht sich
  - Scanner-Feedback
- Danach kann der Spieler das Produkt nochmal scannen oder in die Tüte legen.
- Beim Ablegen in die Tüte wird der offene Verkaufsbetrag zum Total-Wert gebucht.
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
- Der erste erfolgreiche Scan eines Produkts erzeugt den offenen Verkaufsbetrag am Cursor.
- Jeder weitere erfolgreiche Scan desselben gehaltenen Produkts erhöht diesen offenen Verkaufsbetrag erneut um den Produktwert.
- Bei Mehrfachscans wird vor dem erfolgreichen Hinzufügen ein Caught-Roll gegen die aktuelle Suspicion ausgeführt.

## Drag-&-Drop-Regeln

- Produkt wird angeklickt oder gedrückt gehalten.
- Dadurch haftet es am Cursor.
- Während des Drags kann es über den Scanner gezogen werden.
- Danach kann es abgelegt werden:
  - in der Tüte
  - im Müll-Loch
  - optional zurück auf dem Fließband, falls nötig
- Beim Ablegen in der Tüte gilt das Produkt als verkauft und verarbeitet.
- Der offene Verkaufsbetrag wird erst in diesem Moment zum Total-Wert gebucht.
- Beim Ablegen im Müll-Loch verschwindet das Produkt oder der Coupon.
- Produkte in der Tüte können nicht erneut aufgenommen werden.

## Juice-Fokus

- Das Scannen der Produkte ist der wichtigste Kern des Spiels.
- Scannen muss sich extrem satisfying anfühlen.
- Der Spieler soll auch nach 200 Produkten noch Lust auf den nächsten Scan haben.

### Scan-Juice

- Angenehmer Beep-SFX
- Pitch-Eskalation bei Double-, Triple- und Multi-Scans
- Coin-Animation am Cursor
- Offener Verkaufsbetrag schwebt gut lesbar über dem gehaltenen Produkt
- Geld zählt links in der Menüleiste animiert hoch, wenn das Produkt in die Tüte gelegt wird
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
- Maximal 4 sichtbare Belt-Objekte
- 10 Produkte pro Kunde
- Scanner links, quadratisch, vertikaler Strahl
- Scannen nur von rechts nach links
- Tüte über dem Scanner
- Müll-Loch rechts unten
- Kundenhand rechts oben mit Mood-Ring
- Offener Verkaufsbetrag am Cursor
- Geld zählt beim Ablegen in der Tüte direkt hoch
- Double-Scan erhöht Suspicion
- Miete am Tagesende
- Lose bei nicht bezahlbarer Miete
- Coupon- und Sortiment-Upgrade als einfache Buttons
