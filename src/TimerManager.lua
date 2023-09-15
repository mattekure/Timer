timerRunning = false
nCurrentTime = 0
nTimerStartTime = 0
nTimerSeconds = 0

DEFAULT_TIMER_URL = "https://mattekure.com/Timer/"
HIDE_NON_FRIENDLY = "HIDE_NON_FRIENDLY"
LOCALHOST_TIMER_URL = "http://localhost:1803"
OFF = "off"
ON = "on"
OUTPUT_TO_CHAT = "OUTPUT_TO_CHAT"
RESET_ON_TURN = "RESET_ON_TURN"
TIMER_URL = "TIMER_URL"

local tActions = {}

function onTabletopInit()
    if Session.IsHost then
        local option_entry_cycler = "option_entry_cycler"
        local option_header = "option_header_TIMER"
        local option_val_off = "option_val_off"
        OptionsManager.registerOption2(RESET_ON_TURN, false, option_header, "option_label_RESET_ON_TURN", option_entry_cycler,
            { labels = option_val_off, values = OFF, baselabel = "option_val_on", baseval = ON, default = ON })
        OptionsManager.registerOption2(TIMER_URL, false, option_header, "option_label_TIMER_URL", option_entry_cycler,
            { baselabel = "option_val_default_TIMER", baseval = DEFAULT_TIMER_URL, labels = "option_val_localhost_TIMER", values = LOCALHOST_TIMER_URL, default = DEFAULT_TIMER_URL })
        OptionsManager.registerOption2(OUTPUT_TO_CHAT, false, option_header, "option_label_OUTPUT_TO_CHAT", option_entry_cycler,
            { labels = option_val_off, values = OFF, baselabel = "option_val_on", baseval = ON, default = ON })
        OptionsManager.registerOption2(HIDE_NON_FRIENDLY, false, option_header, "option_label_HIDE_NON_FRIENDLY", option_entry_cycler,
            { labels = option_val_off, values = OFF, baselabel = "option_val_on", baseval = ON, default = ON })

        Comm.registerSlashHandler("timer", slashTimer, "[start|stop]")
        local tButton = {
            sIcon = "icon_timer",
            tooltipres = "sidebar_tooltip_timer",
            class = "timerwindow",
        }
        DesktopManager.registerSidebarToolButton(tButton, false);

		CombatManager.setCustomCombatReset(onCombatResetEvent)
        CombatManager_requestActivation = CombatManager.requestActivation
        CombatManager.requestActivation = requestActivation
    end
end

-------------------------------
--Register a timer action with parameters
--fn This is the action that will be called
--delay this is the number of seconds betwen firing.  if you want it to fire every second, put 1.  cannot be 0.  if you want to fire every 3 seconds, put 3.
--tParams this is an optional table of parameters you wish to pass to the fn when it fires.
-------------------------------
function registerTimerAction(fn, delay, tParams)
    table.insert(tActions, { fn, delay, tParams })
end

function unregisterTimerAction(fn, delay)
    for i, v in ipairs(tActions) do
        if v[1] == fn and v[2] == delay then
            tActions[i] = nil
        end
    end
end

function slashTimer(_, sParams)
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

function checkUrlOptionDefault()
    return OptionsManager.isOption(TIMER_URL, DEFAULT_TIMER_URL)
end

function checkOutputToChatOption()
    return OptionsManager.isOption(OUTPUT_TO_CHAT, ON)
end

function checkHideNonFriendlyOption()
    return OptionsManager.isOption(HIDE_NON_FRIENDLY, ON)
end

function checkResetOnTurnOption()
    return OptionsManager.isOption(RESET_ON_TURN, ON)
end

function getTimerUrl()
    if checkUrlOptionDefault() then
        return DEFAULT_TIMER_URL
    else
        return LOCALHOST_TIMER_URL
    end
end

function startTimer()
    timerRunning = true
    Interface.openURL(getTimerUrl(), startTimerLoop)
end

function startTimerLoop()
    nTimerStartTime = os.time();
    nCurrentTime = nTimerStartTime;
    loopTimer()
end

function loopTimer()
    if timerRunning then
        nCurrentTime = os.time();
        local nDiff = nCurrentTime - nTimerStartTime;
        if nDiff ~= nTimerSeconds then
            nTimerSeconds = nDiff;
            for _, v in ipairs(tActions) do
                if nTimerSeconds % v[2] == 0 then
                    if v[1] then
                        if v[3] then
                            v[1](nTimerSeconds, v[3])
                        else
                            v[1](nTimerSeconds)
                        end
                    end
                end
            end
        end
        Interface.openURL(getTimerUrl(), loopTimer)
    end
end

function getCurrentActorDisplayNameOrHidden(nodeCT)
    local sDisplayName = ActorManager.getDisplayName(nodeCT)
    if not sDisplayName or sDisplayName == "" then
        sDisplayName = "(unidentified creature)"
    end

    return sDisplayName
end

function isFriend(vActor)
	return vActor and ActorManager.getFaction(vActor) == "friend"
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
    local nodeActiveCT = _nodeCurrentActor
    if not nodeActiveCT then
        nodeActiveCT = CombatManager.getActiveCT()
    end
    local msg = {
        secret = checkHideNonFriendlyOption() and not isFriend(nodeActiveCT),
        icon = "Mattekure_Logo"
    }
    msg.text = "Actor: " .. getCurrentActorDisplayNameOrHidden(nodeActiveCT)
          .. "\nTime: " .. nHours .. "h:" .. nMins .. "m:" .. nSecs .. "s"
    Comm.deliverChatMessage(msg)
end

function outputTimeIfConfigured()
    if checkResetOnTurnOption()
        and timerRunning
        and checkOutputToChatOption() then
        outputTime(nTimerSeconds)
    end
end

function requestActivation(nodeEntry, bSkipBell)
    outputTimeIfConfigured()
	resetTimerWindowAndOptionallyRestart(true)
	CombatManager_requestActivation(nodeEntry, bSkipBell)
    _nodeCurrentActor = nodeEntry -- store current actor so we have it on combat reset which fires after current is cleared
end

function onCombatResetEvent()
    outputTimeIfConfigured()
	resetTimerWindowAndOptionallyRestart(false)
end

function resetTimerWindowAndOptionallyRestart(bStartTimer)
    if checkResetOnTurnOption() then
        if timerRunning or TimerManager.resetTimer then -- resetTimer present when timewindow showing
            TimerManager.stopTimer()
            if TimerManager.resetTimer then
                TimerManager.resetTimer()
            end

            TimerManager.nTimerStartTime = TimerManager.nCurrentTime
        end

        if bStartTimer then
            TimerManager.startTimer()
        end
    end
end
