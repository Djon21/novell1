-- main/scripts/state/bank.lua
-- Lightweight bank/balance state. Ink should request charges; Lua owns
-- balance math and generates bank SMS text with the current remainder.

local M = {}

local DEFAULT_CARD = "*4821"
local DEFAULT_BALANCE = 272229

local notify_cb = function() end
local add_sms_cb = function(_contact, _text, _opts) end

local _balance = DEFAULT_BALANCE
local _card = DEFAULT_CARD

function M.set_deps(deps)
    if deps.notify then notify_cb = deps.notify end
    if deps.add_sms then add_sms_cb = deps.add_sms end
end

local function format_money(amount)
    amount = math.floor(tonumber(amount) or 0)
    local sign = amount < 0 and "-" or ""
    local s = tostring(math.abs(amount))
    local chunks = {}
    while #s > 3 do
        table.insert(chunks, 1, s:sub(-3))
        s = s:sub(1, -4)
    end
    table.insert(chunks, 1, s)
    return sign .. table.concat(chunks, " ")
end

function M.reset()
    _balance = DEFAULT_BALANCE
    _card = DEFAULT_CARD
end

function M.set_balance(amount)
    local parsed = tonumber(amount)
    _balance = math.floor(parsed ~= nil and parsed or DEFAULT_BALANCE)
    notify_cb()
end

function M.get_balance()
    return _balance
end

function M.charge(amount, merchant, opts)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return false end
    merchant = tostring(merchant or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if merchant == "" then merchant = "Покупка" end

    _balance = _balance - amount
    local text = ("Карта %s: списание %s ₽. %s. Баланс %s ₽."):format(
        _card,
        format_money(amount),
        merchant,
        format_money(_balance)
    )
    add_sms_cb("bank", text, opts)
    notify_cb()
    return true
end

function M.serialize()
    return {
        bank = {
            balance = _balance,
            card = _card,
        },
    }
end

function M.deserialize(data)
    local bank = type(data) == "table" and data.bank or nil
    if type(bank) == "table" then
        local parsed = tonumber(bank.balance)
        _balance = math.floor(parsed ~= nil and parsed or DEFAULT_BALANCE)
        _card = bank.card and tostring(bank.card) or DEFAULT_CARD
    else
        _balance = DEFAULT_BALANCE
        _card = DEFAULT_CARD
    end
end

function M.format_money(amount)
    return format_money(amount)
end

return M
