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
INCLUDE chapters/locations/viewpoint_sunday.ink
INCLUDE chapters/locations/bar_sunday.ink

// Понедельник и вторник пока в legacy-структуре, ждут миграции
INCLUDE chapters/20_monday_home.ink
INCLUDE chapters/21_monday_commute.ink
INCLUDE chapters/22_monday_office.ink

INCLUDE chapters/30_tuesday_home.ink
INCLUDE chapters/31_tuesday_investigation.ink
INCLUDE chapters/32_tuesday_rooftop.ink

// Сервисные модули
INCLUDE chapters/91_inventory_actions.ink
INCLUDE chapters/92_phone_sms.ink
INCLUDE chapters/93_phone_messenger.ink
INCLUDE chapters/94_phone_mail.ink
