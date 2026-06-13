extends Resource
class_name GameBalanceResource

@export var start_money_cents: int = 1000
@export var daily_rent_cents: int = 4000
@export var days_per_run: int = 8
@export var customers_per_day: int = 3
@export var products_per_customer: int = 10
@export var visible_object_slots: int = 4
@export var starting_assortment_level: int = 1
## 0 creates a fresh seed for normal runs. Positive values force reproducible runs.
@export var default_run_seed: int = 0
