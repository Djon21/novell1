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
- [ ] **step3**: создать `main/gui/modules/v2_theme.lua` — экспортирует `COLORS` (все цвета палитры как `vmath.vector4`, альфа 1.0 по умолчанию; отдельно варианты с альфой .3/.5/.7 под `_dim/_medium/_soft`), `FONTS` (имена шрифтов из .font файлов), и хелпер `apply(node, role)` где role = "title" | "body" | "mono" | "caveat" | "eyebrow" с настройкой шрифта+цвета+размера.

### Этап 1 — общие атомы

- [ ] **step4**: создать `main/gui/v2_atoms.gui` с nested prefabs: `corner_brackets` (4 угла, 22×22, cyan, opacity 0.4), `hud_top` (верхняя полоса 960×32 с ink_0 фоном + cyan пульсирующий dot + 2 текст-слота слева/справа), `hud_bot` (аналог снизу).
- [ ] **step5**: создать overlay-компонент `main/gui/components_v2/effects.gui` + `.gui_script` — три full-screen box-ноды: grain (использует generated noise texture или просто 50% opacity noise sprite), scan (repeating horizontal lines), vignette (radial gradient). Скрипт принимает `msg` "set_effects" {level:0..1} и "toggle_scan" {on:bool}.

### Этап 2 — экраны (порядок: hud → map → nav → menu → dialog → choice)

- [ ] **step6**: `main/gui/components_v2/hud_v2.gui` + `.gui_script`. Верхняя плашка локации ("ПРИХОЖАЯ · 07:12 · ПЕТЛЯ #017") + правый слот с двумя круглыми кнопками BAG (иконка рюкзака, бейдж с числом) и PHN (иконка телефона, amber, бейдж). Принимает `msg` "set_location" {name, time, loop}, "set_inventory_count" {n}, "set_phone_notif" {n}. Клик BAG → `msg.post(ui_manager_v2, "open_inventory")`. Клик PHN → `msg.post(ui_manager_v2, "open_phone")`.
- [ ] **step7**: `main/gui/components_v2/inventory_v2.gui` + `.gui_script`. Модалка 4×3 grid предметов. Данные из `main/scripts/game_state.lua` (функция `gs.get_items()`). Схема предмета: `{id, name, qty, type:"key|doc|rare", iter, clue, desc, verbs:{"use","inspect","combine","read","give"}}`. При клике на слот — показывает details-панель с description + кнопки verb'ов. Закрытие по кнопке X и по "close_inventory" сообщению.
- [ ] **step8**: `main/gui/components_v2/phone_v2.gui` + `.gui_script`. Модалка: статусбар (время, 4G, 73% батарея), wallpaper с датой, 8 app-плиток (СМС / Звонки / Карта / Улики / День / Почта / Камера / Терминал) 4×2 grid с цветовыми акцентами (cyan/hot/amber/violet). При клике на app → пока только `print("[phone_v2] app: " .. id)` и визуальный highlight. Сообщения "open_phone", "close_phone".
- [ ] **step9**: `main/gui/components_v2/map_v2.gui` + `.gui_script`. Карта Москвы — использовать bg_map атлас (если нет — генерируем quad с plain color и размещаем pin'ы поверх). 7 пинов: home/work/cafe/metro/shop/clue/gov. Поля пина: `{id, name, color, addr, walk, sub, stat, clue, stamp, desc, pos:{x,y}}`. Клик пина → выделение + показ досье справа. Кнопки "route" "save" "share" пока заглушки. Сообщение "open_map" / "close_map".
- [ ] **step10**: `main/gui/components_v2/nav_buttons_v2.gui` + `.gui_script`. 4 круглые кнопки (112×112, переверстаны под ландшафт: left/up/right/down по периметру экрана). Цвет-код: left=hot, up=cyan, right=amber, down=violet. Поля кнопки: `{dir:"W|N|E|S", room_id, room_label, disabled, locked_label}`. Клик → `msg.post(ui_manager_v2, "nav_go", {dir=..., scene_id=...})`. Данные берём из `scenes.lua` (у сцены поле `exits = {W="kitchen", N="stairs", E={locked="найти ключ"}, S="bedroom"}`). Сообщение "show_nav" / "hide_nav" / "set_exits" {exits_table}.
- [ ] **step11**: `main/gui/components_v2/main_menu_v2.gui` + `.gui_script`. 4 пункта (Новая итерация / Продолжить / Галерея / Достижения), логотип "АВОСЬ" с glitch (3 слоя текста, offset -3/+3 по X, clip в верхнюю и нижнюю половины через отдельные маски-ноды), штамп "СЕКРЕТНО · №17", eyebrow "visual · novel · dossier", meta-строка, досье-карточка справа с прогрессом, ticker внизу (зацикленная анимация по X). Скайлайн делаем упрощённо — PNG-спрайт из макета (можно отложить, пока заглушкой-градиентом). Сообщения как в старом menu: "show_menu"/"hide_menu", клики → "start_game"/"continue_game"/"open_gallery"/"open_achievements".
- [ ] **step12**: `main/gui/components_v2/dialogue_v2.gui` + `.gui_script`. Портрет слева (96×96 img или CRT-режим для нарратора — просто зелёный #5aff7a текст на чёрном), nameplate (имя + tag), dbox справа с угловыми brackets, печатная строка (символ-по-символу анимация, скорость из настроек), кнопки skip/auto/next внизу. Принимает от существующего `dialogue_manager_ink` сообщения "render_dialogue" (как старый dialogue_system), парсит speaker через таблицу `CHARS = {mila=..., artem=..., narrator=...}`.
- [ ] **step13**: `main/gui/components_v2/choice_v2.gui` + `.gui_script`. Модалка выбора 2-4 опций. Каждая опция: `{text, cls:""|"key"|"danger", hint, hintCls:"hot|amber|violet"}`. Таймер справа внизу (18 сек countdown, configurable через параметр). Клик опции → `msg.post(ui_manager_v2, "choice_picked", {index})`. Клавиши 1-4 и Esc (последний — "choice_cancelled"). Сообщения "show_choice" {opts, timer_sec}, "hide_choice".

### Этап 3 — ui_manager_v2

- [ ] **step14**: создать `main/gui/ui_manager_v2.script` по образцу старого `ui_manager.script`. Режимы: `menu`, `nav`, `exploration`, `dialogue`, `choice`, `inventory`, `phone`, `map`. Методы show_*() / hide_*(). Интеграция с `scene_controller` (тот же, из main/scripts/) — отдаёт scene_bg в hud_v2 (как локация), пины карты прокидывает в map_v2, выходы сцены → nav_buttons_v2.
- [ ] **step15**: создать `main/main_v2.collection` — содержит только один GO `ui_manager_v2` с `.script` + все 8 `.gui` компонентов (main_menu_v2, hud_v2, inventory_v2, phone_v2, map_v2, nav_buttons_v2, dialogue_v2, choice_v2, effects) + `music_player.go` и другие системные, как в старой main.collection.
- [ ] **step16**: в `game.project` добавить комментарием строку с альтернативой `bootstrap.main_collection = /main/main_v2.collection` (сам значение пока НЕ меняй — пусть пользователь включит вручную).

### Этап 4 — полиш (можно не торопиться)

- [ ] **step17**: glitch-анимация логотипа (gui.animate two сдвинутых узла по X с random интервалом).
- [ ] **step18**: печатный ввод в dialogue_v2 (посимвольная анимация).
- [ ] **step19**: ticker marquee в main_menu (gui.animate по X, бесконечный цикл).
- [ ] **step20**: parallax skyline (если мышь есть — по mousemove, иначе idle-sway).

---

## REVIEW_NEEDED

*(сюда луп пишет пункты, требующие визуальной проверки в Defold Editor)*

---

## История коммитов

*(луп дописывает после каждого коммита: hash, сообщение)*

- step1 — добавлены Unbounded-Bold.ttf + Manrope-Regular.ttf, 8 новых `.font` файлов (jb_mono 10/12/bold_14, unbounded_bold 20/32, manrope 14/16, caveat_18)
- step2 — `main/images/v2/artem.png`, `mila.png`, `bg_bedroom_01.jpg` + `main/images/v2.atlas`
