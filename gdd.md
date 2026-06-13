# Checkout Scammer – Design Dokument

## Meta

- Plattform: Steam
- Engine: Godot 4.6

## Core Player Craving und Juice-Source

- Ein Produkt über den Kassenscanner ziehen
- Das satisfying „Beep“-Geräusch hören
- Coin-Animation beim Ablegen in die Tüte sehen
- Den aktuellen Verkaufsbetrag im Kassendisplay sehen
- Geld beim finalen Verkauf direkt hochzählen sehen
- Der Scanner-Moment ist der wichtigste Kern des Spiels

## Perspektive und Art-Style

- 2D Pixel-Art
- Minimalistisch wie Scritchy Scratch
- 1-Screen-Gameplay
- Abstrakt, ohne sichtbaren Player-Sprite
- Kein vollständig sichtbarer Kunde
- Der Kunde wird nur durch einen kundenspezifischen Signalträger im rechten Tischbereich angedeutet
- UI-Stil angelehnt an Scritchy Scratch / Balatro
- Alle Spiel- und UI-Farben nutzen die Endesga-64-Palette: <https://lospec.com/palette-list/endesga-64>
- Menüs, Schriften, Buttons, Tooltips, Scannerfeedback, Schatten und Popups verwenden nur Farben aus dieser Palette.
- Neue UI-Farben werden als Theme-Tokens gepflegt, nicht frei pro Szene gemischt.
- Transparenz darf genutzt werden, aber die zugrunde liegende RGB-Farbe bleibt aus Endesga 64.
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

- Der Scanner ist im Kassentisch-Sprite eingelassen.
- Er sitzt vorerst in der Mitte des Tisches.
- Der Scannerstrahl ist vertikal und wird als separates VFX-/Feedback-Element erzeugt.
- Der Scanner funktioniert nur, wenn ein Produkt von rechts nach links über den Scanner gezogen wird.
- Wird ein Produkt von links nach rechts über den Scanner gezogen, passiert nichts.
- Obst ist nicht scannerverkaufbar. Wird Obst über den Scanner gezogen, wird kein Betrag hinzugefügt und kein Suspicion-Roll ausgelöst.
- Dadurch fühlt sich der Scan wie eine bewusste Kassierbewegung an.

### Waage

- Obst muss über die Waage verkauft werden.
- Die Waage steht im Tischbereich oberhalb des Scanners.
- Die Waage ist eine eigene Drop-Zone und akzeptiert immer nur ein wiegbares Produkt gleichzeitig.
- Wenn Obst auf die Waage gelegt wird, spielt die Waage die Press-Animation aus `waage_sheet.png`.
- Solange Obst auf der Waage liegt, bleibt die Waage visuell belastet.
- Das Ablegen auf der Waage berechnet direkt den Betrag aus Gewicht, Kilopreis, Coupons und Stickern.
- Der berechnete Betrag erscheint im Kassendisplay und wird zum offenen Verkaufsbetrag des Obstes addiert.
- Obst kann mehrfach gewogen werden.
- Zum mehrfachen Buchen kann Obst mit der Maus von der Waage hochgehoben und erneut abgelegt werden.
- Während das Obst hochgehoben wird, verschwindet der Betrag aus dem Kassendisplay; der offene Betrag bleibt am Obst gespeichert.
- Wird dasselbe Obst später erneut gewogen, erhöht sich sein aktueller offener Verkaufsbetrag erneut.
- Wird ein Sticker auf Obst geklebt, das gerade auf der Waage liegt, aktualisiert sich der offene Verkaufsbetrag im Kassendisplay sofort.
- Die erste Wiegung ist sicher.
- Ab der zweiten Wiegung desselben Obstes läuft derselbe Suspicion-/Caught-Pfad wie bei Mehrfachscans.
- Bei Caught verschwindet das Obst, der offene Betrag wird gelöscht und kein Geld wird gebucht.

### Produktfläche

- Rechts neben dem Scanner liegen die Produkte verstreut auf dem Kassentisch.
- Es gibt kein sichtbares Fließband mehr.
- Neue Produkte rutschen weiterhin von rechts in die Produktfläche hinein.
- Dadurch entsteht der Eindruck, dass neue Produkte von außerhalb des sichtbaren Bereichs kommen, ohne dass ein Band dargestellt wird.
- Es werden immer maximal 4 aktive Objekte gleichzeitig auf der Produktfläche angezeigt.
- Ohne Coupon sind das 4 Produkte.
- Mit Coupon kann ein sichtbarer Slot durch den Coupon belegt sein.
- Ein Kunde hat weiterhin 10 Produkte.
- Initial fahren die ersten 4 Objekte ins Bild.
- Wenn ein Coupon für diesen Kunden aktiv ist, ist er das erste Objekt, gefolgt von den ersten Produkten.
- Sobald ein Produkt nur aufgenommen wurde, rutscht noch kein neues Produkt nach.
- Ein neues Produkt rutscht erst nach, wenn eines der 4 aktiven Objekte in der Tüte, im Müll oder durch Erwischen verschwunden ist.
- Das wiederholt sich, bis alle 10 Produkte des Kunden verarbeitet wurden.
- Wenn keine Produkte mehr im Kunden-Queue sind, bleibt die Produktfläche leer.

### Tüte

- Über dem Scanner befindet sich die Tüte.
- Gescannte Produkte werden in die Tüte gelegt, um den Verkauf final abzuschließen.
- Gewogenes Obst wird nach dem Wiegen manuell von der Waage genommen und in die Tüte gelegt.
- Obst ohne offenen Verkaufsbetrag wird in der Tüte abgelehnt und nicht verarbeitet.
- Ein Scan bucht noch kein Geld in den Total-Wert.
- Nach einem erfolgreichen Scan oder einer erfolgreichen Wiegung zeigt das Display der Kasse den offenen Verkaufsbetrag des aktuell gebuchten Produktes.
- Der aktuelle Verkaufsbetrag nutzt grüne, displaytypische Schrift direkt im Kassendisplay.
- Beim Ablegen in der Tüte wird dieser aktuelle Verkaufsbetrag zum Total-Wert hinzugefügt.
- Danach verschwindet das Produkt in der Tüte.
- Ein in die Tüte gelegtes Produkt gilt als verkauft und kann nicht mehr aufgehoben oder erneut gescannt werden.
- Mehrfachscans bei Festpreis-Produkten passieren nur, solange der Spieler dasselbe Produkt weiter hält.

### Müll-Loch

- Rechts unten im Eck des Kassentisches befindet sich das Müll-Loch.
- Es liegt unter der Produktfläche.
- Es ist ein rundes Loch im Tisch mit Label `Trash`.
- Produkte oder Coupons können dort hineingeworfen werden.
- Wird ein Coupon in den Müll geworfen, wird er nicht gescannt.
- Das ist eine versteckte Scam-Mechanik.
- Wird ein Produkt mit offenem Verkaufsbetrag in den Müll geworfen, verschwindet es und der offene Betrag wird nicht gebucht.

### Kundensignal

- Rechts oben über der Produktfläche ist der Signalträger des aktuellen Kundentyps sichtbar.
- Der Signalträger deutet den Kunden an, ohne einen vollständigen Kunden zu zeigen.
- Es gibt vier optisch unterscheidbare Kundentypen: Jimmy, Margaret, Chad und Doris.
- Der Signalträger zeigt die aktuelle Suspicion über drei gezeichnete Sprite-Stufen:
  - Grün: Anfangszustand.
  - Gelb: nach einem erfolgreichen Doppel-Scan.
  - Rot: nach zwei oder mehr erfolgreichen Doppel-Scans.
- Es gibt keine plumpe Suspicion-Progressbar mit Zahl.
- Der Signalträger ist die kreative, diegetische Anzeige des Suspicion-Meters.
- Mouseover über den Kunden-/Signalträgerbereich zeigt Name und Beschreibung des Kundentyps.

### Rechte Menüleiste

- Zeigt Upgrades.
- Enthält:
  - Coupon-Button
  - Sortiment-Level-Up-Button
  - Sticker-Button

## Game Setting

- Der Spieler ist Convenience-Store-/Kiosk-Besitzer und Kassierer.
- Ziel: Jeden Tag die Miete zahlen können und so viel Geld wie möglich einnehmen, um Upgrades zu kaufen.
- Twist: Man merkt bereits am ersten Tag, dass man durch normales Scannen und Abkassieren die Miete nicht zahlen kann.
- Die Summe des normalen Produktwerts reicht knapp nicht aus, um die Miete zu zahlen.
- Man muss also kreativ werden und Kunden betrügen, indem man Produkte mehrfach scannt.

## Kundentypen

Jeder Kunde hat einen Typ. Der Typ bestimmt, aus welchem Preisbereich des aktuellen Sortiments Produkte gezogen werden, wie schnell Suspicion steigt und welche Zusatzstrafe bei Caught passiert.

- Jimmy (Kid)
  - Tooltip: `Doesn't pay attention at all and pays with the credit card of his mom.`
  - Kaufverhalten: billigste `30%` des aktuell freigeschalteten Sortiments.
  - Suspicion: `0 -> 20 -> 45 -> 70`.
  - Caught-Strafe: nur das aktuelle Produkt geht verloren.
- Margaret (Fatlady)
  - Tooltip: `A wealthy regular who trusts you completely — unless the mood ring turns red.`
  - Kaufverhalten: gesamtes aktuell freigeschaltetes Sortiment.
  - Suspicion: `10 -> 50 -> 75 -> 90`.
  - Caught-Strafe: nur das aktuelle Produkt geht verloren.
- Chad (Businessman)
  - Tooltip: `Always in a hurry, yet paranoid enough to watch your every move.`
  - Kaufverhalten: teuerste `30%` des aktuell freigeschalteten Sortiments.
  - Suspicion: `30 -> 65 -> 85 -> 95`.
  - Caught-Strafe: aktuelles Produkt geht verloren und zusätzlich wird einmal dessen Produktwert vom aktuellen Geldbestand abgezogen. Der Geldbestand kann dadurch nicht unter `0$` fallen.
- Doris (Oldlady)
  - Tooltip: `The sweetest, slowest customer — but get caught and she'll tell the whole neighborhood.`
  - Kaufverhalten: billigste `60%` des aktuell freigeschalteten Sortiments.
  - Suspicion: `5 -> 30 -> 55 -> 75`.
  - Caught-Strafe: aktuelles Produkt geht verloren und die Start-Suspicion des nächsten Kunden steigt um `+20%`. Mehrfaches Erwischtwerden bei Doris stapelt diesen Aufschlag.

### Kaufverhalten über Preis-Perzentile

- Kundentypen kaufen nicht aus festen Produktlisten, sondern aus Preisbereichen des aktuellen Sortiments.
- Das Sortiment wird dafür nach Produktwert sortiert.
- Festpreis-Produkte nutzen `price_cents`.
- Wiegbare Produkte nutzen den erwarteten Stückpreis aus durchschnittlichem generierten Gewicht mal Kilopreis.
- Die Perzentilgrenzen werden immer neu aus dem aktuell freigeschalteten Sortiment berechnet.
- Sortiment-Level-Ups verschieben die Perzentilgrenzen automatisch.
- Die Prozentwerte sind Balancing-Werte und zentral anpassbar.

## Grundstruktur / Runs

- Ein Run besteht aus 8 Geschäftstagen.
- Ein Geschäftstag besteht aus 3 Kunden.
- Ein Kunde hat 10 zufällige Produkte.
- Für den Prototyp ist die Produktanzahl auf 10 gesetzt, aber zentral im Balancing pflegbar.
- Der erste Kunde eines Runs ist immer Jimmy.
- Alle weiteren Kunden werden zufällig aus den vier Kundentypen gezogen.
- Nie zweimal derselbe Kundentyp direkt hintereinander.
- Es gibt aktuell keine vordefinierten Kundenfolgen. Falls sie später wieder gebraucht werden, werden sie als separates Content-System ergänzt.
- Die ersten Kunden bringen bei ehrlichem Spiel knapp nicht genug Geld ein.
- Dadurch lernt der Spieler die Scam-Mechanik.
- Runs und zufällige Kunden werden deterministisch über einen Seed erzeugt.
- Der gleiche Seed soll die gleiche Kundentyp-, Produkt- und Gewichtsfolge erzeugen.
- Der gleiche Seed soll auch die gleiche Gewichtsfolge für Obst erzeugen.

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
  - sichtbare Objekt-Slots
  - Produktpreise
  - Kilopreise für Obst
  - Obst-Gewichtsranges, Rundung, Verteilung und Sprite-Skalierung
  - Produktgewichte für die Kundengenerierung
  - Kundentypen, Kundentyp-Tooltips und Kundentyp-Texturen
  - Preis-Perzentile je Kundentyp
  - Coupon-Kosten
  - Coupon-Rabatte
  - Coupon-Gewichtungsboni
  - Sticker-Multiplikatoren und tägliche Sticker-Refills
  - Sortiment-Level-Up-Kosten
  - Suspicion-Stufen je Kundentyp
  - Chad-Geldstrafe und Doris-Start-Suspicion-Bonus

### Aktuelle Produkt-Werte

- Startsortiment:
  - Apfel: `150-500g`, aktuell `3,00$ / kg`
  - Orange: `150-500g`, aktuell `3,20$ / kg`
  - Banane: `120-500g`, aktuell `2,60$ / kg`
  - Kaugummi: `0,95$`
  - Bonbonrolle: `0,80$`
  - Taschentuecher: `1,40$`
- Sortiment-Level 2:
  - Brown Snackbar: `1,30$`
- Alle Werte sind Balancing-Platzhalter in den Produkt-Resources.

## Kunden-Produktfluss

- Ein Kunde hat intern eine Queue aus 10 Produkten.
- Der Kundentyp bestimmt, aus welchem Preisbereich des aktuellen Sortiments diese Produkte gezogen werden.
- Coupons können die Gewichtung innerhalb dieses Kundentyp-Produktpools verändern.
- Zu Beginn eines Kunden rutschen die ersten 4 Objekte von rechts in die Produktfläche.
- Nur diese 4 Objekte sind gleichzeitig sichtbar.
- Wenn ein Coupon für diesen Kunden aktiv ist, ist der Coupon das erste Objekt und danach folgen die ersten Produkte.
- Wenn ein Produkt nur aufgenommen wird, bleibt sein sichtbarer Slot reserviert.
- Erst wenn ein aktives Objekt verkauft, weggeworfen oder durch Erwischen entfernt wurde, rutscht das nächste Produkt aus der Queue nach.
- Dadurch bleibt das Spielfeld übersichtlich.
- Der Spieler verarbeitet alle 10 Produkte nacheinander.
- Die Reihenfolge innerhalb der sichtbaren Produkt-Slots ist frei wählbar.
- Festpreis-Produkte können:
  - gescannt werden
  - in die Tüte gelegt werden
  - mehrfach gescannt werden
  - in den Müll geworfen werden, falls das Produkt oder Objekt dafür gedacht ist
- Obst kann:
  - auf die Waage gelegt werden
  - beim Ablegen auf der Waage abgerechnet werden
  - mehrfach gewogen werden
  - nach offener Abrechnung in die Tüte gelegt werden
  - in den Müll geworfen werden
- Obst bekommt beim Erstellen der Produktinstanz ein deterministisches zufälliges Gewicht.
- Leichte und realistische Gewichte sind häufig, sehr schwere Früchte selten.
- Die Gewichtsrundung liegt aktuell bei `10g`.
- Die Obst-Spritegröße wird anhand des jeweiligen Gewichts von ca. `1.0x` bis maximal `2.0x` skaliert.
- Jeder erfolgreiche Scan oder jede erfolgreiche Wiegung erhöht den offenen Verkaufsbetrag des betroffenen Produkts.
- Der offene Verkaufsbetrag wird erst beim Ablegen in der Tüte zum Total-Wert gebucht.

## Suspicion-System

- Jeder Kunde hat ein internes Suspicion-Meter.
- Das Suspicion-Meter ist die Wahrscheinlichkeit, beim Betrügen erwischt zu werden.
- Die Start-Suspicion und alle Steigerungsstufen kommen aus dem aktuellen Kundentyp.
- Ein Caught-Roll passiert bei jedem Produkt-Scan ab dem zweiten Scan desselben Produkts und bei jeder Wiegung ab der zweiten Wiegung desselben Obstes.
- Der erste Scan oder die erste Wiegung eines Produkts ist immer sicher.
- Coupon-Scam löst keinen Caught-Roll aus.
- Wenn ein Mehrfachscan nicht erwischt wird, steigt die Suspicion danach an.
- Jimmy steigt über `0 -> 20 -> 45 -> 70`.
- Margaret steigt über `10 -> 50 -> 75 -> 90`.
- Chad steigt über `30 -> 65 -> 85 -> 95`.
- Doris steigt über `5 -> 30 -> 55 -> 75`.
- Nach der letzten Stufe bleibt die Suspicion beim letzten Wert des Kundentyps.
- Mehrfachscans sind unbegrenzt möglich, bis der Spieler erwischt wird oder das Produkt verkauft.
- Neuer Kunde = neues Suspicion-Meter mit Startwert des Kundentyps.
- Doris kann durch Caught einen `+20%` Start-Suspicion-Bonus für den nächsten Kunden stapeln.
- Dieser Bonus wird beim nächsten Kunden auf dessen Kundentyp-Startwert addiert und bei `100%` gecappt.
- Die aktuelle Suspicion wird ausschließlich über den grün/gelb/roten Sprite-Zustand des Kundensignals angezeigt.
- Es gibt keine zusätzliche Suspicion-Zahl und keine Progressbar.

## Erwischen / Strafe

- Wird man erwischt, erscheint eine Textbox:

`Kunde: Hey, do you want to scam me? I want compensation!`

- Die Textbox muss mit Enter weggeklickt werden.
- Die Wirkung:
  - Das aktuelle Produkt verschwindet visuell.
  - Der offene Verkaufsbetrag im Kassendisplay wird gelöscht.
  - Es wird kein Geld vom offenen Produktbetrag gebucht.
  - Jeder Kundentyp verliert immer mindestens das aktuelle Produkt.
  - Jimmy und Margaret haben keine weitere Strafe.
  - Chad zieht zusätzlich einmal den Produktwert vom aktuellen Geldbestand ab. Der Geldbestand ist bei `0$` gecappt.
  - Doris erhöht zusätzlich die Start-Suspicion des nächsten Kunden um `+20%`. Dieser Aufschlag stapelt, wenn Doris mehrfach erwischt.
- Danach geht der Kunde weiter normal.

## Tagesende

- Zwischen Geschäftstagen, also immer nach 3 Kunden, wird die Miete bezahlt.
- Kann man die Miete nicht zahlen, verliert man sofort.
- Eine spätere Schuldenmechanik ist möglich, aber out of scope für den Prototyp.
- Aktive Tages-Coupons laufen am Tagesende aus.
- Bio-Sticker werden zu Beginn jedes neuen Tages wieder auf `3` aufgefüllt.

## Upgrades

- In der rechten Menüleiste gibt es temporäre und permanente Upgrades:
  - Coupons
  - Sortiment-Level-Up
  - Sticker

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

- Wenn ein Kunde Produkte kauft, die durch einen Coupon beeinflusst wurden, kommt der passende Coupon mit auf die Produktfläche.
- Der Coupon ist ein Extra-Objekt und zählt nicht zu den 10 Produkten des Kunden.
- Der Coupon wird immer als erstes sichtbares Objekt auf die Produktfläche gelegt.
- Er belegt einen sichtbaren Objekt-Slot, reduziert aber nicht die interne Produktanzahl des Kunden.
- Der Spieler kann den Coupon ehrlich scannen.
- Dann wird der Rabatt für alle danach gescannten oder gewogenen passenden Produkte dieses Kunden angewendet.
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

## Sticker

- Der Sticker-Button im rechten Menüpanel öffnet ein kleines Popup am rechten UI-Bereich.
- Das Popup blockiert den mittleren Spielbereich nicht.
- Der Spieler hat pro Tag `3x Bio-Sticker`.
- Die Sticker werden als einzelne physische Sticker im Popup angezeigt.
- Jeder Bio-Sticker kann aus dem Popup heraus per Drag-&-Drop auf Obst gezogen werden.
- Bio-Sticker können nicht auf Festpreis-Produkte, Coupons, Müll, Scanner, Tüte oder leere Fläche geklebt werden.
- Nach dem Aufkleben ist der Sticker verbraucht und kann nicht entfernt werden.
- Der Sticker ist sichtbar auf dem Obst und bewegt sich mit dem Produkt.
- Tooltip: `Verdreifacht den Preis von Obst`
- Der Bio-Sticker multipliziert Obst-Abrechnungen mit `x3`.
- Liegt das beklebte Obst beim Aufkleben auf der Waage, wird der offene Betrag auf der Kasse sofort mit dem Stickerwert aktualisiert.
- Bei Obst außerhalb der Waage wirkt der Sticker auf spätere Wiegungen.
- Verbrauchte Sticker bleiben bis zum Tagesende verbraucht.

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

- Für den aktuellen Asset-Stand gibt es im Startsortiment:
  - Apfel
  - Orange
  - Banane
  - Kaugummi
  - Bonbonrolle
  - Taschentuecher
- Das Sortiment kann vorerst genau einmal erweitert werden.
- Die erste Erweiterung fügt hinzu:
  - Brown Snackbar

## Mögliche spätere Produktlinien

Out of scope für den Prototyp:

- Bürobedarf
- Hygieneartikel
- Kühlware
- Luxusartikel

## Core-Gameplay-Loop

- Kunde startet.
- Der Kundentyp wird rechts oben über der Produktfläche sichtbar.
- Beim ersten Kunden eines Runs ist der Kundentyp immer Jimmy.
- Die ersten 4 Objekte rutschen von rechts in die verstreute Produktfläche.
- Falls für diesen Kunden ein Coupon aktiv ist, liegt er zuerst in der Produktfläche.
- Der Spieler nimmt ein Produkt von der Produktfläche.
- Festpreis-Produkte werden von rechts nach links über den vertikalen Scannerstrahl gezogen.
- Ein gültiger Scan löst aus:
  - Beep
  - Verkaufsbetrag im Kassendisplay erhöht sich
  - Scanner-Feedback
- Obst wird auf die Waage gelegt, direkt abgerechnet und danach in die Tüte gelegt.
- Danach kann der Spieler das Festpreis-Produkt nochmal scannen oder Obst erneut wiegen.
- Beim Ablegen in die Tüte wird der offene Verkaufsbetrag zum Total-Wert gebucht.
- Beim Ablegen in die Tüte spielt die Coin-Animation an der Tüte.
- Wenn eines der 4 aktiven Objekte in der Tüte, im Müll oder durch Erwischen verschwunden ist, rutscht das nächste Produkt von rechts nach.
- Der Spieler verarbeitet alle 10 Produkte des Kunden.
- Festpreis-Produkte können mehrfach gescannt werden.
- Obst kann mehrfach gewogen werden.
- Mehrfaches Scannen oder mehrfaches Wiegen erhöht die Suspicion.
- Die Suspicion wird über den Sprite-Zustand des Kundensignals angezeigt.
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
  - das Produkt Obst bzw. ein wiegbares Produkt ist
- Dadurch wird der Scan-Moment klarer und absichtlicher.
- Der erste erfolgreiche Scan eines Produkts zeigt den offenen Verkaufsbetrag im Kassendisplay.
- Jeder weitere erfolgreiche Scan desselben gehaltenen Produkts erhöht diesen offenen Verkaufsbetrag erneut um den Produktwert.
- Bei Mehrfachscans wird vor dem erfolgreichen Hinzufügen ein Caught-Roll gegen die aktuelle Suspicion ausgeführt.

## Drag-&-Drop-Regeln

- Produkt wird angeklickt oder gedrückt gehalten.
- Dadurch haftet es am Cursor.
- Während des Drags kann es über den Scanner gezogen werden.
- Danach kann es abgelegt werden:
  - in der Tüte
  - im Müll-Loch
  - auf der Waage, wenn es Obst ist
  - optional zurück auf dem Tisch, falls nötig
- Beim Ablegen in der Tüte gilt das Produkt als verkauft und verarbeitet.
- Obst ohne offenen Verkaufsbetrag wird von der Tüte abgelehnt.
- Der offene Verkaufsbetrag wird erst in diesem Moment zum Total-Wert gebucht.
- Beim Ablegen im Müll-Loch verschwindet das Produkt oder der Coupon.
- Produkte in der Tüte können nicht erneut aufgenommen werden.
- Sticker werden aus dem Sticker-Popup gezogen und können nur auf Obst gedroppt werden.

## Juice-Fokus

- Das Scannen der Produkte ist der wichtigste Kern des Spiels.
- Scannen muss sich extrem satisfying anfühlen.
- Der Spieler soll auch nach 200 Produkten noch Lust auf den nächsten Scan haben.

### Scan-Juice

- Angenehmer Beep-SFX
- Pitch-Eskalation bei Double-, Triple- und Multi-Scans
- Offener Verkaufsbetrag sitzt gut lesbar im Kassendisplay
- Geld zählt links in der Menüleiste animiert hoch, wenn das Produkt in die Tüte gelegt wird
- Kurzer Screen Shake bei Double Scans
- Visuelles Feedback am Scanner
- Kurzes Aufleuchten des vertikalen Scannerstrahls
- Kleine Partikel entlang des Scannerstrahls
- Produkt wobbelt oder squasht kurz beim erfolgreichen Scan

### Produktflächen-Juice

- Neue Produkte fahren weich von rechts rein.
- Die Produkte liegen leicht verstreut statt in einer perfekten Reihe.
- Wenn ein aktives Objekt verarbeitet wurde, rückt das nächste Produkt nach.
- Die Bewegung soll weich und satisfying wirken.
- Nicht zu realistisch, eher abstrakt und toy-like.

### Suspicion-Juice

- Das Kundensignal wechselt zwischen grünem, gelbem und rotem Sprite des aktiven Kundentyps.
- Bei steigender Suspicion kann das Kundensignal kurz pulsieren.
- Bei hoher Suspicion kann das Kundensignal minimal unruhig wirken.
- Kein komplexes Animationssystem nötig.
- Kleine visuelle Andeutungen reichen.

## Prototyp-Fokus

Für den ersten spielbaren Prototyp ist wichtig:

- 1 Screen
- Linke Statusleiste
- Mittlerer Kassentisch
- Rechte Upgrade-Leiste
- Verstreute Produktfläche rechts neben Scanner
- Maximal 4 sichtbare aktive Objekte
- 10 Produkte pro Kunde
- Scanner im Tisch-Sprite, vorerst mittig, mit vertikalem Strahl
- Scannen nur von rechts nach links
- Obst ist wiegbar und nicht scanbar
- Waage im Tischbereich
- Tüte über dem Scanner
- Müll-Loch rechts unten
- Kundensignal rechts oben mit vier Kundentypen und je drei Suspicion-Sprites
- Offener Verkaufsbetrag im Kassendisplay
- Coin-Animation beim Ablegen in die Tüte
- Geld zählt beim Ablegen in der Tüte direkt hoch
- Double-Scan erhöht Suspicion
- Mehrfaches Wiegen erhöht Suspicion wie Mehrfachscans
- Erster Kunde eines Runs ist Jimmy, danach random Kundentypen ohne direkte Wiederholung
- Kundentypen steuern Produkt-Preisbereich, Suspicion-Kurve und Caught-Strafe
- Sticker-Button mit `3x` Bio-Stickern pro Tag
- Miete am Tagesende
- Lose bei nicht bezahlbarer Miete
- Coupon-, Sticker- und Sortiment-Upgrade als einfache Buttons
