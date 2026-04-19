-- v2_theme.lua
-- Центральная палитра и типографика для v2-UI.
-- Используется всеми компонентами из main/gui/components_v2/.
--
-- Источник правды — CSS-токены из mobile-макетов AVOS (Downloads/AVOS (14)/*_mobile.html).

local M = {}

-- ============================================================
-- Хелпер: #RRGGBB → vmath.vector4
-- ============================================================
local function rgb(hex, alpha)
    alpha = alpha or 1.0
    local r = tonumber(hex:sub(2, 3), 16) / 255
    local g = tonumber(hex:sub(4, 5), 16) / 255
    local b = tonumber(hex:sub(6, 7), 16) / 255
    return vmath.vector4(r, g, b, alpha)
end

-- ============================================================
-- COLORS — палитра (CSS custom props → vmath.vector4)
-- ============================================================
M.COLORS = {
    -- тёмный фон (слои инта)
    ink_0        = rgb("#07061a"),
    ink_1        = rgb("#0c0a24"),
    ink_2        = rgb("#171232"),
    frame        = rgb("#221947"),

    -- основной текст (бежевая бумага)
    paper        = rgb("#f3ecd9"),
    paper_soft   = rgb("#f3ecd9", 0.7),
    paper_medium = rgb("#f3ecd9", 0.5),
    paper_dim    = rgb("#c9c0a8"),
    paper_faint  = rgb("#f3ecd9", 0.3),

    -- акценты
    accent       = rgb("#7df9ff"),  -- cyan / --accent
    accent_soft  = rgb("#7df9ff", 0.7),
    accent_dim   = rgb("#7df9ff", 0.3),

    accent_hot   = rgb("#ff3d7f"),  -- magenta / --accent-hot
    amber        = rgb("#ffb347"),
    violet       = rgb("#7a5cff"),
    stamp        = rgb("#c8142a"),  -- красная печать

    -- вспомогательные
    crt_green    = rgb("#5aff7a"),  -- CRT-режим нарратора в диалоге
    black        = rgb("#000000"),
    transparent  = vmath.vector4(0, 0, 0, 0),
}

-- Доступ по ключу из скриптов (M.color("accent_hot"))
function M.color(name)
    return M.COLORS[name] or M.COLORS.paper
end

-- ============================================================
-- FONTS — имена как объявлены в .gui компонентах (через add font)
-- Все компоненты v2 должны добавлять эти шрифты с ОДИНАКОВЫМИ именами.
-- ============================================================
M.FONTS = {
    -- JetBrains Mono — UI/технический текст
    mono_10       = "jb_mono_10",
    mono_12       = "jb_mono_12",
    mono_14       = "jb_mono_14",
    mono_18       = "jb_mono_18",
    mono_bold_14  = "jb_mono_bold_14",
    mono_bold_22  = "jb_mono_bold_22",
    mono_stamp    = "jb_mono_stamp",

    -- Unbounded — крупные заголовки/кнопки
    title_20      = "unbounded_bold_20",
    title_32      = "unbounded_bold_32",
    title_72      = "unbounded_black_72",

    -- Caveat — рукописные ремарки ("заметка на полях")
    caveat_18     = "caveat_18",
    caveat_28     = "caveat_28",

    -- Manrope — длинный текст (описания, диалоги)
    body_14       = "manrope_14",
    body_16       = "manrope_16",

    -- Material Icons — глифы для кнопок (рюкзак, телефон, etc.)
    icons         = "icons",
}

-- ============================================================
-- ROLES — семантические комбинации (font + color + size)
-- Применяются через M.apply(node, "role_name").
-- ============================================================
M.ROLES = {
    -- крупные заголовки экранов ("ПРИХОЖАЯ", "АВОСЬ")
    title       = { font = M.FONTS.title_32,     color = M.COLORS.paper },
    title_large = { font = M.FONTS.title_72,     color = M.COLORS.paper },

    -- кнопки меню (Новая итерация, Продолжить)
    button      = { font = M.FONTS.title_20,     color = M.COLORS.paper },

    -- обычный текст (диалоги, описания предметов)
    body        = { font = M.FONTS.body_16,      color = M.COLORS.paper },
    body_small  = { font = M.FONTS.body_14,      color = M.COLORS.paper_soft },

    -- моно (HUD, таймеры, технические числа)
    mono        = { font = M.FONTS.mono_12,      color = M.COLORS.paper_soft },
    mono_small  = { font = M.FONTS.mono_10,      color = M.COLORS.paper_medium },
    mono_accent = { font = M.FONTS.mono_12,      color = M.COLORS.accent },

    -- eyebrow — надтекст над заголовком ("visual · novel · dossier")
    eyebrow     = { font = M.FONTS.mono_10,      color = M.COLORS.accent },

    -- caveat — рукописные ремарки (амбер)
    caveat      = { font = M.FONTS.caveat_18,    color = M.COLORS.amber },
    caveat_big  = { font = M.FONTS.caveat_28,    color = M.COLORS.amber },

    -- штамп "СЕКРЕТНО" (красный с наклоном)
    stamp       = { font = M.FONTS.mono_stamp,   color = M.COLORS.stamp },

    -- hint внизу кнопки/опции ("-2 xp", "+след")
    hint_hot    = { font = M.FONTS.mono_10,      color = M.COLORS.accent_hot },
    hint_amber  = { font = M.FONTS.mono_10,      color = M.COLORS.amber },
    hint_violet = { font = M.FONTS.mono_10,      color = M.COLORS.violet },
    hint_cyan   = { font = M.FONTS.mono_10,      color = M.COLORS.accent },
}

-- Применить роль к текст-ноде.
-- Использование: theme.apply(gui.get_node("title"), "title")
function M.apply(node, role_name)
    local role = M.ROLES[role_name]
    if not role then
        print("[v2_theme] unknown role: " .. tostring(role_name))
        return
    end
    gui.set_font(node, role.font)
    gui.set_color(node, role.color)
end

-- ============================================================
-- LAYOUT — константы раскладки под 960×640 (альбомная)
-- ============================================================
M.LAYOUT = {
    screen_w = 960,
    screen_h = 640,

    -- HUD-полосы
    hud_strip_h = 32,   -- высота верхней/нижней полосы
    hud_padding = 14,   -- внутренний отступ

    -- углы (corner brackets)
    corner_size    = 22,
    corner_margin  = 14,

    -- кнопки меню
    menu_btn_w = 360,
    menu_btn_h = 48,
    menu_gap   = 10,

    -- nav-buttons (круги W/N/E/S)
    nav_btn_size = 112,

    -- портрет в диалоге
    portrait_size = 96,

    -- inventory slot
    inv_slot_size = 96,
    inv_cols      = 4,
    inv_rows      = 3,
}

-- ============================================================
-- Анимационные пресеты — длительность/easing для gui.animate
-- ============================================================
M.ANIM = {
    fade_in_fast  = { duration = 0.25, easing = gui.EASING_OUTCUBIC },
    fade_in_slow  = { duration = 0.7,  easing = gui.EASING_OUTCUBIC },
    hover         = { duration = 0.18, easing = gui.EASING_OUTQUAD  },
    click_press   = { duration = 0.08, easing = gui.EASING_OUTQUAD  },
}

return M
