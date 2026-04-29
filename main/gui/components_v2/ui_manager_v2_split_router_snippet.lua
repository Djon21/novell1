-- ui_manager_v2 split-router snippet
-- Put this inside on_message where "phone_app_clicked" is handled.
-- Component urls are examples; rename them to match your collection.

local APP_COMPONENTS = {
    sms    = "#phone_sms",
    call   = "#phone_call",
    map    = "#phone_map",
    notes  = "#phone_notes",
    quests = "#phone_quests",
    mail   = "#phone_mail",
    cam    = "#phone_cam",
    term   = "#phone_term",
}

local function close_all_phone_apps()
    for _, url in pairs(APP_COMPONENTS) do
        msg.post(url, "close_app")
    end
end

-- inside on_message:
if message_id == hash("phone_app_clicked") then
    close_all_phone_apps()
    local target = APP_COMPONENTS[message.id]
    if target then
        msg.post(target, "open_app")
    end
end
