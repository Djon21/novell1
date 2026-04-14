-- story_data.lua
-- ГЛАВА 1: «ИТЕРАЦИЯ 001» (расширенная версия, ~20-30 минут)

return {
    start = "wake",
    scenes = {

-- ================================================================
-- СЦЕНА 1: ПРОБУЖДЕНИЕ + ВЫБОР ПОЛА
-- ================================================================
        wake = {
            background = { r = 0.38, g = 0.28, b = 0.18 },
            background_image = "bg_bedroom",
            nodes = {
                { type = "dialogue", character = "",
                  text = "Спальня. Рассветный свет проникает сквозь полуприкрытые жалюзи." },
                { type = "dialogue", character = "",
                  text = "На тумбочке: телефон, пустая пачка мелатонина, блокнот с обрывком формулы." },
                { type = "dialogue", character = "",
                  text = "Запись сделана твоим почерком. Но ты не помнишь, когда её написал." },
                { type = "dialogue", character = "",
                  text = "На тёмном экране монитора мигает курсор. Никаких окон — только курсор. Кто ты?" },
                { type = "choice",
                  question = "Выбери персонажа",
                  options = {
                    { text = "Артём",  gender = "male",   next = "wake_mono" },
                    { text = "Мила",   gender = "female",  next = "wake_mono" },
                  }
                },
            }
        },

-- ================================================================
-- СЦЕНА 2: УТРЕННИЙ МОНОЛОГ
-- ================================================================
        wake_mono = {
            background = { r = 0.38, g = 0.28, b = 0.18 },
            background_image = "bg_bedroom",
            next_scene = "metro",
            nodes = {
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Будильник должен сработать через три минуты. Но я уже просну{MC|лся|лась}. Опять." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Как будто тело привыкло к ритму, который я не задава{MC|л|ла}. Встаю. Холодный пол." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Зеркало в прихожей показывает уставшее лицо, которое я вроде бы знаю, но каждый день узнаю заново." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Кто я в этой цепочке? Просто руки, которые собирают чужие фрагменты? Или тот, кто однажды поймёт, зачем всё это нужно?" },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Кофе остыл за то время, пока {MC|искал|искала} чистую футболку. Кружка стоит справа, хотя я всегда ставлю её слева." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Блокнот. Обрывок формулы — явно мой почерк, но непонятно, когда это писалось. Ночью? Во сне?" },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Три непрочитанных сообщения от системы «Авось». Всё те же фрагменты кода. Даже «доброе утро» не пишут." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Третий месяц одного и того же. Получаю кусок, собираю, отправляю. Никакой архитектуры. Никакой картины целиком." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Иногда думаю — а вдруг то, что я пишу, это что-то важное? Но потом приходит следующий тикет, и мысль тонет." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "За окном просыпается город. Серый, как обычно. Машины. Огни. Кто-то куда-то спешит." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Собираюсь. Ключи, карточка метро, наушники. Один ритуал из тысячи." },
            }
        },

-- ================================================================
-- СЦЕНА 3: МЕТРО
-- ================================================================
        metro = {
            background = { r = 0.08, g = 0.09, b = 0.15 },
            next_scene = "office_morning",
            nodes = {
                { type = "dialogue", character = "",
                  text = "Утренний поток. Все смотрят в телефоны. Никто — в глаза." },
                { type = "dialogue", character = "",
                  text = "Эскалатор вниз. Запах старого металла и чего-то горелого — привычный, почти домашний." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Каждый день один и тот же маршрут. Станции уже не замечаю — просто считаю остановки." },
                { type = "dialogue", character = "",
                  text = "Вагон. Тусклый свет, отражения в стекле. Реклама курса по кибербезопасности — третью неделю подряд." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Телефон вибрирует. Уведомление от «Авось»: // PATCH temporal_sync.module" },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Работа стирает дни. Оставляет только тикеты и мерцание монитора." },
                { type = "dialogue", character = "",
                  text = "На соседнем сиденье — забытая газета. Кто-то до сих пор читает бумажные газеты." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Беру. Просто от скуки. Пробегаю взглядом заголовки — и останавливаюсь." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Дата на первой полосе. Смотрю на неё три секунды, пять, десять." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Это через четыре дня." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Достаю телефон — экран едва загружается, батарея в ноль. Сегодняшнее число. Всё правильно." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Смотрю на газету. Смотрю на телефон. Оглядываюсь — никто вокруг не реагирует. Все в своих экранах." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Типографская ошибка. Или я схожу с ума от недосыпа. Оба варианта одинаково вероятны." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Кладу газету обратно. Поезд тормозит." },
                { type = "dialogue", character = "",
                  text = "Станция «Технопарк»." },
            }
        },

-- ================================================================
-- СЦЕНА 4: ОФИС — УТРО (ДО НПС)
-- ================================================================
        office_morning = {
            background = { r = 0.12, g = 0.15, b = 0.22 },
            next_scene = "office",
            nodes = {
                { type = "dialogue", character = "",
                  text = "Лифт. Девятый этаж. Ключ-карта. Зелёный огонёк. Дверь открывается." },
                { type = "dialogue", character = "",
                  text = "Опенспейс пустой — только гул кондиционера и чей-то забытый чай на крайнем столе." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Первый. Как обычно." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Включаю рабочую станцию. Система «Авось» грузится ровно двадцать секунд. Всегда двадцать — не больше, не меньше." },
                { type = "dialogue", character = "",
                  text = "Новый тикет: «Модуль temporal_sync. Приоритет: КРИТИЧЕСКИЙ. Срок: сегодня, 16:00.»" },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Ни описания. Ни контекста. Только путь к файлу и хеш коммита." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Открываю код. И сразу что-то не так — не в логике, не в синтаксисе." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Стиль. Отступы, именование переменных, способ разбивать функции на части." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Это написано так, как пишу я. Не просто аккуратно — а мой конкретный паттерн. Мои привычки." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Но этого файла я никогда не видел." },
            }
        },

-- ================================================================
-- СЦЕНА 5: ВСТРЕЧА С НПС
-- ================================================================
        office = {
            background = { r = 0.12, g = 0.15, b = 0.22 },
            nodes = {
                { type = "dialogue", character = "",
                  text = "Дверь открывается. Голоса. Офис начинает просыпаться." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Ты опять первый. Или последний. В такие дни сложно отличить." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Система не спит. Я просто не хочу тратить сорок минут на пробки." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Или снова была бессонная ночь." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Это было не вопросом." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Нет. Есть такое лицо — когда голова ещё работает, но тело уже нет. У тебя оно сейчас." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "У меня есть специальное лицо для недосыпа?" },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Три месяца наблюдений. Уже могу классифицировать." },
                { type = "dialogue", character = "",
                  text = "Кофе появляется на столе — без вопросов, просто ставят рядом с монитором." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Ты запомнил, как я пью кофе." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Я запоминаю важные вещи." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Продакшен ждёт. Вот твой фрагмент на сегодня. Модуль temporal_sync. Не лезь в ядро. Коммит к четырём." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Без документации? Без контекста? Это как собирать пазл в темноте. И даже коробки нет." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Иногда темнота убирает лишний шум. Ты же чувствуешь это, да? Когда строка кода… отзывается. Когда она не просто работает, а… дышит." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "{NPC_NAME} говорит это так, будто уже знает, что я замети{MC|л|ла}. Вчерашний коммент в логе. Повторяющиеся фразы в чате. Спрашивать прямо… рано. Или страшно." },
                { type = "choice",
                  question = "Как ответить?",
                  options = {
                    { text = "«Ты тоже замечаешь странности?»",
                      next = "office_a", flags = { TRUST = 1, INSIGHT = 1 } },
                    { text = "«Мне просто нужно, чтобы компиляция прошла.»",
                      next = "office_b", flags = { TRUST = 1 } },
                    { text = "«Отзываться может что угодно. Даже баг.»",
                      next = "office_c", flags = { INSIGHT = 1 } },
                  }
                },
            }
        },

        office_a = {
            background = { r = 0.12, g = 0.15, b = 0.22 },
            next_scene = "compile",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Иногда мне кажется, что мы говорим на одном языке, но в разных временных зонах." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Вставляй код. Я буду рядом, если система начнёт… шептать." },
                { type = "dialogue", character = "",
                  text = "Уходит. Но оглядывается — один раз. Быстро." },
            }
        },
        office_b = {
            background = { r = 0.12, g = 0.15, b = 0.22 },
            next_scene = "compile",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Прагматично. Мне нравится. Только не забывай: даже без контекста ты оставляешь след." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "В логах. В коде. В людях." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Последнее слово прозвучало тише. Как будто не для меня." },
            }
        },
        office_c = {
            background = { r = 0.12, g = 0.15, b = 0.22 },
            next_scene = "compile",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Баги не повторяют фразы из вчерашнего дня. Баги не смотрят на тебя так, будто ждали." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Просто сделай работу. Я прослежу за логами." },
                { type = "dialogue", character = "",
                  text = "Улыбка — только краем губ. Как будто в ответе было что-то смешное. Без пояснений." },
            }
        },

-- ================================================================
-- СЦЕНА 6: КОМПИЛЯЦИЯ И ЭХО
-- ================================================================
        compile = {
            background = { r = 0.06, g = 0.08, b = 0.14 },
            nodes = {
                { type = "dialogue", character = "",
                  text = "Первый час — просто пытаюсь понять структуру. Модуль больше, чем должен быть для одного фрагмента." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Здесь есть система. Не видная целиком — но она есть. Как город с высоты: улицы не понять, но сетку чувствуешь." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Имена функций странные. process_delta, anchor_sync, rewind_state. Что это вообще должно делать?" },
                { type = "dialogue", character = "",
                  text = "Терминал. Бегущие строки лога. Низкий гул кулера." },
                { type = "dialogue", character = "",
                  text = "Строка выделяется зелёным: // TODO: fix timeline drift | author: future_self@temporal" },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "future_self@temporal. Я не писал этот комментарий. Но он здесь." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Стиль — мой. Как я форматирую строки, как называю переменные. Это версия меня, которая уже прошла этот день." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Смотрю на метку времени. Коммит сделан… завтра. В 03:47." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Газета в метро. Теперь это. Начинаю думать, что проблема не в типографии." },
                { type = "dialogue", character = "",
                  text = "Рядом появляется кружка. Кто-то поставил беззвучно, пока взгляд был в мониторе." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Ты опять задержался? Кофе закончился, пока ты добирался." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Слово в слово. Но это было до того, как я при{MC|шёл|шла}. Или голова пытается подставить это в прошлое?" },
                { type = "choice",
                  question = "Как ответить?",
                  options = {
                    { text = "«Мы уже это обсуждали. Часы вчера стояли.»",
                      next = "compile_a", flags = { INSIGHT = 1, SYNC = 1 } },
                    { text = "«Проверю коммиты. Может, кто-то пушнул без ревью.»",
                      next = "compile_b", flags = { INSIGHT = 2 } },
                    { text = "«{NPC_NAME}, ты точно в порядке?»",
                      next = "compile_c", flags = { TRUST = 1, SYNC = 1 } },
                  }
                },
            }
        },

        compile_a = {
            background = { r = 0.06, g = 0.08, b = 0.14 },
            next_scene = "talk",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Ты запомнил? Значит, нас двое. Значит, петля… не только в голове." },
                { type = "dialogue", character = "",
                  text = "Терминал: BUILD SUCCESSFUL. WARNING: temporal_anchor unstable." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Смотрим на экран. Потом друг на друга. Никто не говорит очевидного." },
            }
        },
        compile_b = {
            background = { r = 0.06, g = 0.08, b = 0.14 },
            next_scene = "talk",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Этот хеш… его нет в репозитории. Но он в истории. Код писался дважды." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Один раз — тобой. Второй — кем-то, кто уже знает, чем всё кончится." },
                { type = "dialogue", character = "",
                  text = "Терминал: BUILD SUCCESSFUL. WARNING: temporal_anchor unstable." },
            }
        },
        compile_c = {
            background = { r = 0.06, g = 0.08, b = 0.14 },
            next_scene = "talk",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Я не знаю. Но когда ты рядом, глюки… становятся тише." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Как будто реальность держится за нас, а не наоборот." },
                { type = "dialogue", character = "",
                  text = "Терминал: BUILD SUCCESSFUL. WARNING: temporal_anchor unstable." },
            }
        },

-- ================================================================
-- СЦЕНА 7: РАЗГОВОР И ТИШИНА
-- ================================================================
        talk = {
            background = { r = 0.10, g = 0.08, b = 0.20 },
            nodes = {
                { type = "dialogue", character = "",
                  text = "Конец рабочего дня. Офис пустеет. Остаётся только гул серверов и свет мониторов." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Ты остаёшься?" },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Не люблю час пик." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Или просто некуда торопиться." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Это тоже было не вопросом." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Нет. Но это был комплимент." },
                { type = "dialogue", character = "",
                  text = "{NPC_NAME} садится рядом. Не за свой стол — именно рядом. Достаточно близко, чтобы это было заметно." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Ты когда-нибудь задумывался, почему нам не дают полную архитектуру?" },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Потому что если один знает всё, система становится уязвимой. Или… потому что никто не знает всё." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Или потому что кто-то хочет, чтобы мы собирали её по частям. В реальном времени. С ошибками. С последствиями." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "{NPC_NAME} говорит слишком спокойно. Как будто это не гипотеза. Как будто это инструкция." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Три месяца. Ты ни разу не спросил, что я думаю об этом проекте." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "А что ты думаешь?" },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Что мы строим что-то важное. Настолько важное, что нам нельзя это знать." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Не пытайся поймать всё сегодня. Оставь одну переменную незакрытой. Дай ей… время. Или дай нам время." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "А если система не ждёт? Если она уже написала ответ за нас?" },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Тогда мы перепишем его вместе." },
                { type = "dialogue", character = "",
                  text = "Пауза. За окном город — огни, движение, чужие жизни." },
                { type = "choice",
                  question = "Твой ответ:",
                  options = {
                    { text = "«Оставлю. Но только если ты будешь рядом, когда система спросит.»",
                      next = "talk_a", flags = { TRUST = 2, SYNC = 1 } },
                    { text = "«Код не ждёт. Проверю ядро сегодня ночью. Один.»",
                      next = "talk_b", flags = { INSIGHT = 2, TRUST = -1 } },
                    { text = "«А что, если мы уже пробовали? И это не первый раз.»",
                      next = "talk_c", flags = { TRUST = 1, INSIGHT = 1, SYNC = 1 } },
                  }
                },
            }
        },

        talk_a = {
            background = { r = 0.10, g = 0.08, b = 0.20 },
            next_scene = "ch1_end",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Тогда я не уйду. Даже если часы снова пойдут назад." },
                { type = "dialogue", character = "",
                  text = "Не уходит. Просто остаётся — смотреть на город вместе с тобой." },
            }
        },
        talk_b = {
            background = { r = 0.10, g = 0.08, b = 0.20 },
            next_scene = "ch1_end",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Один… опасное слово. Но я не стану тебя останавливать." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Просто… оставь мне копию лога. На случай, если завтра мы проснёмся не теми." },
                { type = "dialogue", character = "",
                  text = "{NPC_NAME} смотрит дольше, чем нужно для простой просьбы." },
            }
        },
        talk_c = {
            background = { r = 0.10, g = 0.08, b = 0.20 },
            next_scene = "ch1_end",
            nodes = {
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "Значит, мы в одной лодке. Или в одной петле." },
                { type = "dialogue", character = "{NPC_NAME}",
                  text = "В любом случае… спасибо, что не отворачиваешься." },
                { type = "dialogue", character = "",
                  text = "Рука {NPC_NAME} на секунду оказывается рядом с твоей. Случайно или нет — неизвестно." },
            }
        },

-- ================================================================
-- КОНЕЦ ГЛАВЫ 1
-- ================================================================
        ch1_end = {
            background = { r = 0.0, g = 0.0, b = 0.0 },
            nodes = {
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Завтра будет тот же день. Или другой. Но что-то уже изменилось." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Газета. Коммит с завтрашней датой. Кружка не на том месте. Мелочи, которые не должны складываться." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Но они складываются. И я не хочу это стирать. Даже если придётся собирать по частям." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Даже если придётся ошибаться." },
                { type = "dialogue", character = "{MC_NAME}",
                  text = "Я буду здесь. В этой строке. В этом дне." },
                { type = "end",
                  text = "ИТЕРАЦИЯ 001 ЗАВЕРШЕНА.\n\nКликни, чтобы начать заново." },
            }
        },

    }
}
