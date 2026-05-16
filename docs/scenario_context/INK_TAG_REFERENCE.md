# Ink Tag Reference For GPT

Этот файл - короткий справочник тегов для авторинга Ink. Его можно загружать в GPT вместо `main/scripts/dialogue_manager_ink.lua`, если задача только написать или проверить сценарий.

Source of truth в коде: `main/scripts/dialogue_manager_ink.lua`, функция `apply_tags`.

Если нужно изменить поведение тегов или добавить новый тег, тогда уже нужен сам Lua-файл. Для обычного написания сцен достаточно этого справочника.

## Фон, говорящий, эффекты

| Тег | Пример | Что делает |
|---|---|---|
| `bg:NAME` | `# bg:bg_apartment_bedroom_morning` | Меняет фон диалога. `bg:none` или пустое значение убирает фон. |
| `color:R,G,B` | `# color:0.1,0.1,0.15` | Меняет цвет подложки, значения 0..1. |
| `speaker:ID` | `# speaker:mc` | Меняет говорящего. `mc` и `npc` подставляют текущие имена, `none` очищает говорящего. |
| `sfx:NAME` | `# sfx:phone_notify` | Одноразовый звук. |
| `shake:I,D` | `# shake:0.2,0.5` | Тряска экрана: сила и длительность. |
| `pulse:D,R,G,B` | `# pulse:0.8,0,255,0` | Цветовая вспышка, RGB 0..255. |

## Флаги, предметы, квесты

| Тег | Пример | Что делает |
|---|---|---|
| `set_flag:NAME=VALUE` | `# set_flag:coffee_drunk=true` | Ставит game_state flag. Значения `true`, `false`, числа и строки поддерживаются. |
| `flag:NAME=VALUE` | `# flag:coffee_drunk=true` | Legacy alias для `set_flag`. Для нового текста лучше `set_flag`. |
| `add_item:ID` | `# add_item:phone` | Добавляет предмет. |
| `remove_item:ID` | `# remove_item:mug` | Убирает предмет. |
| `item:add:ID` | `# item:add:phone` | Legacy alias для добавления предмета. |
| `item:remove:ID` | `# item:remove:mug` | Legacy alias для удаления предмета. |
| `quest:start:ID` | `# quest:start:make_coffee` | Ставит квест в `active`. |
| `quest:done:ID` | `# quest:done:make_coffee` | Ставит квест в `done`. |
| `quest:fail:ID` | `# quest:fail:reply_npc` | Ставит квест в `failed`. |
| `quest:ID=STATUS` | `# quest:make_coffee=done` | Прямо задаёт статус квеста. |

`quest:complete` не поддерживается.

## SMS и мессенджер

| Тег | Пример | Что делает |
|---|---|---|
| `sms:add:CONTACT:TEXT` | `# sms:add:mila:Есть планы?` | Добавляет входящее SMS. |
| `sms:reply:CONTACT:TEXT` | `# sms:reply:mila:Хорошо.` | Добавляет исходящее SMS от героя и ставит авто-флаг ответа. |
| `sms:read:CONTACT` | `# sms:read:mila` | Помечает SMS-чат прочитанным. |
| `msg:add:CHAT:TEXT` | `# msg:add:mila:Привет` | Добавляет входящее сообщение в Messenger. |
| `msg:reply:CHAT:TEXT` | `# msg:reply:mila:Ок` | Добавляет исходящее сообщение в Messenger и ставит авто-флаг ответа. |
| `msg:read:CHAT` | `# msg:read:mila` | Помечает Messenger-чат прочитанным. |

Если текст содержит двоеточие, лучше обернуть его в кавычки или проверить результат после сборки.

## Телефонные приложения и данные

| Тег | Пример | Что делает |
|---|---|---|
| `phone:map` | `# phone:map` | Открывает телефон сразу на карте. |
| `phone:app:NAME` | `# phone:app:sms` | Открывает конкретное приложение телефона. |
| `phone:close` | `# phone:close` | Закрывает phone overlay. Использовать только в специальных случаях. |
| `note:add:TITLE:BODY` | `# note:add:Кейс:не хватает данных` | Добавляет заметку. |
| `mail:add:FROM:SUBJECT` | `# mail:add:system:Кейс 017` | Добавляет письмо без отдельного тела. |
| `mail:add:FROM:SUBJECT:BODY` | `# mail:add:system:Кейс 017:Текст` | Добавляет письмо с телом. |
| `mail:read` | `# mail:read` | Помечает всю почту прочитанной. |
| `mail:read:INDEX` | `# mail:read:1` | Помечает одно письмо прочитанным. `1` - самое свежее. |
| `call:in:WHO` | `# call:in:mila` | Входящий звонок. |
| `call:out:WHO` | `# call:out:mila` | Исходящий звонок. |
| `call:missed:WHO` | `# call:missed:mila` | Пропущенный звонок. |
| `call:seen` | `# call:seen` | Сбрасывает счётчик пропущенных. |
| `clue:add:ID:LABEL` | `# clue:add:repeat:Повтор сигнала` | Добавляет улику. |

## Терминал

| Тег | Пример | Что делает |
|---|---|---|
| `term:ok:TEXT` | `# term:ok:Готово` | Добавляет строку уровня `ok`. |
| `term:warn:TEXT` | `# term:warn:Нет поля` | Добавляет предупреждение. |
| `term:err:TEXT` | `# term:err:Ошибка` | Добавляет ошибку. |
| `term:info:TEXT` | `# term:info:Запрос принят` | Добавляет информационную строку. |
| `term:prompt:TEXT` | `# term:prompt:>` | Добавляет prompt-строку. |
| `term:plain:TEXT` | `# term:plain:...` | Добавляет обычную строку. |
| `term:clear` | `# term:clear` | Очищает терминал. |
| `term:defaults` | `# term:defaults` | Возвращает дефолтный лог терминала. |

## Карта

| Тег | Пример | Что делает |
|---|---|---|
| `map:allow:POI_ID` | `# map:allow:poi_cafe` | Разрешает конкретную точку. |
| `map:allow:reset` | `# map:allow:reset` | Сбрасывает временные ограничения карты. |
| `map:lock_to:POI_ID` | `# map:lock_to:poi_cafe` | Оставляет доступной только одну точку. |
| `map:lock_all` | `# map:lock_all` | Блокирует все точки. |
| `map:lock:all` | `# map:lock:all` | То же, более читаемый вариант. |

Карта живёт **внутри телефона** (`phone_map`). Открывается через `# phone:map` или через тап иконки карты в phone-launcher'е. Standalone-карты больше нет — `# map:hub:` снят, теги выше управляют только доступностью POI на phone-карте.

## Сцены исследования

| Тег | Пример | Что делает |
|---|---|---|
| `explore:SCENE_ID` | `# explore:apartment_bedroom` | Передаёт управление exploration scene. |
| `goto_scene:SCENE_ID` | `# goto_scene:apartment_bedroom` | Alias для `explore`. |
| `return_to_scene` | `# return_to_scene` | Возвращает в последнюю exploration scene. Обычно ставится в конце side-knot. |

Если `return_to_scene`, `explore`, `goto_scene`, `phone:*` или `adv:*` стоят после последнего текста, они выполняются после того, как игрок дочитает параграф.

## Scene characters (full-figure на фоне)

«Сценные персонажи» — спрайты-фигуры на фоне exploration-сцены
(в стиле Persona 5), не путать с диалоговыми портретами в `dialogue_v2`.
Конфиг — `main/scripts/scene_characters.lua` (`SCENE_GROUPS` + `SCENES`).
Реальный список доступных групп/персонажей — в `PROJECT_INVENTORY.md`
секция **Scene Characters**.

| Тег | Пример | Что делает |
|---|---|---|
| `scene_char:show:GROUP:KEY` | `# scene_char:show:park:mila_idle` | Показать персонажа `KEY` в группе `GROUP`. |
| `scene_char:hide:GROUP:KEY` | `# scene_char:hide:park:mila_idle` | Спрятать конкретного персонажа. |
| `scene_char:hide_all` | `# scene_char:hide_all` | Спрятать всех персонажей текущей группы. |

Auto-hide при смене группы сцен — встроенное поведение. При переходе
между sub-сценами одной группы (например `park_hub` → `park_riverside_bench`,
обе в группе `park`) персонажи **остаются**. При выходе из группы (выход
из парка по `leave_park`) — авто-`hide_all`, явный тег не нужен.

Если у scene character есть `action.type = "ink_knot"`, клик по нему
запускает соответствующий knot — это альтернатива хотспоту на области
персонажа. См. `scene_characters.lua` SCENES конфиг и
`docs/guides/HOW_TO_ADD_SCENE_CHARACTERS.md`.

## HUD hints

| Тег | Пример | Что делает |
|---|---|---|
| `hud:hint:phone` | `# hud:hint:phone` | Подсветить/пульсировать кнопку телефона. |
| `hud:hint:bag` | `# hud:hint:bag` | Подсветить/пульсировать кнопку инвентаря. |
| `hud:hint:reset` | `# hud:hint:reset` | Снять подсказки. |
| `hud:hint:phone:off` | `# hud:hint:phone:off` | Снять подсказку телефона, если обработчик поддерживает target `phone:off`. |
| `hud:hint:bag:off` | `# hud:hint:bag:off` | Снять подсказку инвентаря, если обработчик поддерживает target `bag:off`. |

`dialogue_manager_ink.lua` передаёт весь target после `hint:` в команду `hud_hint`. Конкретную поддержку target проверять в UI/message flow, если добавляется новый вариант.

## Реклама

| Тег | Пример | Что делает |
|---|---|---|
| `adv:fullscreen` | `# adv:fullscreen` | Показывает полноэкранную рекламу. |
| `ad:fullscreen` | `# ad:fullscreen` | Alias для fullscreen-рекламы. |
| `adv:interstitial` | `# adv:interstitial` | То же, отправляется как fullscreen. |
| `ad:interstitial` | `# ad:interstitial` | Alias. |
| `adv:rewarded` | `# adv:rewarded` | Показывает rewarded-рекламу без флага награды. |
| `adv:rewarded:FLAG` | `# adv:rewarded:watched_hint_ad` | Показывает rewarded-рекламу и ставит reward flag при успешном просмотре. |
| `ad:rewarded:FLAG` | `# ad:rewarded:watched_hint_ad` | Alias. |

Рекламу лучше ставить в паузах: перед картой, после эпизода, перед сменой локации, а не посреди реплики.

## Meta и концовки

| Тег | Пример | Что делает |
|---|---|---|
| `meta:add:KEY:DELTA` | `# meta:add:loop_awareness:1` | Увеличивает числовое meta-поле. |
| `meta:set:KEY:VALUE` | `# meta:set:loop_awareness:2` | Задаёт meta-поле. |
| `loop:end:false:ID` | `# loop:end:false:ending_a` | Помечает ложную концовку. |
| `loop:end:true` | `# loop:end:true` | Помечает истинную концовку. |

Поддержанные numeric meta keys:

- `iteration_number`
- `completed_iterations`
- `loop_awareness`
- `false_endings_count`

## Типовой side-knot из хотспота

```ink
=== look_at_table ===
# speaker:none
На столе лежит чашка. Кофе давно остыл.

# set_flag:table_seen=true
# return_to_scene
-> DONE
```

## Типовой выход к карте

```ink
=== leave_apartment_to_map ===
# speaker:none
Дверь закрывается слишком тихо.

# map:allow:reset
# phone:map
-> DONE
```

## Типовой сюжетный маршрут только в одну точку

```ink
=== go_to_cafe_only ===
# speaker:none
Сейчас есть только один нормальный вариант.

# map:lock_to:poi_cafe
# phone:map
-> DONE
```

