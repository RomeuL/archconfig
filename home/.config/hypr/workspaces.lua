-- Workspaces por monitor:
--   1-5  sempre no monitor principal, mesmo vazios: a tela do notebook ou, num PC
--        de mesa (sem a saída eDP-1), o primeiro monitor conectado
--   z, x sempre no monitor externo (criados quando ele é conectado)
-- Sem monitor externo, z e x vão para o principal e só continuam existindo
-- enquanto tiverem janelas abertas.

local laptop             = "eDP-1"
local externalWorkspaces = { "z", "x" }

-- A saída do notebook existe mesmo com a tela desligada; num PC de mesa, não
local function hasLaptopScreen()
    for card = 0, 9 do
        local f = io.open("/sys/class/drm/card" .. card .. "-" .. laptop .. "/status")
        if f then
            f:close()
            return true
        end
    end
    return false
end

local isLaptop = hasLaptopScreen()

-- Persistentes: o Hyprland mantém 1-5 abertos e o Waybar mostra todos
local function mainRule(i, monitor)
    return hl.workspace_rule({
        workspace  = tostring(i),
        monitor    = monitor,
        persistent = true,
        default    = (i == 1),
    })
end

-- No notebook as regras de 1-5 são fixas; no PC de mesa seguem o monitor principal (attachMain)
if isLaptop then
    for i = 1, 5 do
        mainRule(i, laptop)
    end
end

local mainRules     = {}
local externalRules = {}

local function findMain()
    if isLaptop then return laptop end
    for _, m in ipairs(hl.get_monitors()) do
        if not m.is_mirror then
            return m.name
        end
    end
end

local function findExternal()
    local main = findMain()
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= main and not m.is_mirror then
            return m.name
        end
    end
end

local function findWorkspace(name)
    for _, ws in ipairs(hl.get_workspaces()) do
        if ws.name == name then
            return ws
        end
    end
end

local function isExternalWorkspace(ws)
    for _, name in ipairs(externalWorkspaces) do
        if ws and ws.name == name then
            return true
        end
    end
    return false
end

-- Traz z/x que estavam no notebook e faz o monitor externo mostrar z
local function placeExternalWorkspaces(monitor)
    local m = hl.get_monitor(monitor)
    if not m then return end

    for _, name in ipairs(externalWorkspaces) do
        local ws = findWorkspace(name)
        if ws and ws.monitor and ws.monitor.name ~= monitor then
            hl.dispatch(hl.dsp.workspace.move({ workspace = "name:" .. name, monitor = monitor }))
        end
    end

    -- Focar em z faz o monitor externo mostrá-lo; depois o foco volta para onde estava
    if not isExternalWorkspace(m.active_workspace) then
        local previous = hl.get_active_monitor()
        hl.dispatch(hl.dsp.focus({ workspace = "name:" .. externalWorkspaces[1] }))
        if previous and previous.name ~= monitor then
            hl.dispatch(hl.dsp.focus({ monitor = previous.name }))
        end
    end
end

-- No PC de mesa, prende 1-5 ao monitor principal (ou solta, se monitor == nil)
local function attachMain(monitor)
    for _, rule in ipairs(mainRules) do
        rule:set_enabled(false)
    end
    mainRules = {}

    if not monitor then return end

    for i = 1, 5 do
        mainRules[#mainRules + 1] = mainRule(i, monitor)
    end
end

-- Prende z e x ao monitor externo (ou solta, se monitor == nil)
local function attachExternal(monitor)
    for _, rule in ipairs(externalRules) do
        rule:set_enabled(false)
    end
    externalRules = {}

    if not monitor then return end

    for i, name in ipairs(externalWorkspaces) do
        externalRules[#externalRules + 1] = hl.workspace_rule({
            workspace  = "name:" .. name,
            monitor    = monitor,
            persistent = true,
            default    = (i == 1),
        })
    end

    -- O Hyprland só cria os workspaces persistentes no ciclo seguinte
    hl.timer(function () placeExternalWorkspaces(monitor) end, { timeout = 200, type = "oneshot" })
end

local function attachAll()
    if not isLaptop then attachMain(findMain()) end
    attachExternal(findExternal())
end

attachAll()

-- Pequeno atraso: o Hyprland só define o workspace inicial do monitor depois do evento
hl.on("monitor.added", function ()
    hl.timer(attachAll, { timeout = 200, type = "oneshot" })
end)
hl.on("monitor.removed", attachAll)
