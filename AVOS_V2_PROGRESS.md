# AVOS V2 — прогресс интеграции нового UI

## Контекст

Интегрируем mobile-макеты из `C:\Users\GoldiM\Downloads\AVOS (14)\` в Defold-игру.
Игра **альбомная 960×640** — верстаем с учётом этого, mobile-макеты переверстываются под ландшафт.
Старый UI в `main/gui/components/` **не трогаем**. Всё новое идёт параллельно в `main/gui/components_v2/`.
Переключение — через `bootstrap.main_collection` в `game.project` (временно можно оставить старую коллекцию, новую добавлять постепенно).

**Рабочая ветка**: `AVOS_C` в репозитории `C:\Users\GoldiM\novell1\AVOS\AVOS_C`.
**Ассеты**: `artem.png`, `mila.png`, `bg_bedroom_01.jpg` лежат в `C:\Users\GoldiM\Downloads\AVOS (14)\assets\`.
**HTML-источники**: `menu_mobile.html`, `hud_mobile.html`, `nav_buttons_mobile.html`, `dialog_mobile.html`, `choice_mobile.html`, `map_mobile.html` — там же.

**Палитра** (CSS → Defold vmath.vector4):
- `--ink-0 #07061a` · `--ink-1 #0c0a24` · `--ink-2 #171232`
- `--paper #f3ecd9` · `--paper-dim #c9c0a8`
- `--accent #7df9ff` (cyan) · `--accent-hot #ff3d7f` (magenta)
- `--amber #ffb347` · `--violet #7a5cff` · `--stamp #c8142a`

**Шрифты**: JetBrains Mono (300/400/500/700), Unbounded (400/600/800/900), Caveat (400/700), Manrope (для длинного текста).

---

## Правила для луп-итераций

1. Читаешь этот файл. Находишь первый пункт с `[ ]`.
2. Выполняешь его ПОЛНОСТЬЮ (код + все нужные файлы).
3. Если что-то непонятно по макетам — читаешь соответствующий `*_mobile.html`.
4. Коммитишь одним коммитом: `git add` → `git commit -m "v2(stepN): описание"` → `git push origin AVOS_C`.
5. Меняешь `[ ]` → `[x]` напротив пункта.
6. Если нужен ручной review — добавляешь в раздел `REVIEW_NEEDED` внизу.
7. Никогда не трогаешь `main/gui/components/` (старый UI), только `main/gui/components_v2/` и `main/gui/v2_*`.
8. Работаешь в `C:\Users\GoldiM\novell1\AVOS\AVOS_C` на ветке `AVOS_C`.

---

## Чеклист

### Этап 0 — фундамент

- [x] **step1**: скопировать шрифты JetBrains Mono / Unbounded / Caveat / Manrope в `main/fonts/` (скачать с Google Fonts если нет) и создать `.font` файлы для каждого начертания, которое реально используется (JBM-Regular/Bold, Unbounded-Bold/Black, Caveat-Regular, Manrope-Regular/Medium). Формат по аналогии с `main/fonts/material_icons.font`.
- [x] **step2**: скопировать ассеты из `C:\Users\GoldiM\Downloads\AVOS (14)\assets\` (`artem.png`, `mila.png`, `bg_bedroom_01.jpg`) в `main/images/v2/` и добавить в атлас `main/atlases/v2.atlas`. *(атлас размещён в `main/images/v2.atlas` а не в `main/atlases/` — консистентно с существующими `backgrounds.atlas`/`characters.atlas`)*
- [x] **step3**: создать `main/gui/modules/v2_theme.lua` — экспортирует `COLORS` (все цвета палитры как `vmath.vector4`, альфа 1.0 по умолчанию; отдельно варианты с альфой .3/.5/.7 под `_dim/_medium/_soft`), `FONTS` (имена шрифтов из .font файлов), и хелпер `apply(node, role)` где role = "title" | "body" | "mono" | "caveat" | "eyebrow" с настройкой шрифта+цвета+размера.

### Этап 1 — общие атомы

- [x] **step4**: создать `main/gui/v2_atoms.gui` с nested prefabs: `corner_brackets` (4 угла, 22×22, cyan, opacity 0.4), `hud_top` (верхняя полоса 960×32 с ink_0 фоном + cyan пульсирующий dot + 2 текст-слота слева/справа), `hud_bot` (аналог снизу). *(в Defold nested prefabs = отдельные `.gui` template-файлы; создано 3 файла в `main/gui/components_v2/atoms/`: corner_brackets.gui, hud_top.gui, hud_bot.gui)*
- [x] **step5**: создать overlay-компонент `main/gui/components_v2/effects.gui` + `.gui_script` — три full-screen box-ноды: grain (использует generated noise texture или просто 50% opacity noise sprite), scan (repeating horizontal lines), vignette (radial gradient). Скрипт принимает `msg` "set_effects" {level:0..1} и "toggle_scan" {on:bool}. *(на старте — plain-color alpha box'ы; позже можно подключить текстуры noise/scan/gradient)*

### Этап 2 — экраны (порядок: hud → map → nav → menu → dialog → choice)

- [x] **step6**: `main/gui/components_v2/hud_v2.gui` + `.gui_script`. Верхняя плашка локации ("ПРИХОЖАЯ · 07:12 · ПЕТЛЯ #017") + правый слот с двумя круглыми кнопками BAG (иконка рюкзака, бейдж с числом) и PHN (иконка телефона, amber, бейдж). Принимает `msg` "set_location" {name, time, loop}, "set_inventory_count" {n}, "set_phone_notif" {n}. Клик BAG → `msg.post(ui_manager_v2, "open_inventory")`. Клик PHN → `msg.post(ui_manager_v2, "open_phone")`.
- [x] **step7**: `main/gui/components_v2/inventory_v2.gui` + `.gui_script`. Модалка 4×3 grid предметов. Данные из `main/scripts/game_state.lua` (функция `gs.get_items()`). Схема предмета: `{id, name, qty, type:"key|doc|rare", iter, clue, desc, verbs:{"use","inspect","combine","read","give"}}`. При клике на слот — показывает details-панель с description + кнопки verb'ов. Закрытие по кнопке X и по "close_inventory" сообщению.
- [x] **step8**: `main/gui/components_v2/phone_v2.gui` + `.gui_script`. Модалка: статусбар (время, 4G, 73% батарея), wallpaper с датой, 8 app-плиток (СМС / Звонки / Карта / Улики / День / Почта / Камера / Терминал) 4×2 grid с цветовыми акцентами (cyan/hot/amber/violet). При клике на app → пока только `print("[phone_v2] app: " .. id)` и визуальный highlight. Сообщения "open_phone", "close_phone".
- [x] **step9**: `main/gui/components_v2/map_v2.gui` + `.gui_script`. Карта Москвы — использовать bg_map атлас (если нет — генерируем quad с plain color и размещаем pin'ы поверх). 7 пинов: home/work/cafe/metro/shop/clue/gov. Поля пина: `{id, name, color, addr, walk, sub, stat, clue, stamp, desc, pos:{x,y}}`. Клик пина → выделение + показ досье справа. Кнопки "route" "save" "share" пока заглушки. Сообщение "open_map" / "close_map".
- [x] **step10**: `main/gui/components_v2/nav_buttons_v2.gui` + `.gui_script`. 4 круглые кнопки (112×112, переверстаны под ландшафт: left/up/right/down по периметру экрана). Цвет-код: left=hot, up=cyan, right=amber, down=violet. Поля кнопки: `{dir:"W|N|E|S", room_id, room_label, disabled, locked_label}`. Клик → `msg.post(ui_manager_v2, "nav_go", {dir=..., scene_id=...})`. Данные берём из `scenes.lua` (у сцены поле `exits = {W="kitchen", N="stairs", E={locked="найти ключ"}, S="bedroom"}`). Сообщение "show_nav" / "hide_nav" / "set_exits" {exits_table}.
- [x] **step11**: `main/gui/components_v2/main_menu_v2.gui` + `.gui_script`. 4 пункта (Новая итерация / Продолжить / Галерея / Достижения), логотип "АВОСЬ" с glitch (3 слоя текста, offset -3/+3 по X, clip в верхнюю и нижнюю половины через отдельные маски-ноды), штамп "СЕКРЕТНО · №17", eyebrow "visual · novel · dossier", meta-строка, досье-карточка справа с прогрессом, ticker внизу (зацикленная анимация по X). Скайлайн делаем упрощённо — PNG-спрайт из макета (можно отложить, пока заглушкой-градиентом). Сообщения как в старом menu: "show_menu"/"hide_menu", клики → "start_game"/"continue_game"/"open_gallery"/"open_achievements".
- [x] **step12**: `main/gui/components_v2/dialogue_v2.gui` + `.gui_script`. Портрет слева (96×96 img или CRT-режим для нарратора — просто зелёный #5aff7a текст на чёрном), nameplate (имя + tag), dbox справа с угловыми brackets, печатная строка (символ-по-символу анимация, скорость из настроек), кнопки skip/auto/next внизу. Принимает от существующего `dialogue_manager_ink` сообщения "render_dialogue" (как старый dialogue_system), парсит speaker через таблицу `CHARS = {mila=..., artem=..., narrator=...}`.
- [x] **step13**: `main/gui/components_v2/choice_v2.gui` + `.gui_script`. Модалка выбора 2-4 опций. Каждая опция: `{text, cls:""|"key"|"danger", hint, hintCls:"hot|amber|violet"}`. Таймер справа внизу (18 сек countdown, configurable через параметр). Клик опции → `msg.post(ui_manager_v2, "choice_picked", {index})`. Клавиши 1-4 и Esc (последний — "choice_cancelled"). Сообщения "show_choice" {opts, timer_sec}, "hide_choice".

### Этап 3 — ui_manager_v2

- [x] **step14**: создать `main/gui/ui_manager_v2.script` по образцу старого `ui_manager.script`. Режимы: `menu`, `nav`, `exploration`, `dialogue`, `choice`, `inventory`, `phone`, `map`. Методы show_*() / hide_*(). Интеграция с `scene_controller` (тот же, из main/scripts/) — отдаёт scene_bg в hud_v2 (как локация), пины карты прокидывает в map_v2, выходы сцены → nav_buttons_v2.
- [x] **step15**: создать `main/main_v2.collection` — содержит только один GO `ui_manager_v2` с `.script` + все 8 `.gui` компонентов (main_menu_v2, hud_v2, inventory_v2, phone_v2, map_v2, nav_buttons_v2, dialogue_v2, choice_v2, effects) + `music_player.go` и другие системные, как в старой main.collection.
- [x] **step16**: в `game.project` добавить комментарием строку с альтернативой `bootstrap.main_collection = /main/main_v2.collection` (сам значение пока НЕ меняй — пусть пользователь включит вручную).

### Этап 4 — полиш (можно не торопиться)

- [x] **step17**: glitch-анимация логотипа (gui.animate two сдвинутых узла по X с random интервалом).
- [ ] **step18**: печатный ввод в dialogue_v2 (посимвольная анимация).
- [ ] **step19**: ticker marquee в main_menu (gui.animate по X, бесконечный цикл).
- [ ] **step20**: parallax skyline (если мышь есть — по mousemove, иначе idle-sway).

---

## REVIEW_NEEDED

*(сюда луп пишет пункты, требующие визуальной проверки в Defold Editor)*

- **step4**: открой `main/gui/components_v2/atoms/` в Defold Editor, визуально проверь что `corner_brackets.gui`, `hud_top.gui`, `hud_bot.gui` рендерятся корректно (углы по периметру 960×640, hud-полосы высотой 32px сверху/снизу с cyan бордером). `script: ""` в textproto обычно валидно (без скрипта), но если Defold требует явного отсутствия — удалить строку руками.
- **step5**: `effects.gui` пока использует plain-color box'ы с alpha (grain белый 7%, scan белый 18% BLEND_MULT, vignette чёрный 55%). Выглядит как затемнение без текстур — для полноценного эффекта нужно подключить PNG текстуры noise/scan/radial_gradient в атлас и заменить TYPE_BOX на текстуру. Пока работает как базовая затенёнка.
- **step17**: glitch-анимация логотипа — случайная вспышка каждые 1.5-4.5s через `timer.delay` с рекурсивным `schedule_next_glitch`, сдвиг hot/cyan по X на ±8-10 с цепочкой `gui.animate position.x` (burst 30ms, возврат 50ms). Базовые позиции зашиты: hot=58, cyan=62, y=498. Если сменишь позиции логотипа в .gui — поправь константы `LOGO_BASE`/`LOGO_Y`. Таймер останавливается в `final()` (при unload компонента). Видимость логотипа не отключает таймер; если меню скрыто (`hide_menu`), glitch всё равно тикает — не критично, но если беспокоит, можно обернуть `glitch_burst` в `if self.visible then ... end` (и так сделано).
- **step16**: `game.project` — добавлены 3 строки-комментария с `#` после `main_collection = /main/main.collectionc`. Значение НЕ изменено. ВАЖНО: Defold Editor при сохранении `game.project` через GUI может удалить комментарии `#` — если хочешь их сохранить, редактируй файл только текстовым редактором. Для переключения на v2: закомментируй строку 2 (`main_collection = /main/main.collectionc`) добавив `#` перед ней, и раскомментируй строку 5.
- **step15**: `main/main_v2.collection` — 3 embedded GO: `ui_manager_v2` (script + 9 .gui компонентов), `music_player`, `sfx_player`. Порядок компонентов в одной GO определяет z-order рендеринга — сейчас: ui_manager_v2 → main_menu_v2 → hud_v2 → nav_buttons_v2 → dialogue_v2 → choice_v2 → inventory_v2 → phone_v2 → map_v2 → effects. Если visually overlay накладывается не тот — меняй порядок. В `.gui` у каждого компонента z задаёт свой слой (0.4-0.7), это тоже поможет. Collection пока НЕ подключена через bootstrap — это делается в step16 (комментарий) или пользователем вручную.
- **step14**: ui_manager_v2.script — базовый режим (menu/nav/exploration/dialogue) + оверлеи (choice/inventory/phone/map, могут быть поверх exploration/dialogue). Использует `dm.current_line()`, `dm.current_choices()`, `dm.advance()`, `dm.pick_choice()` — проверь, что в `dialogue_manager_ink.lua` эти методы существуют (если нет — добавь тонкий адаптер). Hotspots НЕ прокидываются (v2 хотспоты встроены в сцену — `set_scene_object`/`set_hotspot` остались no-op). `current_scene_exits()` читает `scenes[id].exits` через require scenes — если у scene_controller метод не `current_scene_id`, переименуй. ESC закрывает первый открытый оверлей. Музыка стартует при первом touch, как в старом ui_manager. Компоненты подключаются как `#main_menu_v2`, `#hud_v2`, `#nav_buttons_v2`, `#dialogue_v2`, `#choice_v2`, `#inventory_v2`, `#phone_v2`, `#map_v2`, `#effects` — все должны быть в одном GO (step15 main_v2.collection).
- **step13**: choice_v2 — модалка 680×420 с backdrop, поддерживает 2-4 опции (лимит 4 в on_message). Опции создаются динамически как дети `opts_panel` (bg + border + label + опционально hint) стек сверху вниз 60px высотой с 12px gap. Стили опций: `cls=""` (normal, ink bg + cyan border 35%), `cls="key"` (ink bg + cyan border 80%), `cls="danger"` (dark red bg + hot border). Hint-строка раскрашивается `hintCls`: hot/amber/violet/default=cyan. Таймер countdown читает `timer_sec` из "show_choice" (по умолчанию 18), update(dt) декрементит time_left, при ≤0 шлёт "choice_timeout"; цвет timer_num/fill переключается accent→amber (<60%)→hot (<30%). Если `timer_sec ≤ 0` — элементы таймера скрываются. Клик по opt.bg → "choice_picked" {index}. Клавиши 1-4/Esc НЕ реализованы (только тач), если нужно — добавить в on_input. Проверь в Defold Editor, что `update(self, dt)` тикает в gui_script (обычно да, когда компонент enabled).
- **step12**: dialogue_v2 — портрет пока icon-плашка (emoji-face `\uEE9F BB`), не спрайт; подключение реальных артов `artem.png`/`mila.png` из `v2.atlas` — отдельная работа (нужна текстура на portrait_bg и удалить portrait_icon). Угловые brackets нарисованы 4-мя BOX-нодами (2 H + 2 V) только для TL/TR — нижние углы не обозначены; если нужно симметрично — добавить BL/BR. Typewriter-эффект (step18) пока не реализован — текст появляется сразу целиком. Clicking dbox также триггерит "dialogue_next" — если это мешает, добавить зону-исключение для кнопок. CHARS расширяется в код под новых персонажей (колл-центр, звонящий и т.д.).
- **step11**: main_menu_v2 — логотип сделан из 3 статических слоёв `logo_hot` (сдвиг -2px, hot alpha 35%), `logo_cyan` (сдвиг +2px, cyan alpha 35%), `logo_main` (белый paper). Glitch-анимация (случайные сдвиги `logo_hot`/`logo_cyan` по X) — отдельный шаг step17. Ticker-текст 2400px, стоит статично; marquee по X — step19. Caveat-фраза разбита на 2 строки вручную, т.к. `line_break: true` + caveat_18 может переносить странно — проверь визуально, подправь ширину/позиции при необходимости. Пункты меню — просто текстовые ноды, кликабельная зона равна размеру ноды (pivot PIVOT_W, size 400×28) — если хитбокс промахивается, увеличить size или добавить невидимые BOX-ноды для клика.
- **step10**: nav_buttons_v2 пытается `require "main.scripts.scenes"` через `pcall` для room_label по scene_id; если модуль недоступен или у сцены нет поля `name`/`label` — используется room_id в uppercase. Проверь в Defold Editor, что иконки-chevron `\uE5C4/\uE5D8/\uE5C8/\uE5DB` рендерятся в шрифте `icons.font` (Material Icons). PIE-ноды 112×112 с `PIECE_BOUNDS_ELLIPSE` — круглые кнопки. В .gui кнопки по умолчанию видны, но в init все 4 скрываются; ui_manager_v2 должен прислать "set_exits" при входе в сцену. Формат exits поддерживает и строку-id, и table с locked_label (для закрытых дверей).
- **step9**: map_v2 — фон map_area залит плоским цветом (ink_1 со слабым cyan-бордером сверху/снизу), без SVG-«реки»/квадалов/дорог из HTML-макета. Если нужна настоящая карта — можно подложить спрайт в атлас `v2.atlas` и заменить TYPE_BOX на TYPE_BOX с текстурой. Пины рендерятся как квадраты 32×32 — в макете они круглые, но круглые требуют TYPE_PIE (или png-спрайт); можно переделать на `TYPE_PIE` с `outer_bounds: PIECE_BOUNDS_ELLIPSE` позже. Кодпойнты Material Icons для пинов (home/business/coffee/subway/store/star/account_balance) взяты примерно — проверь, что глифы рендерятся в шрифте `icons.font`. Пин координаты в POINTS нормализованы 0..1 относительно map_area (560×480); y=0 — низ (PIVOT_SW), y=1 — верх. Изначально выбран "home".
- **step8**: phone_v2 — `phone_mobile.html` отсутствует в `Downloads/AVOS (14)/`, дизайн сделан по спецификации step8 (вертикальная рамка 280×560 по центру ландшафта, status bar cyan + wallpaper + 4×2 tiles). Кодпойнты Material Icons для приложений (chat_bubble/call/map/search_insights/today/mail/camera_alt/terminal) могут не совпасть с реальным атласом — проверь визуально и поменяй в массиве APPS в phone_v2.gui_script. Плитка "day" использует E8DF (today), "clues" — F435 (search_insights) — если глифа нет, подмени. `flash_tile` использует `timer.delay` — убедись, что `timer` доступен в gui_script (обычно да). Сообщение `phone_app_clicked` {id} летит в несуществующий ui_manager_v2 — это нормально до step14.
- **step7**: inventory_v2 читает реальный инвентарь через `gs.get_inventory()` — проверь, что items_catalog содержит id'шники, которые game_state реально может вернуть (схема: mug/phone/key/cup/note/card/usb/cig/cash). Слоты и verb-кнопки создаются в `init()` через `gui.new_*_node` как дети нод `grid`/`verbs_panel` — убедись в Defold Editor, что `max_nodes: 512` хватает (12 слотов × 4 ноды + 5 кнопок × 3 ноды ≈ 63 доп. ноды, укладываемся). Verb-сообщение `inventory_verb` {item_id, verb} шлётся в несуществующий пока `ui_manager_v2` — это нормально до step14.
- **step6**: иконки BAG/PHN используют кодпойнты Material Icons `\uE533` (inventory_2) и `\uE32C` (smartphone). Если глифы не отрендерятся — заменить на другие из Material Icons codepoints. Координата `main:/ui_manager_v2#ui_manager_v2` в const `UI_MGR` — на этом этапе ui_manager_v2 ещё не создан (step14), сообщения `open_inventory`/`open_phone` пока будут лететь в пустоту. Это ОК, позже заработает.

---

## История коммитов

*(луп дописывает после каждого коммита: hash, сообщение)*

- step1 — добавлены Unbounded-Bold.ttf + Manrope-Regular.ttf, 8 новых `.font` файлов (jb_mono 10/12/bold_14, unbounded_bold 20/32, manrope 14/16, caveat_18)
- step2 — `main/images/v2/artem.png`, `mila.png`, `bg_bedroom_01.jpg` + `main/images/v2.atlas`
- step3 — `main/gui/modules/v2_theme.lua` (COLORS, FONTS, ROLES, LAYOUT, ANIM, apply helper)
- step4 — 3 атома-шаблона: `components_v2/atoms/corner_brackets.gui`, `hud_top.gui`, `hud_bot.gui`
- step5 — `components_v2/effects.gui` + `.gui_script` (grain/scan/vignette, msg set_effects/toggle_scan/show_effects/hide_effects)
- step6 — `components_v2/hud_v2.gui` + `.gui_script` (заголовок локации + BAG/PHN pie-кнопки с бейджами; шлёт open_inventory/open_phone в ui_manager_v2)
- step7 — `components_v2/inventory_v2.gui` + `.gui_script` (4×3 сетка, details-панель справа, кнопки-глаголы; слоты и глаголы создаются динамически через gui.new_box_node/new_text_node; читает items_catalog + gs.get_inventory)
- step8 — `components_v2/phone_v2.gui` + `.gui_script` (вертикальная рамка 280×560 по центру, status bar + wallpaper + 4×2 сетка приложений с цветовыми акцентами cyan/hot/amber/violet; клик по app шлёт "phone_app_clicked" в ui_manager_v2)
- step9 — `components_v2/map_v2.gui` + `.gui_script` (map_area 560×480 слева + dossier-панель 310×480 справа; 7 пинов home/work/cafe/metro/shop/clue/gov с нормализованными координатами, динамически создаются в init; по клику пина — обновление dossier + лог; 3 кнопки-глагола route/save/share; шлёт close_map/map_verb в ui_manager_v2)
- step10 — `components_v2/nav_buttons_v2.gui` + `.gui_script` (4 круглые pie-кнопки 112×112 по периметру ландшафта W/N/E/S с цветами hot/cyan/amber/violet, иконки chevron_left/expand_less/chevron_right/expand_more, подписи room_label; `set_exits` принимает table {W=..., N=..., E=..., S=...}, значение = scene_id / table {room_id, room_label, disabled, locked_label} / nil; клик → "nav_go" {dir, scene_id} в ui_manager_v2; locked-состояние показывает серую подпись)
- step11 — `components_v2/main_menu_v2.gui` + `.gui_script` (логотип АВОСЬ в 3 слоя под glitch (step17), 4 пункта меню НОВАЯ ИТЕРАЦИЯ/ПРОДОЛЖИТЬ/ГАЛЕРЕЯ/ДОСТИЖЕНИЯ, штамп СЕКРЕТНО, досье-карточка справа с прогрессом и caveat-хинтом, ticker снизу; клик пункта → start_game/continue_game/open_gallery/open_achievements в ui_manager_v2)
- step12 — `components_v2/dialogue_v2.gui` + `.gui_script` (dbox 920×200 внизу + portrait 96×96 + nameplate (имя + tag) + текст manrope_16 с line_break + угловые brackets; кнопки SKIP/AUTO/NEXT; таблица CHARS {mila,artem,narrator} для цвета nameplate и CRT-зелёного для нарратора; принимает "render_dialogue" {speaker,name,text,tag} совместимо с dialogue_manager_ink; шлёт dialogue_next/dialogue_skip/dialogue_auto в ui_manager_v2)
- step13 — `components_v2/choice_v2.gui` + `.gui_script` (модалка 680×420 с backdrop, title_eyebrow + title_main, 2-4 опции динамически в opts_panel 640×300 с cls=""/key/danger и hint-строкой hintCls=hot/amber/violet, countdown-таймер 18s с цветовым индикатором accent→amber→hot, "show_choice" {opts,timer_sec,title}, "hide_choice"; шлёт choice_picked/choice_timeout в ui_manager_v2)
- step14 — `main/gui/ui_manager_v2.script` (оркестратор 8 v2-компонентов: menu/nav/exploration/dialogue base modes + choice/inventory/phone/map overlays; dm/gs/scene_controller интеграция; ESC закрывает оверлеи; музыка при первом touch; `nav_go` вызывает scene_controller.enter_scene + обновляет выходы)
- step15 — `main/main_v2.collection` (embedded GO: ui_manager_v2 + 9 .gui компонентов + music_player + sfx_player; старая main.collection не затронута)
- step16 — `game.project` (комментарий с альтернативным bootstrap на `/main/main_v2.collectionc`; значение не менялось)
- step17 — glitch-анимация logo_hot/logo_cyan в main_menu_v2 (timer.delay 1.5-4.5s + gui.animate position.x ±8-10px)
