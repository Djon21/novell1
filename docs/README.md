# Документация AVOS_S

Документация разделена на рабочие reference-файлы, практические гайды и архив миграции.

## Читать Первым

1. `../README.md`
2. `reference/CODEX_CONTEXT.md`
3. `reference/ARCHITECTURE.md`
4. `docs/guides/HOW_TO_WRITE_INK.md`
5. `reference/TODO.md`

## Reference

- `reference/ARCHITECTURE.md` — текущий runtime
- `reference/UI_MANAGER_V2_MODULES.md` — как сейчас разрезан `ui_manager_v2.script`
- `reference/CODEX_CONTEXT.md` — краткая карта проекта для новых сессий
- `reference/CONTINUE_HERE.md` — где продолжать работу
- `reference/LOOP_SYSTEM.md` — итерации и meta-state
- `reference/INVENTORY_SYSTEM.md` — инвентарь и Ink-действия предметов
- `reference/TESTING_CHECKLIST.md` — ручной QA перед релизом
- `reference/L10N_PLAN.md` — план локализации
- `reference/ROADMAP.md` — крупные направления
- `reference/TODO.md` — живые хвосты

## Guides

- `guides/HOW_TO_ADD_SCENES.md`
- `guides/HOW_TO_ADD_PORTRAITS.md`
- `guides/HOW_TO_ADD_SOUNDS.md`
- `guides/GRAPHICS_GUIDE.md`
- `guides/DESIGN_PORT_RULES.md`
- `guides/F1_HOTSPOT_EDITOR.md`
- `guides/PHONE_SYSTEM.md`
- `guides/HUB_SYSTEM.md`
- `guides/YANDEX_SDK_AND_ADS.md`

## Archive

`archive/legacy-ui/` хранит историю старого `novel_ui` и GUI-миграции. Эти файлы не являются source of truth для текущего `v2` runtime.

`archive/legacy_runtime/` содержит отключённый старый runtime. Его не используем как fallback.
