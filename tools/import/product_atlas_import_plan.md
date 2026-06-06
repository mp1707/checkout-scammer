# Product Atlas Import Plan

Aktueller Content nutzt `AtlasTexture`-Subresources aus
`res://assets/textures/products/products_sheet.png`. Die Regionen stehen in
`res://assets/textures/products/products_sheet.txt`; alle Sprites sind `32x32`.

Aktuelle Atlas-Reihenfolge von links nach rechts:

| Product ID / Actor | Region |
| --- | --- |
| `apple` | `Rect2(0, 0, 32, 32)` |
| `orange` | `Rect2(32, 0, 32, 32)` |
| `banana` | `Rect2(64, 0, 32, 32)` |
| `brown_snackbar` | `Rect2(96, 0, 32, 32)` |
| CouponActor | `Rect2(128, 0, 32, 32)` |

Wenn spaeter groessere Produktbatches dazukommen, soll ein Import-Tool:

- `products_sheet.txt` lesen;
- stabile Produkt-IDs auf Sprite-Namen mappen;
- `ProductVariantResource`-Dateien schreiben oder aktualisieren;
- Preis, Gewichtung und Sortiment-Level aus einem editierbaren Manifest erhalten;
- sichtbar fehlschlagen, wenn eine gewuenschte Sprite-Region fehlt.
