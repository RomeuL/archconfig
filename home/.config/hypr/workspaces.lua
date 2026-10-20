-- Workspaces por monitor:
--   1-5  sempre no monitor do notebook
--   z, x sempre no monitor externo (criados quando ele é conectado)
-- Sem monitor externo, z e x vão para o notebook e só continuam existindo
-- enquanto tiverem janelas abertas.

local laptop             = "eDP-1"
local externalWorkspaces = { "z", "x" }

for i = 1, 5 do
    hl.workspace_rule({ workspace = tostring(i), monitor = laptop, default = (i == 1) })
end

local externalRules = {}

local function findExternal()
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= laptop and not m.is_mirror then
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

attachExternal(findExternal())

-- Pequeno atraso: o Hyprland só define o workspace inicial do monitor depois do evento
hl.on("monitor.added", function ()
    hl.timer(function () attachExternal(findExternal()) end, { timeout = 200, type = "oneshot" })
end)
hl.on("monitor.removed", function () attachExternal(findExternal()) end)
