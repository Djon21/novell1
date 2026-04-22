# Инструкция по добавлению портретов персонажей

В текущем `v2`-стеке портреты больше не требуют отдельных GUI-нод под каждого героя. `dialogue_v2.gui` использует один общий `portrait_bg`, а нужный спрайт подставляет `main/gui/components_v2/dialogue_v2.gui_script`.

## Куда сейчас добавляются портреты

- активный atlas: `main/images/v2.atlas`
- активная логика: `main/gui/components_v2/dialogue_v2.gui_script`
- legacy `main/images/characters.atlas` нужен только для старого UI и не является текущим source of truth

## Требования к файлу

- формат: `PNG`
- прозрачный фон
- рекомендуемый размер: `512x512`
- имя файла: латиница, lowercase

Пример:

```text
main/images/v2/anya.png
```

## Шаг 1: Добавить файл в `main/images/v2/`

```text
main/images/v2/anya.png
```

## Шаг 2: Зарегистрировать его в `main/images/v2.atlas`

```text
images {
  image: "/main/images/v2/anya.png"
}
```

После этого atlas frame будет называться `anya`.

## Шаг 3: Добавить персонажа в `dialogue_v2.gui_script`

Найдите таблицу `CHARS` в `main/gui/components_v2/dialogue_v2.gui_script` и добавьте новый ключ.

Пример:

```lua
["аня"] = {
    color = vmath.vector4(1.0, 0.702, 0.278, 1.0),
    icon = string.char(0xEE, 0x9F, 0xBB),
    tag = "контакт",
    portrait = "anya",
},
```

Что важно:

- ключ ищется после приведения speaker к нижнему регистру
- `portrait` должен совпадать с именем кадра в `v2.atlas`
- `tag` и `color` — это подпись и акцент nameplate

## Шаг 4: Использовать персонажа в Ink

```ink
# speaker:Аня
Привет.
```

или

```ink
# speaker:аня
Привет.
```

Поскольку lookup идёт в lower-case, обе формы будут работать, если ключ в `CHARS` добавлен корректно.

## Спец-значения speaker

- `# speaker:mc` — имя главного героя из `save_manager`
- `# speaker:npc` — имя второго главного персонажа
- `# speaker:none` — нарратив без портрета

Для `mc` и `npc` уже настроены маппинги на текущие портреты Артёма и Милы.

## Что изменилось по сравнению с legacy UI

Больше не нужно:

- править `novel_ui.gui`
- создавать отдельную GUI-ноду `portrait_anya`
- регистрировать портрет в `S.portraits`

Всё это относилось к старому монолитному UI.

## Fallback-поведение

Если `portrait` не найден, `dialogue_v2.gui_script` покажет иконку-заглушку вместо спрайта. Это удобно для промежуточных персонажей, но для боевого контента лучше всё-таки добавить настоящий портрет.

## Чеклист

- [ ] PNG лежит в `main/images/v2/`
- [ ] файл прописан в `main/images/v2.atlas`
- [ ] персонаж добавлен в `CHARS` в `dialogue_v2.gui_script`
- [ ] `portrait` совпадает с atlas frame
- [ ] реплика с `# speaker:Имя` проверена в игре
