local timerRunning = false
local nCurrentTime = 0
local nTimerStartTime = 0;
local nTimerSeconds = 0;

local tActions = {}

function onTabletopInit()
    if Session.IsHost then
        Comm.registerSlashHandler("timer", slashTimer, "[start|stop]")

        local tButton = {
            sIcon = "icon_timer",
            tooltipres = "sidebar_tooltip_timer",
            class = "timerwindow",
        }
        DesktopManager.registerSidebarToolButton(tButton, false);
    end
end

function registerTimerAction(fn, delay)
    table.insert(tActions, { fn, delay })
end

function unregisterTimerAction(fn, delay)
    for i, v in ipairs(tActions) do
        if v[1] == fn and v[2] == delay then
            tActions[i] = nil
        end
    end
end

function slashTimer(sCommand, sParams)
    if sParams == "start" then
        startTimer()
    elseif sParams == "stop" then
        stopTimer()
    else
        local msg = {}
        msg.text = "Usage /timer [start|stop]"
        Comm.addChatMessage(msg)
    end
end

function stopTimer()
    timerRunning = false
end

function startTimer()
    timerRunning = true
    Interface.openURL("http://0.0.0.0/", startTimerLoop)
end

function startTimerLoop(url, response)
    nTimerStartTime = os.time();
    nCurrentTime = nTimerStartTime;
    loopTimer()
end

function loopTimer(url, response)
    if timerRunning then
        nCurrentTime = os.time();
        local nDiff = nCurrentTime - nTimerStartTime;
        if nDiff ~= nTimerSeconds then
            nTimerSeconds = nDiff;
            for _, v in ipairs(tActions) do
                if nTimerSeconds % v[2] == 0 then
                    if v[1] then
                        v[1](nTimerSeconds)
                    end
                end
            end
        end
        Interface.openURL("http://0.0.0.0", loopTimer)
    end
end

function outputTime(nTime)
    local nHours = math.floor(nTime / 3600)
    local nLeft = math.floor(nTime % 3600)
    local nMins = math.floor(nLeft / 60)
    local nSecs = math.floor(nTime % 60)
    if nHours >= 0 and nHours <= 9 then
        nHours = "0" .. nHours
    end
    if nMins >= 0 and nMins <= 9 then
        nMins = "0" .. nMins
    end
    if nSecs >= 0 and nSecs <= 9 then
        nSecs = "0" .. nSecs
    end
    local msg = {}
    msg.text = nHours .. ":" .. nMins .. ":" .. nSecs
    Comm.deliverChatMessage(msg)
end
