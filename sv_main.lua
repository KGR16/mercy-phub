EntityModule, LoggerModule, EventsModule, CallbackModule, BlipModule, PedsModule, FunctionsModule, VehicleModule = nil, nil, nil, nil, nil, nil, nil, nil

_Ready = false
AddEventHandler('Modules/server/ready', function()
    TriggerEvent('Modules/server/request-dependencies', {
        'Callback',
        'Player',
        'Events',
    }, function(Succeeded)
        if not Succeeded then return end
        if not Succeeded then return end
        PlayerModule = exports['mercy-base']:FetchModule('Player')
        BlipModule = exports['mercy-base']:FetchModule('BlipManager')
        EntityModule = exports['mercy-base']:FetchModule("Entity")
        VehicleModule = exports['mercy-base']:FetchModule("Vehicle")
        LoggerModule = exports['mercy-base']:FetchModule('Logger')
        EventsModule = exports['mercy-base']:FetchModule('Events')
        CallbackModule = exports['mercy-base']:FetchModule('Callback')
        FunctionsModule = exports['mercy-base']:FetchModule('Functions')
        PedsModule = exports['mercy-base']:FetchModule('Peds')
        _Ready = true
    end)
end)

local dispatchCID = nil
local commanderCID = nil
local breakedOfficers = {}

local function getTableSize(t)
    local count = 0
    for _, __ in pairs(t) do
        count = count + 1
    end
    return count
end
Citizen.CreateThread(function() 
    while not _Ready do 
        Citizen.Wait(4000)
    end 
RegisterNetEvent('qb-phub:server:refresh', function(JobName)
    local src = source
    -- local Player = PlayerModule.GetPlayerBySource(src)
    local data = {}
    local count = 0
    for _, v in pairs(PlayerModule.GetPlayers()) do
        local xPlayer = PlayerModule.GetPlayerBySource(v)
        if xPlayer then
            -- if xPlayer.PlayerData.Job.Name == JobName then
            if xPlayer.PlayerData.Job.Name == "police" then
                if xPlayer.PlayerData.Job.Callsign == "TBH" then return end
                data[xPlayer.PlayerData.CitizenId] = {
                    Break = GetUnits(xPlayer.PlayerData.CitizenId, 'break'),
                    Duty = xPlayer.PlayerData.Job.Duty,
                    Radio = GetRadioChannel(v) or '?',
                    OfficerName = xPlayer.PlayerData.CharInfo.Firstname .. ' ' .. xPlayer.PlayerData.CharInfo.Lastname,
                    CallSign = xPlayer.PlayerData.Job.Callsign,
                    CitizenId = xPlayer.PlayerData.CitizenId,
                }
                TriggerClientEvent('qb-phub:client:refresh', -1, data, getTableSize(data),
                    GetUnits(xPlayer.PlayerData.CitizenId, 'dispatch'),
                    GetUnits(xPlayer.PlayerData.CitizenId, 'commander'))
            end
        end
    end
end)

RegisterNetEvent('qb-phub:server:openhub', function()
    local xPlayer = PlayerModule.GetPlayerBySource(src)
    local src = source
    if xPlayer then
        if xPlayer.PlayerData.Job.Name == "police" then
    TriggerClientEvent('qb-phub:client:open', src, 'toggle')
    end
end
end)

RegisterNetEvent('qb-phub:client:break', function(isit)
    local src = source
    local Player = PlayerModule.GetPlayerBySource(src)
    if isit then
        breakedOfficers[Player.PlayerData.CitizenId] = true
        if dispatchCID == Player.PlayerData.CitizenId then
            dispatchCID = nil
        elseif commanderCID == Player.PlayerData.CitizenId then
            commanderCID = nil
        end
        Player.Functions.SetJobDuty(false)
    else
        breakedOfficers[Player.PlayerData.CitizenId] = false
        Player.Functions.SetJobDuty(true)
    end
    Wait(50)
    TriggerEvent('qb-phub:server:refresh', Player.PlayerData.Job.Name)
end)

RegisterNetEvent('qb-phub:cl:changecallsign', function(callsign)
    local src = source
    local Player = PlayerModule.GetPlayerBySource(src)
    Player.Functions.SetMetaData("callsign", callsign)
    Wait(50)
    TriggerEvent('qb-phub:server:refresh', Player.PlayerData.Job.Name)
end)

RegisterNetEvent('qb-phub:client:dispatch', function()
    local src = source
    local Player = PlayerModule.GetPlayerBySource(src)
    local Dispatch = PlayerModule.GetPlayerByStateId(dispatchCID)
    if dispatchCID ~= Player.PlayerData.CitizenId then
        if not dispatchCID or dispatchCID == nil and not Dispatch then
            dispatchCID = Player.PlayerData.CitizenId
            Player.Functions.Notify('phub', Player.PlayerData.CharInfo.Firstname .. ' ' .. Player.PlayerData.CharInfo.Lastname .. ' Is The Dispatch Now', 'success')
        else
            Player.Functions.Notify('phub', Dispatch.PlayerData.CharInfo.Firstname .. ' ' .. Dispatch.PlayerData.CharInfo.Lastname .. ' Is The Dispatch Now', 'error')
        end
    else
        dispatchCID = nil
    end
    Wait(50)
    TriggerEvent('qb-phub:server:refresh', Player.PlayerData.Job.Name)
end)

RegisterNetEvent('qb-phub:client:commander', function()
    local src = source
    local Player = PlayerModule.GetPlayerBySource(src)
    local Commander = PlayerModule.GetPlayerByStateId(commanderCID)
    if commanderCID ~= Player.PlayerData.CitizenId then        
        if not commanderCID or commanderCID == nil and not Commander then            
            commanderCID = Player.PlayerData.CitizenId            
            Player.Functions.Notify('phub', Player.PlayerData.CharInfo.Firstname .. ' ' .. Player.PlayerData.CharInfo.Lastname .. ' Is The Commander Now', 'success')
        else            
            Player.Functions.Notify('phub', Commander.PlayerData.CharInfo.Firstname .. ' ' .. Commander.PlayerData.CharInfo.Lastname .. ' Is The Commander Now', 'error')
        end
    else        
        commanderCID = nil
    end
    Wait(50)
    TriggerEvent('qb-phub:server:refresh', Player.PlayerData.Job.Name)
end)


function GetRadioChannel(source)
    if Player(source).state['radioChannel'] then
        return Player(source).state['radioChannel']
    else
        return '?'
    end
end

function GetUnits(cid, type)
    local src = source
    local Player = PlayerModule.GetPlayerByStateId(cid)
    if type == 'dispatch' and cid == dispatchCID then
        return cid
    end
    if type == 'commander' and cid == commanderCID then
        return cid
    end
    if type == 'break' then
        if breakedOfficers[cid] == true then
            return true
        end
    end
    return false
end
end)