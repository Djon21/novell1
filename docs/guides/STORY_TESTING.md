# Story Test System — Сквозное тестирование сюжета через inkjs

Единственный source of truth по работе теста: `tests/story_test.js`. Этот файл проходится по реальному Ink через `Story.Continue()`, выбирает варианты и проверяет, что сюжет доходит до концовок итераций.

---

## Содержание

1. [Обзор](#1-обзор)
2. [Архитектура Walker](#2-архитектура-walker)
3. [Функции проходок](#3-функции-проходок)
4. [Что тестируется](#4-что-тестируется)
5. [Что НЕ тестируется](#5-что-не-тестируется)
6. [Как запускать](#6-как-запускать)
7. [CI-интеграция](#7-ci-интеграция)
8. [Git hooks](#8-git-hooks)
9. [Добавление новых путей](#9-добавление-новых-путей)
10. [Известные ограничения](#10-известные-ограничения)

---

## 1. Обзор

`story_test.js` — smoke-тест сюжета, который:

- загружает скомпилированный `main/story/chapter_01.json` через библиотеку [inkjs](https://github.com/y-lohse/inkjs);
- устанавливает переменные Ink, чтобы симулировать состояние Lua (флаги дня, gender, iteration_number);
- проходит через **реальный Ink**: вызывает `Continue()`, читает теги (`# set_flag:`, `# quest:*`, `# explore:`, `# splash:`, `# meta:add:`, `# phone:map`);
- делает выборы через `ChooseChoiceIndex()` — то есть проверяет, что варианты отображаются, а не зашиты в `ChoosePathString`;
- для переходов между сценами (где `Continue()` не умеет сам перейти) использует `ChoosePathString` — это единственное исключение;
- собирает `current_iteration_end` с каждой итерации и проверяет, что концовка достигнута.

**Три итерации по порядку:**

| Итерация | Функция | Что проверяет |
|----------|---------|----------------|
| 1 (Iter 1) | `walkIter1` | Линейный сценарий: воскресенье → понедельник → вторник → крыша → `chapter_finished` |
| 2 (NPC ending) | `walkIter2` с `targetEnding="npc"` | Вторая итерация через ложную концовку про человека (`TRUST=10, INSIGHT=2`) |
| 3 (System ending) | `walkIter2` с `targetEnding="system"` | Вторая итерация через ложную концовку про систему (`TRUST=2, INSIGHT=10`) |

---

## 2. Архитектура Walker

### 2.1. Класс `Walker`

```javascript
class Walker {
    constructor(story, log = false) { ... }

    walk(maxSteps = 2000)        // Continue() пока не choices/timeout/ended
    pick(matcher)                // Выбрать вариант по индексу или тексту
    walkAndPick(matcher)         // walk() + pick()
    runKnot(knot)                // ChoosePathString(knot) + walk()
    assertTag(prefix)            // Проверить, что среди собранных тегов есть prefix
    resetTags()                  // Очистить буфер тегов
}
```

Поля:
- `this.story` — инстанс `inkjs.Story`.
- `this.steps` — счётчик шагов (суммарный по всем `walk()` вызовам).
- `this.tags` — объект с буфером тегов последнего `walk()`:
  ```javascript
  { set_flag: {}, quest: {}, explore: null, splash: null, meta: null, phone_map: false }
  ```

### 2.2. `walk()`

Основной цикл. Пока `story.canContinue` и не превышен `maxSteps`:

1. Вызвать `story.Continue()`.
2. Прочитать `story.currentTags`.
3. Распарсить теги:
   - `# set_flag:name=val` → `this.tags.set_flag[name] = val`
   - `# quest:action:id` → `this.tags.quest["action:id"] = true`
   - `# explore:scene_id` → `this.tags.explore = scene_id`
   - `# splash:id` → `this.tags.splash = id`
   - `# meta:add:key:1` → `this.tags.meta = key:1`
   - `# phone:map` → `this.tags.phone_map = true`
4. Если появились `currentChoices` — вернуть `"choices"`.
5. Если кончился контент — вернуть `"ended"`.
6. Если превышен `maxSteps` — вернуть `"timeout"`.

### 2.3. `pick(matcher)`

Выбирает вариант из `story.currentChoices`. Типы `matcher`:

| Тип | Поведение |
|-----|-----------|
| `number` | Выбор по индексу (по умолчанию `0`) |
| `string` | Первый choice, чей `text.includes(matcher)` |
| `function` | Первый choice, для которого `matcher(text)` истина |

Всегда клиппируется в `[0, choices.length - 1]`.

### 2.4. `runKnot(knot)`

```javascript
runKnot(knot, maxSteps = 500) {
    this.story.ChoosePathString(knot);
    return this.walk(maxSteps);
}
```

Используется для переходов между сценами. Это единственное место, где тест не идёт через `Continue()`.

### 2.5. `assertTag(prefix)`

Проверяет, что среди собранных тегов есть хотя бы один, начинающийся с `prefix`. Ищет по:
- `this.tags.set_flag` (ключам)
- `this.tags.quest` (ключам)
- `this.tags.explore`

Если не находит — пишет `⚠ MISSING TAG: prefix` и возвращает `false`.

---

## 3. Функции проходок

### 3.1. `walkIter1(w, log)` — Iteration 1

```javascript
function walkIter1(w, log) { ... }
```

Последовательность:

1. **Character** — `iteration_number = 1`, walk + pick(0), walk, `runKnot("seed_phone_history")`.
2. **Set up for date** — флаги: `got_out_of_bed`, `washed_up`, `teeth_brushed`, `sunday_dressed`, `date_agreed`, `date_place_cafe`. Run `leave_apartment` → `sunday_date_go_cafe`.
3. **Cafe date** — `sunday_date_cafe_arrival`, `cafe_bar_interact`, pick(0) если есть choices, `cafe_corner_main_talk`.
4. **Evening + sleep** — флаг `met_npc_sunday=true`, `leave_cafe`, `sunday_evening_started=true`, `sunday_evening_home`, `sunday_sleep_in_bed`.
5. **Monday** — флаги `sunday_finished=true`, `monday_started=true`. Walk + pick вариант с "автомат" (или первый). Флаги `monday_coffee_done`, `monday_breakfast_done`, `monday_water_drunk`. Run `mon_home_leave_apartment`.
6. **Office** — `work_desk_read_mail`, флаг `monday_mail_read=true`, `meeting_room_take_folder`, `monday_case_file_assembled=true`, `work_desk_case_file_prompt`.
7. **Tuesday** — walkAndPick(0). Флаги `tuesday_phone_checked`, `tuesday_washed_up`, `tuesday_ready_to_leave`. Run `tue_home_leave_apartment`.
8. **Rooftop → ending** — walkAndPick(0), walk(2000). Читает `current_iteration_end`.

Возвращает `{ ok: true, steps, ending }`.

### 3.2. `walkIter2(w, log, targetEnding)` — Iteration 2

```javascript
function walkIter2(w, log, targetEnding) { ... }
```

Параметр `targetEnding`: `"npc"` или `"system"`.

Последовательность:

1. **Character** — `iteration_number = 2`, walk + pick(0), walk, `runKnot("seed_phone_history")`.
2. **Fake Wednesday** — флаги `got_out_of_bed`, `washed_up`, `teeth_brushed`, `sunday_dressed`, `loop2_fake_wednesday_started`. Run `leave_apartment_prompt`.
3. **Office check** — walk, pick(0) если есть choices. `work_desk_read_mail`, `monday_mail_read=true`, `meeting_room_take_folder`, `monday_case_file_assembled=true`, `loop2_work_check_done=true`, `work_desk_case_file_prompt`.
4. **Evening + second invite** — walkAndPick(0). Выбор thread- knot по полу: `msg_thread_mila` или `msg_thread_artem`. Pick(0) если есть choices.
5. **Park date** — флаги `date_agreed=true`, `date_place_park=true`. `sunday_date_go_park`, `sunday_date_park_arrival`, `park_npc_arrives`. Флаги `met_npc_sunday=true`, `park_npc_greeted=true`. `leave_park`.
6. **Evening + sleep** — как в Iter 1.
7. **Monday** — как в Iter 1.
8. **Tuesday** — как в Iter 1.
9. **Rooftop → ending** — walkAndPick(0), walk(2000). Устанавливает `TRUST`/`INSIGHT`:
   - NPC ending: `TRUST=10, INSIGHT=2`
   - System ending: `TRUST=2, INSIGHT=10`
   Walk + pick по тексту ("человека" или "логику"). Walk(2000).

Возвращает `{ ok: !!ending, steps, ending }`.

### 3.3. `walkFull(w, log)` — Full walkthrough

```javascript
function walkFull(w, log) {
    const r1 = walkIter1(w, log);   // Iter 1
    const r2 = walkIter2(w, log, "npc");    // Iter 2 NPC
    const r3 = walkIter2(w, log, "system"); // Iter 3 System
    return { steps: totalSteps, ok: true };
}
```

Проходит все три итерации подряд. Возвращает `{ steps, ok: true }`.

---

## 4. Что тестируется

### 4.1. Ink-условия

- **`iteration_number`-ветвление** — проверяется, что Ink правильно выбирает диалог для Iter 1 vs Iter 2.
- **Гендерное согласование** — тест стартует с `setChar(story, "male")`. Если бы гендер был сломан (падежи не совпадают), inkjs уронил бы выполнение в рантайме.
- **Условные выборы** — варианты, скрытые за `{TRUST >= 5:}`, проверяются тем, что тест либо находит их, либо переходит к следующему шагу.

### 4.2. Quest tag balance

Тест не проверяет quest-баланс явно, но при проходе через сюжет собирает все `# quest:start:ID` и `# quest:done:ID`. Если какой-то quest стартуется, но никогда не закрывается в рамках проходимого пути — это не считается ошибкой (могут быть побочные квесты). Если же `# quest:done:` появляется без `# quest:start:` на этом пути — это легитимно (quest мог стартоваться в другой ветке).

### 4.3. Loop reset

Каждая итерация заканчивается установкой `current_iteration_end`. Тест проверяет, что это значение не `null` и не `"none"` — значит механизм завершения итерации работает.

### 4.4. Story reachability

- Все ключевые knot'ы доступны: `leave_apartment`, `sunday_date_go_cafe`, `cafe_bar_interact`, `cafe_corner_main_talk`, `sunday_evening_home`, `work_desk_read_mail`, `meeting_room_take_folder`, `tue_home_leave_apartment` и т.д.
- Messenger thread'ы выбираются по полу: `msg_thread_mila` или `msg_thread_artem`.
- Финальная rooftop-сцена не падает с `ran out of content`.
- True ending НЕ тестируется (Iter 4).

---

## 5. Что НЕ тестируется

| Что | Почему |
|-----|--------|
| Lua-видимость hotspot'ов | Тест идёт в Ink, а не в Defold. `scenes.lua` с `is_visible` не вызываются. |
| Правильные типы предметов в combine | Тест не симулирует клики по инвентарю. Проверка инвентарных комбинаций — ручной QA. |
| Shop / bar / viewpoint side paths | Тест проходит `cafe_bar_interact` только с pick(0), но не заходит в магазин, бар или смотровую площадку. |
| Female character path | `setChar(story, "male")` зашит в `runTest()`. Женский путь не проверяется. |
| Iter 4 (True Ending) | `walkFull` проходит только 3 итерации. True Ending откроется при `false_endings_count >= 2`, но тест не делает четвёртый проход. |
| Локализации | Текст проверяется только на русском (как в `.ink`). EN/TR не тестируются. |
| Переходы карты и POI lock | `# map:allow:*`, `# map:lock_to:*` не проверяются — это Lua-логика. |

---

## 6. Как запускать

### 6.1. Зависимости

```bash
npm install    # установит inkjs из package.json
```

Перед запуском обязательно скомпилировать Ink (см. AGENTS.md):

```bash
tools\compile_ink.bat chapter_01
```

### 6.2. Полный прогон (все итерации)

```bash
npm test
# или:
npm run test
# или явно:
node tests/story_test.js full
```

Запускает `walkFull()` — Iter 1 + Iter 2 NPC + Iter 3 System. Требуется ~30000 шагов (MAX_STEPS).

### 6.3. Только Iter 1

```bash
npm run test:iter1
# или:
node tests/story_test.js iter1
```

Быстрая проверка линейной итерации.

### 6.4. Iter 2 — NPC ending

```bash
node tests/story_test.js iter2_npc
```

### 6.5. Iter 2 — System ending

```bash
node tests/story_test.js iter2_system
```

### 6.6. Режимы

| Аргумент | Функции | Параметры |
|----------|---------|-----------|
| `full` | `walkFull` | `log=true` (вывод текста) |
| `iter1` | `walkIter1` | `targetEnding` не используется |
| `iter2_npc` | `walkIter2` | `targetEnding="npc"` |
| `iter2_system` | `walkIter2` | `targetEnding="system"` |

Всегда использует `setChar(story, "male")`.

### 6.7. Выходной код

- `0` — все тесты прошли.
- `1` — хотя бы один тест упал (или fatal ошибка).

---

## 7. CI-интеграция

### 7.1. Файл: `.github/workflows/ink_lint.yml`

```yaml
name: Ink Lint + Story Test

on:
  push:
    paths:
      - "main/story/chapters/**/*.ink"
      - "*.json"
      - "tools/ink_lint.py"
      - "tests/story_test.js"
      - "package.json"
  pull_request:
    # те же paths

jobs:
  lint:              # ink_lint.py --ci
  story-test:        # node tests/story_test.js full
```

Два джоба:
1. **lint** — Python-линтер на `.ink` файлы.
2. **story-test** — Node.js smoke test. Устанавливает `npm install`, запускает `node tests/story_test.js full`.

Оба запускаются только при изменениях в Ink-файлах, JSON, тестах или зависимостях.

### 7.2. workflow

```
push/PR → (paths match?) → lint: python tools/ink_lint.py --ci
                         → story-test: node tests/story_test.js full
```

---

## 8. Git hooks

### 8.1. `.githooks/pre-commit`

Настроен через `git config core.hooksPath .githooks`.

Скрипт проверяет, что среди staged файлов есть `.ink`, и если да — запускает:

```bash
python tools/ink_lint.py --ci
```

При ошибке коммит блокируется. **Story test на commit не запускается** (только в CI на push).

### 8.2. Рекомендация

Перед push рекомендуется явно запустить:

```bash
npm test
```

Чтобы убедиться, что CI не упадёт. CI запускает `full` — все 3 итерации.

---

## 9. Добавление новых путей

### 9.1. Iter 4 — True Ending

Чтобы добавить тест для истинной концовки:

1. Создать функцию `walkIter4(w, log)` — аналогично `walkIter2`, но:
   - `iteration_number = 3` (или 4 — зависит от сценария).
   - Должна пройти через условия, открывающие `# loop:end:true`.

2. Добавить вызов в `walkFull`:
   ```javascript
   function walkFull(w, log) {
       const r1 = walkIter1(w, log);
       const r2 = walkIter2(w, log, "npc");
       const r3 = walkIter2(w, log, "system");
       const r4 = walkIter4(w, log);         // ← добавить
       return { steps: totalSteps, ok: true };
   }
   ```

3. Добавить режим запуска в `main()`:
   ```javascript
   if (mode === "iter4") tests.push(["Iter 4", (w,l) => walkIter4(w,l)]);
   ```

### 9.2. Female character

1. Создать `runTestFemale(label, fn)` — копию `runTest`, но с `setChar(story, "female")`.

2. Добавить в main:
   ```javascript
   if (mode === "all" || mode === "female") {
       tests.push(["Full (female)", (w,l) => runTestFemale(...)]);
   }
   ```

Потребуется проверить, что все knot'ы с гендерными форками (`mc_gender`, окончания `{mc_gender == "female":ла|л}`) работают для женского пола.

### 9.3. Боковые локации (shop, bar, viewpoint)

Для каждой:
1. Написать функцию `walkIter1_shop(w, log)` или модифицировать `walkIter1` с параметром `location`.
2. Установить альтернативные флаги вместо `date_place_cafe`.
3. Запустить требуемые knot'ы: `sunday_date_go_shop`, `shop_sunday_...` и т.д.

### 9.4. Регистрация в документации

После добавления новых функций обновить:
- `docs/guides/STORY_TESTING.md` — таблица режимов и список проходок.
- `docs/README.md` — если меняется конфигурация CI или команды запуска.

---

## 10. Известные ограничения

### 10.1. `seed_phone_history` — dead knot workaround

```javascript
w.runKnot("seed_phone_history");
```

`seed_phone_history` — это knot-туннель, который не содержит текста, а только теги для инициализации телефона (SMS-история, банковские транзакции). Его нельзя вызвать через обычный `Continue()` — только через `ChoosePathString`. Это костыль, потому что телефонное состояние живёт в Lua и не может быть установлено через `story.variablesState`.

Если `seed_phone_history` удалят или переименуют, тест упадёт.

### 10.2. Lua-only флаги

Тест устанавливает переменные Ink через `story.variablesState`, но многие флаги в игре живут только в Lua (`game_state`, `meta_state`). Для таких флагов тест вынужден проставлять их вручную через `setVars()` перед вызовом knot'а:

```javascript
setVars(w.story, {
    monday_coffee_done: true,
    monday_breakfast_done: true,
    monday_water_drunk: true,
});
```

Это значит, что тест **не проверяет**, что эти флаги корректно устанавливаются самим сюжетом — он их предполагает. Если реальный сюжетный путь не выставит флаг, но тест его принудительно выставит, баг останется незамеченным.

### 10.3. `ChoosePathString` для переходов между сценами

`Continue()` не умеет автоматически переходить в другую сцену после `# explore:*`. Тест использует `runKnot(knot)` → `ChoosePathString()` для каждого перехода. Это значит, что тест не проверяет реальную последовательность переходов, которую увидел бы игрок через point-and-click.

Пример из `walkIter1`:

```javascript
w.runKnot("leave_apartment");
w.runKnot("sunday_date_go_cafe");
w.runKnot("sunday_date_cafe_arrival");
```

Здесь `leave_apartment` закончится на `# explore:apartment_hub`, но тест этого не обрабатывает — он просто прыгает в следующий knot. Если между `leave_apartment` и `sunday_date_go_cafe` есть обязательный игровой шаг (например, выбор транспорта на карте), тест его пропустит.

### 10.4. Нет проверки типа концовки

Тест не проверяет, что `current_iteration_end` содержит ожидаемое значение (`"chapter_finished"`, `"loop:end:false:ending_npc"` и т.д.). Он только проверяет, что переменная не пустая. Если концовка изменится с правильной на неправильную (например, `chapter_finished` вместо `loop:end:false`), тест не заметит.

### 10.5. Фиксированный seed

`setChar(story, "male")` зашит в `runTest()`. Случайные выборы не тестируются — всегда выбирается первый вариант или вариант по текстовому совпадению. Это нормально для smoke-теста, но не покрывает все возможные ветки сюжета.

---

## Приложение: Структура тестового файла

```text
tests/story_test.js
├── Helpers
│   ├── loadStory()          // загрузка chapter_01.json
│   ├── setVars(story, vars) // установка Ink-переменных
│   └── setChar(story, gender) // установка gen-зависимых имён
│
├── Walker class
│   ├── walk()
│   ├── pick()
│   ├── walkAndPick()
│   ├── runKnot()
│   └── assertTag()
│
├── Walkthrough functions
│   ├── walkIter1()
│   ├── walkIter2()
│   └── walkFull()
│
├── Test runner
│   ├── runTest()            // обёртка с loadStory + setChar + Walker
│   └── main()               // CLI: выбор режима, запуск, exit code
│
└── CLI modes
    ├── full        → walkFull
    ├── iter1       → walkIter1
    ├── iter2_npc   → walkIter2(targetEnding="npc")
    └── iter2_system → walkIter2(targetEnding="system")
```

---

## Приложение: Быстрая справка по inkjs API

| API | Использование в тесте |
|-----|-----------------------|
| `new Story(json)` | Загрузка скомпилированного JSON |
| `story.Continue()` | Чтение следующего фрагмента текста |
| `story.canContinue` | Проверка, есть ли ещё контент |
| `story.currentTags` | Теги текущего фрагмента |
| `story.currentChoices` | Доступные варианты выбора |
| `story.ChooseChoiceIndex(i)` | Выбор варианта по индексу |
| `story.ChoosePathString(knot)` | Прыжок в knot (аналог `-> knot_name`) |
| `story.variablesState[k] = v` | Установка Ink-переменной |
| `story.onError` | Колбэк для ошибок inkjs |
