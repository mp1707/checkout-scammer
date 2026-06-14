extends RefCounted
class_name UiTexts

## Central place for all player-facing strings. Keep the game in one language
## (English) and route new UI copy through constants here so a later
## localization pass only has to touch this file.

const DEFAULT_CUSTOMER_CAUGHT_DIALOG: String = "Customer: That extra charge is not staying on my bill."
const DEFAULT_CUSTOMER_FAREWELL_DIALOG: String = "Customer: Thanks, bye."
const RUN_LOST_DIALOG: String = "Rent is due, but the drawer is short. Shift over."
const RUN_WON_DIALOG_FORMAT: String = "Day %d rent is paid. You win!"
const RECEIPT_CONFIRM_TITLE: String = "Receipt"
const RECEIPT_CONFIRM_BODY: String = "Print the receipt for this customer?"
const RECEIPT_CONFIRM_YES: String = "Yes"
const RECEIPT_CONFIRM_NO: String = "No"
const RECEIPT_TITLE: String = "Receipt"
const RECEIPT_EMPTY_LABEL: String = "No charged items."
const RECEIPT_TOTAL_LABEL: String = "Total"
const RECEIPT_CONTINUE_BUTTON: String = "Continue"

const COUPON_BUTTON_TOOLTIP: String = "Coupons start with the next customer. Bought during the last customer of the day, they start tomorrow."
const STICKER_BUTTON_TOOLTIP: String = "Stickers only apply to fruit. Stock refills every day."

const ASSORTMENT_MAXED_BUTTON_LABEL: String = "Max Stock"
const ASSORTMENT_MAXED_TOOLTIP: String = "All assortment levels are unlocked."
const ASSORTMENT_BUTTON_LABEL_FORMAT: String = "Lvl %d %s"
const ASSORTMENT_EFFECT_TOOLTIP_LINE: String = "Takes effect with the next customer."
const ASSORTMENT_NEW_PRODUCTS_HEADER: String = "New products:"
