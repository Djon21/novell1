# Как писать ink-файлы для AVOS — полная шпаргалка

> Этот файл отвечает на вопрос: «Я хочу написать ink-knot — что именно нужно написать и в каком порядке?»
> Все грабли описаны в разделе **Типичные ошибки**.

---

## Содержание

1. [Структура одного knot'а — шаблон](#1-структура-одного-knota--шаблон)
2. [Все поддерживаемые теги — полная таблица](#2-все-поддерживаемые-теги--полная-таблица)
3. [Двойная система переменных](#3-двойная-система-переменных)
4. [Как knot связан со сценой](#4-как-knot-связан-со-сценой)
5. [Чеклист перед тем как писать knot](#5-чеклист-перед-тем-как-писать-knot)
6. [Типичные ошибки — НЕ ДЕЛАЙ ТАК](#6-типичные-ошибки--не-делай-так)
7. [Примеры готовых knot'ов](#7-примеры-готовых-knotов)

---

## 1. Структура одного knot'а — шаблон

```ink
=== имя_knota ===
# bg:имя_фона # speaker:none
Текст, который увидит игрок.
Второй абзац (если нужен).
# set_flag:название_флага=true
# quest:done:id_квеста
# add_item:id_предмета
# return_to_scene
-> DONE
```

**Правила:**
- `# bg:` и `# speaker:` — **первая строка**, до текста
- Текст — середина
- Флаги, квесты, предметы — **после текста**, перед `# return_to_scene`
- `# return_to_scene` — **всегда последний** тег (кроме `-> DONE`)
- `-> DONE` — завершает knot, обязателен

---

## 2. Все поддерживаемые теги — полная таблица

### Фон и говорящий

| Что хочешь сделать | Правильный тег |
|---|---|
| Поставить фон | `# bg:bg_apartment_hall_morning` |
| Убрать имя говорящего (нарратив) | `# speaker:none` |
| Имя главного героя | `# speaker:mc` |
| Имя NPC (Мила/другой) | `# speaker:npc` |
| Любое имя напрямую | `# speaker:Аня` |

### Флаги

| Что хочешь сделать | Правильный тег |
|---|---|
| Установить флаг в `true` | `# set_flag:название=true` |
| Установить флаг в `false` | `# set_flag:название=false` |
| Установить число | `# set_flag:счётчик=5` |

> **Примечание:** тег `# flag:название=true` тоже работает (старый синтаксис).

### Предметы инвентаря

| Что хочешь сделать | Правильный тег |
|---|---|
| Добавить предмет | `# add_item:phone` |
| Убрать предмет | `# remove_item:phone` |

### Квесты

| Что хочешь сделать | Правильный тег |
|---|---|
| Начать квест | `# quest:start:id_квеста` |
| Завершить квест / шаг | `# quest:done:id_квеста` |
| Провалить квест | `# quest:fail:id_квеста` |

### Навигация по сценам

| Что хочешь сделать | Правильный тег |
|---|---|
| Вернуться в последнюю сцену (после монолога) | `# return_to_scene` |
| Перейти в конкретную сцену | `# explore:id_сцены` |

> `# return_to_scene` — **всегда висит в конце knot'а**, после всего текста. Игрок сначала дочитает текст, потом попадёт обратно в сцену.

### Телефон (SMS, заметки)

| Что хочешь сделать | Правильный тег |
|---|---|
| Прислать SMS от контакта | `# sms:add:anya:Текст сообщения` |
| Добавить заметку | `# note:add:Заголовок:Тело заметки` |
| Закрыть телефон | `# phone:close` |

### Звук и эффекты

| Что хочешь сделать | Правильный тег |
|---|---|
| Звуковой эффект | `# sfx:coffee_brew` |
| Тряска экрана | `# shake:0.3,0.5` |

---

## 3. Двойная система переменных

В проекте есть **два разных хранилища** и их нужно синхронизировать:

| Хранилище | Для чего | Синтаксис |
|---|---|---|
| **Ink-переменные** | Условия внутри ink (`{has_phone:}`) | `VAR x = false` + `~ x = true` |
| **game_state флаги** | Условия в scenes.lua, quests.lua | `# set_flag:x=true` |

### Когда нужно только `# set_flag:`

Если флаг используется только в `scenes.lua` / `quests.lua` — достаточно тега:

```ink
# set_flag:left_apartment=true
```

### Когда нужны ОБА

Если флаг **используется в условии внутри самого ink-файла** — нужны три вещи:

**Шаг 1 — в `00_bootstrap.ink` объявить переменную:**
```ink
VAR has_phone = false
```

**Шаг 2 — в knot'е присвоить значение ink-переменной:**
```ink
~ has_phone = true
```

**Шаг 3 — в knot'е выставить флаг в game_state:**
```ink
# set_flag:has_phone=true
```

### Проверка: нужно ли добавлять VAR?

Посмотри в своём ink-файле — есть ли такое:
```ink
{has_phone:        ← условие? → нужен VAR
{not coffee_drunk: ← условие? → нужен VAR
{mug_taken and coffee_drunk: ← условие? → нужен VAR для обоих
```

Нет условий → VAR не нужен, хватит `# set_flag:`.

---

## 4. Как knot связан со сценой

Knot'ы вызываются из `scenes.lua` двумя способами:

### Способ A — on_enter (автоматически при входе в сцену)

В `scenes.lua`:
```lua
on_enter = {
    knot = "apartment_bedroom_intro",  -- имя knot'а
    condition = function(gs)
        return not gs.get_flag("bedroom_morning_seen")  -- имя флага
    end,
},
```

В ink:
```ink
=== apartment_bedroom_intro ===    ← имя должно совпадать с knot =
# set_flag:bedroom_morning_seen=true   ← флаг должен совпадать с condition
# return_to_scene
-> DONE
```

> **Главное правило on_enter:** knot должен выставить флаг, который `condition` проверяет на `false`. Иначе — вечный цикл.

### Способ B — hotspot (по клику игрока)

В `scenes.lua`:
```lua
action = { type = "ink_knot", knot = "take_phone" },
```

В ink:
```ink
=== take_phone ===    ← имя должно совпадать с knot =
...
# return_to_scene
-> DONE
```

---

## 5. Чеклист перед тем как писать knot

Перед написанием нового knot'а **пройди по этому списку**:

### [ ] 1. Узнай точное имя knot'а

Открой `scenes.lua`, найди нужный hotspot или `on_enter`, скопируй значение `knot = "..."`.

### [ ] 2. Проверь флаги в condition

Если у сцены есть `on_enter.condition` — посмотри, какой флаг она проверяет.  
Твой knot **обязан** выставить этот флаг через `# set_flag:`.

### [ ] 3. Проверь квесты в quests.lua

Если knot должен двигать квест, открой `quests.lua` и уточни точный `id` квеста.  
Используй только те id, которые там есть.

### [ ] 4. Если используешь условие в ink — добавь VAR в bootstrap

```ink
{not my_flag:  ← нужен VAR my_flag = false в 00_bootstrap.ink
```

### [ ] 5. Не забудь # return_to_scene в конце

Если knot вызван из hotspot'а или on_enter — без `# return_to_scene` игрок застрянет в диалоге.

### [ ] 6. Поставь `-> DONE` последней строкой

---

## 6. Типичные ошибки — НЕ ДЕЛАЙ ТАК

### Ошибка 1: неправильный синтаксис тегов

| Неправильно | Правильно |
|---|---|
| `# setflag:bedroom_seen=true` | `# set_flag:bedroom_seen=true` |
| `# additem:phone` | `# add_item:phone` |
| `# queststart:make_coffee` | `# quest:start:make_coffee` |
| `# questdone:make_coffee` | `# quest:done:make_coffee` |

### Ошибка 2: имя knot'а не совпадает с scenes.lua

```lua
-- scenes.lua говорит:
knot = "apartment_bedroom_intro"

-- а в ink написано:
=== bedroom_intro ===   ← НЕПРАВИЛЬНО, разные имена
```

**Как проверить:** скопируй имя knot'а из scenes.lua и вставь в ink без изменений.

### Ошибка 3: on_enter без флага-заглушки → вечный цикл

```lua
-- scenes.lua:
condition = function(gs) return not gs.get_flag("seen") end
```

```ink
-- ink — нет # set_flag:seen=true:
=== my_intro ===
Текст.
# return_to_scene    ← флаг никогда не выставится → цикл!
-> DONE
```

**Правильно:**
```ink
=== my_intro ===
Текст.
# set_flag:seen=true   ← ОБЯЗАТЕЛЬНО
# return_to_scene
-> DONE
```

### Ошибка 4: VAR не объявлен, но используется в условии

```ink
-- 00_bootstrap.ink — нет VAR has_mug
-- 01_apartment.ink:
{has_mug:  ← ОШИБКА компиляции: Unresolved variable: has_mug
```

**Правильно:** открой `00_bootstrap.ink`, добавь:
```ink
VAR has_mug = false
```

### Ошибка 5: несуществующий id квеста

```ink
# quest:start:get_coffee   ← такого квеста нет в quests.lua!
```

**Как проверить:** открой `quests.lua`, найди таблицу с квестами, сверь id.

### Ошибка 6: теги до текста, флаги — нет

```ink
=== my_knot ===
# set_flag:seen=true    ← поставил флаг ДО текста
Текст монолога.
# return_to_scene
```

Технически работает, но флаг выставится до того как игрок увидит текст. Для on_enter-флагов это нормально, но логически лучше держать флаги **после текста**.

---

## 7. Примеры готовых knot'ов

### Простой монолог (осмотр объекта)

```ink
=== look_bed_morning ===
# speaker:none
Постель скомкана. Сон был неровным.
# return_to_scene
-> DONE
```

### Монолог с получением предмета

```ink
=== take_mug ===
# speaker:none
Кружка в шкафчике. Берёшь её.
# add_item:mug
~ has_mug = true
# set_flag:has_mug=true
# return_to_scene
-> DONE
```

> Нужно `~ has_mug = true` потому что в ink есть условие `{has_mug:}`.  
> `~ has_mug = true` — для ink. `# set_flag:has_mug=true` — для scenes.lua/quests.lua.

### on_enter-монолог (один раз при входе в сцену)

```ink
=== apartment_bedroom_intro ===
# bg:bg_apartment_bedroom_morning # speaker:none
Комната держит сон: смятая постель, слабый свет через жалюзи.
На тумбочке что-то лежит экраном вниз.
# set_flag:bedroom_morning_seen=true
# quest:start:find_phone
# return_to_scene
-> DONE
```

> Флаг `bedroom_morning_seen` выставляется сразу — до того как игрок кликнет «Далее».  
> Когда после клика сработает `return_to_scene`, `on_enter.condition` уже вернёт `false` — цикла не будет.

### Монолог с SMS и квестом

```ink
=== take_phone ===
# speaker:none
Телефон вспыхивает экраном. Есть сообщения.
# sfx:phone_notify
# add_item:phone
~ has_phone = true
# set_flag:has_phone=true
# set_flag:phone_active=true
# sms:add:anya:Ты видел PATCH к temporal_sync.module? Очень важно.
# quest:done:find_phone
# quest:start:reply_anya
# return_to_scene
-> DONE
```

### Итерационно-зависимый текст

```ink
=== look_hall_mirror ===
# speaker:none
{iteration_number > 1:
Знакомое лицо. Слишком знакомое — будто уже видел его сегодня.
~ INSIGHT = INSIGHT + 1
- else:
Обычное отражение. Ничего странного.
}
# return_to_scene
-> DONE
```

---

## Быстрая справка — одним взглядом

```
=== имя_из_scenes_lua ===
# bg:имя_фона # speaker:none          ← первой строкой
Текст для игрока.
# set_flag:флаг_из_condition=true     ← ОБЯЗАТЕЛЬНО если on_enter
# quest:start:id_из_quests_lua        ← только существующие id
# quest:done:id_из_quests_lua
# add_item:id_предмета
# sms:add:контакт:текст
# return_to_scene                     ← последний тег
-> DONE                               ← последняя строка
```

**Если в ink есть `{флаг:` или `{not флаг:` → в `00_bootstrap.ink` нужен `VAR флаг = false`**
