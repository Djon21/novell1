# Yandex SDK и реклама

Актуально на `2026-05-06`.

Этот документ описывает, как в проекте подключен Yandex Games SDK, где он инициализируется, как Lua-код получает доступ к SDK и как вызывать рекламу.

## Коротко

- SDK подключен через Defold dependency `defold-yagames` в `game.project`.
- Ручной `YaGames.init()` в `main/engine_template.html` больше не нужен и не должен добавляться обратно.
- HTML-блок SDK вставляется расширением `defold-yagames` во время HTML5-сборки через manifest merge.
- Язык Яндекса сохраняется в `window.__gameLang` через настройку `yagames.sdk_init_snippet` в `game.project`.
- Рекламу из игры надо вызывать через Lua-модуль:

```lua
local yagames = require("yagames.yagames")
```

## Где подключен SDK

Главное место подключения:

```ini
# game.project

[project]
dependencies#0 = https://github.com/indiesoftby/defold-yagames/archive/master.zip

[yagames]
sdk_init_snippet = try { window.__gameLang = ysdk.environment.i18n.lang; console.log("YaGames lang:", window.__gameLang); } catch (e) { console.warn("Cannot read environment.i18n.lang:", e); } try { ysdk.features.LoadingAPI.ready(); } catch (e) { console.warn("LoadingAPI.ready failed:", e); }
```

Что это значит:

- `dependencies#0` скачивает и подключает расширение `defold-yagames`.
- Расширение добавляет JS SDK Яндекса в HTML5 build.
- `[yagames].sdk_init_snippet` выполняется сразу после успешного `YaGames.init(...)`.
- В snippet сейчас делаются две вещи: сохраняется язык в `window.__gameLang` и вызывается `ysdk.features.LoadingAPI.ready()`.

## Почему SDK не видно напрямую в `engine_template.html`

Сейчас так и должно быть.

`main/engine_template.html` является шаблоном страницы игры. Мы убрали оттуда ручной блок:

```js
YaGames.init(...)
```

Если добавить его обратно, при сборке получится дубль: один init из нашего шаблона и второй init из `defold-yagames`.

Правильная схема теперь такая:

1. Defold собирает HTML5 билд.
2. Берется `main/engine_template.html`.
3. Manifest расширения `defold-yagames` добавляет в итоговый HTML свой SDK-блок.
4. В этот блок подставляется `sdk_init_snippet` из `game.project`.
5. Игра стартует уже после инициализации SDK.

Важно: папка `build/wasm-web` является сгенерированной. Если там виден старый HTML с двумя SDK-блоками, это старый билд. Нужно пересобрать HTML5.

## Как игра узнает язык Яндекса

Язык берется из JS SDK:

```js
ysdk.environment.i18n.lang
```

Затем сохраняется в глобальную JS-переменную:

```js
window.__gameLang
```

Lua-сторона читает ее через `html5.run`:

```lua
local ok, lang = pcall(html5.run, "window.__gameLang || ''")
```

Для локализации не нужно делать `require("yagames.yagames")`. Локализация специально читает только `window.__gameLang`, чтобы UI мог получить язык как можно раньше.

## Как подключить SDK в Lua

Если нужна реклама, лидерборды, авторизация, покупки или другие методы SDK, подключай модуль так:

```lua
local yagames = require("yagames.yagames")
```

Лучше делать `require` на верхнем уровне файла, не внутри `pcall`.

Правильно:

```lua
local yagames = require("yagames.yagames")

function init(self)
    yagames.init(function(self, err)
        if err then
            print("Yandex SDK init error:", err)
            return
        end

        print("Yandex SDK ready")
    end)
end
```

Не рекомендуется:

```lua
local ok, yagames = pcall(require, "yagames.yagames")
```

Причина: Defold должен увидеть `require("yagames.yagames")` статически, чтобы модуль точно попал в HTML5 bundle.

## Главное правило перед рекламой

Рекламу нельзя показывать в момент активного игрового действия, когда игрок может случайно нажать по рекламному блоку.

Для визуальной новеллы хорошие места:

- перед переходом на новую большую сцену;
- после завершения главы;
- после выбора направления на карте, но до загрузки новой локации;
- после ложной концовки;
- перед началом новой итерации.

Плохие места:

- прямо посреди фразы;
- во время typewriter-эффекта;
- в момент, когда игрок нажимает hotspot;
- сразу под палец игрока на мобильном экране без понятной паузы.

## Полноэкранная реклама

Это обычная interstitial-реклама. Ее можно показывать в логических паузах.

Минимальный пример:

```lua
local yagames = require("yagames.yagames")

local function show_fullscreen_ad()
    yagames.features_gameplayapi_stop()

    yagames.adv_show_fullscreen_adv({
        open = function(self)
            sound.set_group_gain("master", 0)
            print("Fullscreen ad opened")
        end,

        close = function(self, was_shown)
            sound.set_group_gain("master", 1)
            yagames.features_gameplayapi_start()

            if was_shown then
                print("Fullscreen ad was shown")
            else
                print("Fullscreen ad was not shown")
            end
        end,

        offline = function(self)
            print("Fullscreen ad offline")
        end,

        error = function(self, err)
            print("Fullscreen ad error:", err)
        end
    })
end
```

Что важно:

- `features_gameplayapi_stop()` вызывается перед рекламой.
- Звук глушится в `open`.
- Звук возвращается в `close`.
- `features_gameplayapi_start()` вызывается в `close`, когда игра снова продолжается.
- `close` вызывается даже если реклама не была показана.
- `was_shown == false` обычно означает, что реклама не открылась, например из-за слишком частого вызова или ошибки.

## Rewarded video

Rewarded video показывается только когда игрок сам понимает, что смотрит рекламу ради награды.

Пример:

```lua
local yagames = require("yagames.yagames")

local function show_rewarded_ad()
    local reward_ready = false

    yagames.features_gameplayapi_stop()

    yagames.adv_show_rewarded_video({
        open = function(self)
            sound.set_group_gain("master", 0)
            print("Rewarded video opened")
        end,

        rewarded = function(self)
            reward_ready = true
            print("Reward counted")
        end,

        close = function(self)
            sound.set_group_gain("master", 1)
            yagames.features_gameplayapi_start()

            if reward_ready then
                -- Выдать награду здесь.
                -- Например: добавить подсказку, валюту, бонусную попытку.
                print("Give reward")
            else
                print("Rewarded video closed without reward")
            end
        end,

        error = function(self, err)
            print("Rewarded video error:", err)
        end
    })
end
```

Главное правило rewarded video: награду выдаем только если был callback `rewarded`.

## Sticky banner

Sticky banner можно показывать/скрывать через:

```lua
yagames.adv_show_banner_adv()
yagames.adv_hide_banner_adv()
yagames.adv_get_banner_adv_status(callback)
```

Для текущей игры sticky banner лучше не включать автоматически, пока не понятно, где он не будет закрывать телефон, inventory, LOG и hotspots.

Если включать позже, сначала нужно проверить на мобильном экране:

- не перекрывает ли нижнюю часть телефона;
- не мешает ли карте;
- не закрывает ли кнопки HUD;
- не конфликтует ли с портретной ориентацией.

## Где лучше держать код рекламы

Не стоит размазывать прямые вызовы `yagames.adv_show_*` по разным GUI-скриптам.

В проекте для этого есть один модуль-обертка:

```text
main/scripts/yandex_ads.lua
```

В нем живут:

- `init(callback)`;
- `show_fullscreen(on_done)`;
- `show_rewarded(on_reward, on_done)`;
- защиту от двойного показа;
- mute/unmute;
- `GameplayAPI.stop/start`.

Вызывать SDK напрямую из Ink/runtime-кода больше не нужно. Используй обертку:

```lua
local yandex_ads = require("main.scripts.yandex_ads")

yandex_ads.show_fullscreen(function(was_shown)
    -- Продолжить переход на следующую сцену.
end)
```

## Как вызвать рекламу из Ink

Для сценария добавлены теги:

```ink
# adv:fullscreen
# ad:fullscreen
# adv:rewarded
# adv:rewarded:reward_flag_name
```

`adv` и `ad` работают одинаково. `ad` просто короткий alias.

Пример полноэкранной рекламы перед картой:

```ink
# speaker:none
Дорога до офиса занимает время.

# adv:fullscreen
# phone:map
-> DONE
```

Пример rewarded video с флагом награды:

```ink
* [Посмотреть рекламу и получить подсказку]
    # adv:rewarded:watched_hint_ad
    # speaker:none
    Если реклама досмотрена, игра поставит флаг watched_hint_ad=true.
    -> DONE
```

`# adv:rewarded:watched_hint_ad` ставит `game_state` flag `watched_hint_ad = true` только если SDK прислал callback `rewarded`. Важно: это именно `game_state` flag, не Ink `VAR`, поэтому внутри той же Ink-ветки его нельзя читать через `{watched_hint_ad: ...}`. Он полезен для Lua-логики, сцен, хотспотов, квестов и последующих проверок через runtime.

Если после `# adv:fullscreen` или `# adv:rewarded` в той же пачке идут другие команды, `dm_commands.lua` продолжит их после закрытия рекламы через callback `on_resume`. Это нужно для сценариев вроде `# adv:fullscreen` → `# goto_scene:*` или `# adv:fullscreen` → `# phone:map`.

## Когда вызывать init

`yagames.init(...)` нужно вызвать один раз после старта игры. Сейчас это делает `ui_manager_v2.script` через:

```lua
local yandex_ads = require("main.scripts.yandex_ads")
```

И в `init(self)`:

```lua
yandex_ads.init()
```

В HTML5 на Яндексе SDK будет настоящий.

В локальном desktop-запуске расширение использует mock-режим, поэтому код не должен падать, но настоящая реклама локально не покажется.

## Как проверить рекламу

Проверять рекламу надо в HTML5-билде.

Минимальный smoke-test:

1. Собрать HTML5.
2. Запустить build в окружении Яндекс Игр или через тестирование в консоли Яндекса.
3. Открыть DevTools console.
4. Проверить, что нет ошибок `YaGames.init`.
5. Дойти до места, где вызывается реклама.
6. Проверить, что звук выключается на рекламе и возвращается после закрытия.
7. Проверить, что игра продолжает переход/сцену после `close`.

Если реклама не показывается:

- проверь, включена ли монетизация в Консоли разработчика Яндекс Игр;
- проверь, не вызывается ли fullscreen слишком часто;
- проверь console на ошибки SDK;
- проверь, что `yagames.init(...)` уже завершился без `err`;
- проверь, что тест идет именно в HTML5, а не в нативном desktop-билде.

## Что нельзя делать

- Не добавлять вручную `<script src="/sdk.js">` в `main/engine_template.html`.
- Не добавлять второй `YaGames.init(...)` в `main/engine_template.html`.
- Не вызывать рекламу до завершения `yagames.init(...)`.
- Не выдавать rewarded-награду в `close`, если до этого не пришел `rewarded`.
- Не показывать fullscreen-рекламу под случайный тап игрока.
- Не раскидывать прямые вызовы рекламы по разным GUI-скриптам.

## Полезные ссылки

- Официальная документация Яндекса по рекламе для Defold: https://yandex.ru/dev/games/doc/ru/sdk/defold/adv
- Официальная документация Яндекса по `LoadingAPI` и `GameplayAPI`: https://yandex.com/dev/games/doc/en/sdk/sdk-game-events
- Репозиторий подключенного Defold-расширения: https://github.com/indiesoftby/defold-yagames
