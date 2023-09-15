timerRunning = false
nCurrentTime = 0
nTimerStartTime = 0;
nTimerSeconds = 0;

DEFAULT_TIMER_URL = "https://mattekure.com/Timer/"
LOCALHOST_TIMER_URL = "http://localhost:1803"
TIMER_URL = "TIMER_URL"

local tActions = {}

function onTabletopInit()
    local option_entry_cycler = "option_entry_cycler"
    local option_header = "option_header_TIMER"
	local option_val_default = "option_val_default_TIMER"
	local option_val_localhost = "option_val_localhost_TIMER"
	OptionsManager.registerOption2(TIMER_URL, false, option_header, "option_label_TIMER_URL", option_entry_cycler,
		{ baselabel = option_val_default, baseval = DEFAULT_TIMER_URL, labels = option_val_localhost, values = LOCALHOST_TIMER_URL, default = DEFAULT_TIMER_URL })

    if Session.IsHost then
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

function checkUrlOptionDefault()
    return OptionsManager.isOption(TIMER_URL, DEFAULT_TIMER_URL)
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

function requestActivation(nodeEntry, bSkipBell)
	resetTimerWindow(true)
	CombatManager_requestActivation(nodeEntry, bSkipBell)
end

function onCombatResetEvent()
	resetTimerWindow(false)
	TimerManager.stopTimer()
end

function resetTimerWindow(bStartTimer)
	if TimerManager.resetTimer then
		TimerManager.resetTimer()
		TimerManager.nTimerStartTime = TimerManager.nCurrentTime
        if bStartTimer then
		    TimerManager.startTimer()
        end
	end
end
