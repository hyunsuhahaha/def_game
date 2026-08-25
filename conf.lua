local function isAutomatedRun()
    for _, name in ipairs({
        "LAST_HAUL_SELF_TEST", "LAST_HAUL_CAPTURE", "LAST_HAUL_CAPTURE_HARVEST", "LAST_HAUL_CAPTURE_GAME",
        "LAST_HAUL_CAPTURE_FARM", "LAST_HAUL_CAPTURE_MINE", "LAST_HAUL_CAPTURE_WALL", "LAST_HAUL_CAPTURE_REPAIR",
        "LAST_HAUL_CAPTURE_META", "LAST_HAUL_CAPTURE_RESULTS", "LAST_HAUL_CAPTURE_UPGRADE",
        "LAST_HAUL_CAPTURE_UNITS", "LAST_HAUL_CAPTURE_TEST_OPTIONS", "LAST_HAUL_CAPTURE_TURRET_PROMPT"
    }) do
        if os.getenv(name) then return true end
    end
    return false
end

function love.conf(t)
    t.identity = "last-haul"
    t.version = "11.5"
    t.console = true
    t.window.title = "LAST HAUL — 전진 보급 로비"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.minwidth = 960
    t.window.minheight = 540
    t.window.vsync = 1
    t.window.msaa = 2
    if isAutomatedRun() then t.window.visible, t.console = false, false end
end
