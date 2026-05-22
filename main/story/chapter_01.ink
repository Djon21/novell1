// chapter_01.ink
// Root Ink file for iteration 001+. The actual story is split into modular chapters.
// Root must contain INCLUDE only.

INCLUDE chapters/00_bootstrap.ink

// Apartment + системные модули (все дни, все итерации, переключатель времени)
INCLUDE chapters/10_apartment.ink

// Локации x день: один файл = одна локация в один день
INCLUDE chapters/locations/park_sunday.ink
INCLUDE chapters/locations/cafe_sunday.ink
INCLUDE chapters/locations/shop_sunday.ink
INCLUDE chapters/locations/sunday_gift_reactions.ink
INCLUDE chapters/locations/viewpoint_sunday.ink
INCLUDE chapters/locations/bar_sunday.ink

INCLUDE chapters/locations/commute_monday.ink
INCLUDE chapters/locations/office_monday.ink

INCLUDE chapters/locations/office_tuesday.ink
INCLUDE chapters/locations/archive_tuesday.ink
INCLUDE chapters/locations/rooftop_tuesday.ink

// Сервисные модули
INCLUDE chapters/91_inventory_actions.ink
INCLUDE chapters/92_phone_sms.ink
INCLUDE chapters/93_phone_messenger.ink
INCLUDE chapters/94_phone_mail.ink
