extends Resource
class_name ScriptedCustomerResource

## Fixed product order for a specific customer, used to script the early game.
## Only applies while the run is still at `required_assortment_level`; once the
## player upgrades, the generator falls back to weighted random products.

@export var id: String = ""
@export var day: int = 1
@export var customer_number: int = 1
@export var required_assortment_level: int = 1
@export var products: Array[ProductVariantResource] = []
