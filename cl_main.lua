EntityModule, LoggerModule, EventsModule, CallbackModule, BlipModule, PedsModule, FunctionsModule, VehicleModule = nil, nil, nil, nil, nil, nil, nil, nil

local _Ready = false
AddEventHandler('Modules/client/ready', function()
    if not _Ready then
        _Ready = true
    end
    TriggerEvent('Modules/client/request-dependencies', {
        'Events',
        'Entity',
        'Logger',
        'Callback',
        'Functions',
        'BlipManager',
        'Player',
        'Vehicle',
        'Peds',
    }, function(Succeeded)
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
    end)
end)

local Enabled = false
local Break = false
local ChatArray = {}

Citizen.CreateThread(function() 
    while not _Ready do 
        Citizen.Wait(4000)
    end 

    CreateThread(function()
        while true do
            Wait(10000)
            local Player = PlayerModule.GetPlayerData()
            if Player.Job == nil then return end
            TriggerServerEvent('qb-phub:server:refresh', Player.Job.Name)
        end
    end)

    -- Events

    RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
        if Enabled then
            local Player = PlayerModule.GetPlayerData()
            if Player == nil then return end
            if Player.Job.Name == nil then return end
            if Player.Job.Name ~= "police" or Player.Job.Name ~= "EMS" then
                SendNUIMessage({ 
                    action = "close";
                    Job = PlayerModule.GetPlayerData().Job.Name;
                })
            end
        end
    end)

    RegisterNetEvent("qb-phub:client:open", function(type)
        if type == 'toggle' then
            if Enabled then
                Enabled = false
                SendNUIMessage({ 
                    action = "close";
                    Job = PlayerModule.GetPlayerData().Job.Name;
                })
            else
                Enabled = true
                SendNUIMessage({ 
                    action = "open"; 
                    Job = PlayerModule.GetPlayerData().Job.Name;
                    duty = PlayerModule.GetPlayerData().Job.Duty;
                    Cid = PlayerModule.GetPlayerData().CitizenId;
                })
            end
        elseif type == 'drag' then
            SetNuiFocus(true, true)
            SendNUIMessage({ 
                action = "drag";
                Job = PlayerModule.GetPlayerData().Job.Name;
                duty = PlayerModule.GetPlayerData().Job.Duty;
                Cid = PlayerModule.GetPlayerData().CitizenId;
            })
        end
    end)

    local Job = nil
    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        Job = PlayerModule.GetPlayerData().Job
    end)

    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        SendNUIMessage({ 
            action = "close";
            Job = PlayerModule.GetPlayerData().Job.Name;
        })
    end)

    AddEventHandler('onResourceStart', function(resourceName)
        if GetCurrentResourceName() == resourceName then
            Job = PlayerModule.GetPlayerData().Job
        end
    end)

    RegisterNetEvent("qb-phub:client:refresh", function(data, PoliceCount, DispatchCid, CommanderCid)
        local sendDispatchCid = DispatchCid or nil

        SendNUIMessage({ 
            action = 'refresh', 
            data = data, 
            title = PoliceCount;
            ComCid = CommanderCid;
            DisCid = sendDispatchCid;
            Job = PlayerModule.GetPlayerData().Job ~= nil and PlayerModule.GetPlayerData().Job.Name;
            duty = PlayerModule.GetPlayerData().Job ~= nil and PlayerModule.GetPlayerData().Job.Duty;
            Cid = PlayerModule.GetPlayerData().CitizenId;
        })
    end)

    -- RegisterNUICallback
    RegisterNUICallback("Close", function()
        SetNuiFocus(false, false)
    end)
    RegisterNUICallback("Close2", function()
        SendNUIMessage({ 
            action = "close";
        })
        SetNuiFocus(false, false)
    end)
    RegisterNetEvent('mercy-base/client/on-logout', function()
        SendNUIMessage({ 
            action = "close";
        })
    end)

    -- RegisterNUICallback("EmptyChat", function(data, cb)
    --     print("NUICallback: EmptyChat, data:", data)
    --     if data ~= nil then
    --         TriggerServerEvent('momo-phub:EmptyChat', data)
    --     end
    -- end)

    -- RegisterNUICallback("SendMessage", function(data, cb)
    --     print("NUICallback: SendMessage, data:", data)
    --     if data ~= nil then
    --         TriggerServerEvent('momo-phub:SendChat', data)
    --     end
    -- end)

    -- RegisterNetEvent("momo-phub:UpdateChat", function(data)
    --     print("Event: momo-phub:UpdateChat")
    --     SendNUIMessage({
    --         action = 'UpdateChat';
    --         Chat = data;
    --         Job = PlayerModule.GetPlayerData().Job.Name;
    --     })
    -- end)

    -- RegisterNetEvent("momo-phub:EmptyChat", function(data)
    --     print("Event: momo-phub:EmptyChat")
    --     SendNUIMessage({
    --         action = 'EmptyChat';
    --         Chat = data;
    --         Job = PlayerModule.GetPlayerData().Job.Name;
    --     })
    -- end)

    RegisterNUICallback("onduty", function()
        
        local Player = PlayerModule.GetPlayerData()
        local PlayerJob = Player.Job
        local newState
        
        if PlayerJob.Name == "police" then
            if Player.Job.Duty then
                newState = false
            else
                newState = true
            end
            TriggerServerEvent('mercy-base/server/set-duty', { State = newState })
            TriggerServerEvent("qb-phub:sv:refresh", "police")
        else
            if Player.Job.Duty then
                newState = false
            else
                newState = true
            end
            TriggerServerEvent('mercy-base/server/set-duty', { State = newState })
            TriggerServerEvent("qb-phub:sv:refresh", "EMS")
        end
    end)
    

    RegisterNUICallback("break", function()
        Break = not Break
        LocalPlayer.state.Breakhub = Break
        TriggerServerEvent("qb-phub:client:break", Break)
    end)

    RegisterNUICallback("dispatch", function()
        TriggerServerEvent("qb-phub:client:dispatch")
    end)

    RegisterNUICallback("commander", function()
        TriggerServerEvent("qb-phub:client:commander")
    end)

    RegisterNUICallback("changecallsign", function(data)
        TriggerServerEvent("qb-phub:cl:changecallsign", data.callsign)
    end)

    RegisterNUICallback('notify', function(data)
        exports['mercy-ui']:Notify("phub", data.why, 'error', "5000")
    end)

    RegisterKeyMapping("phub", "Toggle Job list", 'keyboard', "EQUALS")
    RegisterCommand('phub', function()
        
        local Player = PlayerModule.GetPlayerData()
        
        PlayerJob = PlayerModule.GetPlayerData().Job
        
        if PlayerJob.Name == "police" then
            
            Enabled = true
            
            TriggerServerEvent('qb-phub:server:refresh', Player.Job.Name)
            
            SetNuiFocus(true, true)
            
            SendNUIMessage({
                action = "drag",
                Job = PlayerModule.GetPlayerData().Job.Name,
                duty = PlayerModule.GetPlayerData().Job.Duty,
            })
        else
        end
    end)
    

end)
