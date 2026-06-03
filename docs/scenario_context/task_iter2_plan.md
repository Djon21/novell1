# Iteration 2 — План работ

> **Создан**: 2026-06-03  
> **Текущее состояние**: iter 1 завершён (true/false ending → `loop1_to_iter2_reset`).  
> **Задача**: Дописать iter 2 от точки возврата из офиса до финала игры.

## Краткий сюжет iter 2

Герой просыпается, думает что среда — телефон показывает воскресенье. Пытается пойти на работу → офис закрыт. После возврата принимает что это воскресенье. Проживает воскресенье (свидание) с новым осознанием, но мир повторяется. В понедельник может выбрать другую стратегию в офисе. Во вторник — другие последствия. На крыше — финал: true ending требует синтеза обоих подходов.

---

## Phase 0: УЖЕ РАБОТАЕТ (не трогать)

Следующие узлы iter 2 уже написаны и не требуют изменений:

| Knot | Файл | Строка |
|---|---|---|
| `apartment_start` (iter 2: «Среда... телефон глючит») | `10_apartment.ink` | 66 |
| `look_bed_morning` (iter 2: «Постель смята точно так же») | `10a_sunday.ink` | 11 |
| `bedroom_desk_morning` (iter 2: first_anomaly_seen) | `10a_sunday.ink` | 51 |
| `look_bedroom_window` (iter 2: «Картинка слишком знакомая») | `10a_sunday.ink` | 60 |
| `look_bathroom_mirror` (iter 2: «Выражение уже было отрепетировано») | `10a_sunday.ink` | 104 |
| `take_mug` (iter 2: «Она снова стоит на том же месте») | `10a_sunday.ink` | 438 |
| `look_kitchen_window` (iter 2: «Снова серая машина») | `10a_sunday.ink` | 478 |
| `take_phone` (iter 2: «Он не просто дату потерял — он откатился») | `10a_sunday.ink` | 199 |
| `leave_apartment_prompt` (iter 2: → office check) | `10a_sunday.ink` | 288 |
| `loop2_fake_wednesday_leave_for_work` | `10a_sunday.ink` | 532 |
| `loop2_fake_wednesday_work_check` | `10a_sunday.ink` | 546 |
| `loop2_return_home_after_office` | `10a_sunday.ink` | 591 |
| Iter 2 awareness в понедельник (кровать, ноутбук, умывание, окно) | `10b_monday.ink` | 59, 79, 98, 318 |
| Iter 2 awareness во вторник (спальня, зеркало, кофе) | `10c_tuesday.ink` | 47, 178, 268 |
| `tue_rooftop_loop_entry` / `tue_rooftop_loop_talk` | `rooftop_tuesday.ink` | 139, 161 |

---

## Phase 1: [1 knot] ПРИНЯТИЕ ВОСКРЕСЕНЬЯ

### Где: `10a_sunday.ink` — новый knot после `loop2_return_home_after_office`

### Что меняется
Текущий `loop2_return_home_after_office` делает:
```ink
# goto_scene:apartment_hub
```
Заменить на `-> loop2_accept_sunday`.

### Новый knot `loop2_accept_sunday`

1. Герой стоит в коридоре после возврата из офиса
2. Монолог: «Офис закрыт. Воскресенье. Снова. Ладно. Раз мир решил повторить день — я хотя бы могу прожить его иначе, а не делать вид что это ошибка календаря.»
3. `# set_flag:anomaly_interpreted=true`
4. `~ INSIGHT = INSIGHT + 1`
5. `# bg:bg_apartment_hall_day`
6. Читает сообщение от NPC (которое пришло в `loop2_fake_wednesday_work_check`)
7. Отвечает NPC
8. `# set_flag:date_agreed=true`
9. `# goto_scene:apartment_hub` → DONE

### Эффект на остальную игру
После этого флага `hall_jacket_shoes` в `apartment.lua` снова видим (условие `date_agreed`), `leave_apartment_prompt` перестаёт блокировать выход, и воскресный маршрут работает как в iter 1.

### Флаги, которые потребуются
- `anomaly_interpreted` — новый (герой принял петлю, а не отрицает)
- `date_agreed` — уже есть (сбрасывается в `loop1_to_iter2_reset`, выставляется здесь)
- `loop2_returned_home` — уже есть (выставляется в `loop2_return_home_after_office`)

---

## Phase 2: [~4 knots] ВОСКРЕСЕНЬЕ — СВИДАНИЕ С ITER 2 ОСОЗНАНИЕМ

### NPC не помнит петли
Для NPC это первое воскресенье. Диалоги те же. Герой реагирует иначе — добавляются внутренние комментарии (`# speaker:mc` или `# speaker:none`) с оттенком deja vu.

### Какие файлы и knot'ы требуют iter 2 веток

#### `cafe_sunday.ink`
| Knot | Что добавить |
|---|---|
| `sunday_date_cafe_arrival` | iter 2: «Тот же запаль кофе. Тот же свет. Она/он ещё не знает, что мы уже это проходили.» |
| `cafe_window_table` | iter 2: «Я уже сидел{mc_gender == "female":а|} за этим столом. Те же меню, те же фразы.» |
| `cafe_corner_main_talk` | iter 2: Внутренний монолог о повторении разговора |

#### `park_sunday.ink`
| Knot | Что добавить |
|---|---|
| `sunday_date_park_arrival` | iter 2: «Парк выглядит точно как в прошлый раз. Потому что это и есть прошлый раз.» |
| `park_bench_main_talk` | iter 2: deja vu в диалоге |
| `park_path_main_talk` | iter 2: deja vu в диалоге |

#### `shop_sunday.ink`
| Knot | Что добавить |
|---|---|
| `sunday_shop_arrival_pre_date` | iter 2: осознанный выбор подарка |
| `sunday_shop_arrival_with_npc` | iter 2: «Мы уже выбирали это вместе» |

#### `viewpoint_sunday.ink`
| Knot | Что добавить |
|---|---|
| `sunday_viewpoint_arrival` | iter 2 |

### Важно
- Не менять реплики NPC — они не знают о петле
- Добавлять `~ INSIGHT = INSIGHT + 1` на моменты узнавания
- Не плодить новые knot'ы — ветки внутри существующих через `{iteration_number > 1: ... - else: ...}`

---

## Phase 3: [~3 knots] ПОНЕДЕЛЬНИК — ВЫБОР СТРАТЕГИИ

### Где: `office_monday.ink`

### Что меняется
В iter 1 герой проходит офисный кейс одним маршрутом. В iter 2 герой может выбрать **другую** стратегию.

### Существующие точки выбора в `mon_office_core_choice`

Текущие варианты из `mon_office_core_choice`:
1. **Auto** — применить стандартное решение (office_standard_solution_applied)
2. **Manual** — разобрать вручную (office_clarification_requested)
3. **Stop** — заблокировать автоматическое решение (office_auto_solution_blocked)

В iter 2:
- Если в iter 1 было `auto` — в iter 2 доступен выбор `manual` или `stop`
- Если в iter 1 было `manual` — в iter 2 доступен `auto` или `stop`
- И т.д.
- Каждый выбор отличается в диалогах (герой осознанно выбирает иначе)

### Ограничение
- В iter 2 варианты, уже выбранные в iter 1, должны быть помечены (или скрыты), чтобы игрок не мог дважды выбрать одно и то же
- `meta:get:completed_strategies` в идеале — но можно проще: флаг `iter1_office_strategy` проставляется в `tue_rooftop_iter001_finish`

### Флаги
- `iter1_office_strategy = "auto" | "manual" | "stop"` — что выбрал в iter 1
- `iter2_office_strategy = "auto" | "manual" | "stop"` — что выбрал в iter 2

---

## Phase 4: [~2 knots] ВТОРНИК — ПОСЛЕДСТВИЯ ДРУГОЙ СТРАТЕГИИ

### Где: `office_tuesday.ink`, `rooftop_tuesday.ink`

### Что меняется
- Разные стратегии в понедельник → разные последствия во вторник
- Текст в `tuesday_office.ink` (расследование, лог, апелляция) меняется под стратегию iter 2
- `tue_rooftop_loop_entry` уже есть для iter 2+ — должен учитывать комбинацию `iter1_office_strategy + iter2_office_strategy`

### Варианты комбинаций
| Iter 1 | Iter 2 | Результат |
|---|---|---|
| auto | manual | Понял что стандарт не работает (→ +INSIGHT) |
| auto | stop | Увидел обе крайности (→ +INSIGHT+SYNC) |
| manual | auto | Понял что ручной разбор тоже может быть стандартом (→ +INSIGHT) |
| manual | stop | Синтез подхода (→ +INSIGHT+TRUST) |
| stop | auto/manual | Отказ от блокировки (→ +TRUST) |

---

## Phase 5: [~1-2 knots] ФИНАЛ — TRUE ENDING

### Где: `rooftop_tuesday.ink`

### Что меняется
Сейчас `tue_rooftop_loop_signal` → `-> END`. Нужен финальный экран.

### Условия ending'ов
- **True ending** (разрыв петли): `SYNC >= 2` + `INSIGHT >= 3` + `TRUST >= 2` + обе стратегии попробованы
- **NPC ending**: `TRUST > INSIGHT` (остался с человеком, но петля не раскрыта)
- **System ending**: `INSIGHT >= TRUST` (понял систему, но потерял человека)

### Новый контент
- `tue_final_epilogue` — финальный текст + credits
- `# splash:day:monday` с инвертированным смыслом (мир изменился, всё будет иначе)
- Или `# meta:set:game_completed:true`

---

## Итого: список задач (порядок выполнения)

```
Phase 1: loop2_accept_sunday knot              [10a_sunday.ink, 1 knot]
Phase 2: iter2 awareness on cafe/park date     [cafe_sunday.ink, park_sunday.ink, ~4 knots]
Phase 3: office monday iter2 choices           [office_monday.ink, ~2 knots]
Phase 4: tuesday iter2 consequences            [office_tuesday.ink, ~1 knot]
Phase 5: rooftop true ending                   [rooftop_tuesday.ink, ~2 knots]
```

Оценка: **10-12 новых/изменённых knot'ов**, ~250-400 строк ink.
