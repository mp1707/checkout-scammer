extends RefCounted
class_name UiTexts

## Central place for all player-facing strings. Keep the game in one language
## (English) and route new UI copy through constants here so a later
## localization pass only has to touch this file.

const CUSTOMER_CAUGHT_DIALOG: String = "Customer: Hey, do you want to scam me? I want compensation!"
const CUSTOMER_BYE_DIALOG: String = "Thanks, byyyyyeeeeee"
const RUN_LOST_DIALOG: String = "Rent is due, but the drawer is short. Shift over."
const RUN_WON_DIALOG_FORMAT: String = "Day %d rent is paid. You win!"

const COUPON_BUTTON_TOOLTIP: String = "Coupons start with the next customer. Bought during the last customer of the day, they start tomorrow."
const STICKER_BUTTON_TOOLTIP: String = "Stickers only apply to fruit. Stock refills every day."

const ASSORTMENT_MAXED_BUTTON_LABEL: String = "Max Stock"
const ASSORTMENT_MAXED_TOOLTIP: String = "All assortment levels are unlocked."
const ASSORTMENT_BUTTON_LABEL_FORMAT: String = "Lvl %d %s"
const ASSORTMENT_EFFECT_TOOLTIP_LINE: String = "Takes effect with the next customer."
const ASSORTMENT_NEW_PRODUCTS_HEADER: String = "New products:"
