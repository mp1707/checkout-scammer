# Product Atlas Import Plan

Phase 1 uses `AtlasTexture` subresources in product variant `.tres` files so the
starting content can be loaded and validated immediately. Normal regions come
from `res://assets/textures/products/black_outline/spritesheet.txt`; highlight
regions use the matching entries from
`res://assets/textures/products/white_outline/spritesheet.txt`.

Before adding larger product batches or changing sprite regions in bulk, build a
generator in `tools/import` that:

- reads `spritesheet.txt`;
- maps stable product IDs to source sprite names;
- writes or updates `ProductVariantResource` files;
- preserves price, weight and assortment values from an editable manifest;
- fails visibly when a requested source sprite is missing.

Current Phase-1 atlas choices:

| Product ID | Source sprite |
| --- | --- |
| `gum` | `outline_black/16x16/Seeds (carrot).png` |
| `chips` | `outline_black/16x16/Grain sack.png` |
| `chocolate_bar` | `outline_black/16x16/Cookie.png` |
| `water` | `outline_black/16x16/Flask Full (blue).png` |
| `soda` | `outline_black/16x16/Flask Full (orange).png` |
| `energy_drink` | `outline_black/16x16/Flask Full (violet).png` |
| `apple` | `outline_black/16x16/Apple (green).png` |
| `banana` | `outline_black/16x16/Banana.png` |
| `orange` | `outline_black/16x16/Orange.png` |
