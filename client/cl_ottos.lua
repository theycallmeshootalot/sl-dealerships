QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then 
        PlayerJob = QBCore.Functions.GetPlayerData().job 
        CrownsPed()
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    CrownsPed()
end)

AddEventHandler('onResourceStop', function(resourceName) 
	if GetCurrentResourceName() == resourceName then
        DeletePed(CrownsPed())
	end 
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

local function DrawText3D(x, y, z, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

CreateThread(function()
    local blip = AddBlipForCoord(Config.OttosPedLocation.x, Config.OttosPedLocation.y, Config.OttosPedLocation.z)
    SetBlipSprite(blip, 811)
    SetBlipColour(blip, 59)
    SetBlipScale(blip, 0.9)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.OttosBlipName)
    EndTextCommandSetBlipName(blip)
end)

RegisterNetEvent('sl-dealerships:client:spawnSellingVehicle', function(data)
    local vehicle = data.vehicle.model
    local vehiclename = data.vehicle.name
    local location = Config.OttosVehicleSpawn
 
    if QBCore.Functions.SpawnClear(vector3(location.x, location.y, location.z), 2.0) then
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetVehicleEngineOn(veh, true)
            exports['LegacyFuel']:SetFuel(veh, 100.0)
        end, vehicle, location, false)
    else
        QBCore.Functions.Notify('The area to bring in the '..vehiclename.." isn't clear, remove all vehicles or players out of the area", 'error')
    end
end)

RegisterNetEvent('sl-dealerships:client:spawnTestDriveVehicle', function(data)
    local vehicle = data.vehicle.model
    local vehiclename = data.vehicle.name
    local location = Config.OttosVehicleSpawn

    if QBCore.Functions.SpawnClear(vector3(location.x, location.y, location.z), 2.0) then
        QBCore.Functions.Notify('You have registered the '..vehiclename.." as a test-drive vehicle, when done return the vehicle", 'info')
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            local veh = NetToVeh(netId)
            SetVehicleEngineOn(veh, true)
            exports['LegacyFuel']:SetFuel(veh, 100.0)
        end, vehicle, location, false)
    else
        QBCore.Functions.Notify('The area to bring in the '..vehiclename.." isn't clear, remove all vehicles or players out of the area", 'error')
    end

    CreateThread(function()
        while true do
            Wait(0)
            local position = GetEntityCoords(PlayerPedId())
            local distance = #(position - vector3(Config.OttosTestDriveReturn.x, Config.OttosTestDriveReturn.y, Config.OttosTestDriveReturn.z))
            if distance < 5 then
                DrawText3D(Config.OttosTestDriveReturn.x, Config.OttosTestDriveReturn.y, Config.OttosTestDriveReturn.z, "Press [E] to return test-drive vehicle")
                if IsControlJustReleased(0, 38) then
                    if IsPedInAnyVehicle(PlayerPedId()) then
                        DeleteVehicle(GetVehiclePedIsIn(PlayerPedId()))
                        QBCore.Functions.Notify('You have returned the '..vehiclename, 'info')
                        return false
                    else
                        QBCore.Functions.Notify('You are not in a vehicle used for your workplace', 'error')
                        return false
                    end
                end
            end
        end
    end)
end)

-- SELLING VEHICLE --

RegisterNetEvent('sl-dealerships:client:sellavehiclemenu', function(data)
    local SellVehicleMenu = {
        {
            icon = "fas fa-car",
            header = PlayerJob.label.. " | Select Nearest Customer",
            isMenuHeader = true
        },
    }
    QBCore.Functions.TriggerCallback('sl-dealerships:server:getnearestplayer', function(players)
        for _, vp in pairs(players) do
            if vp and vp ~= PlayerId() then
                SellVehicleMenu[#SellVehicleMenu + 1] = {
                    header = vp.name,
                    txt = "Player ID: " ..vp.sourceplayer,
                    icon = "fa-solid fa-user-check",
                    params = {
                        event = "sl-dealerships:client:sellvehiclecategories",
                        args = {
                            target = vp.sourceplayer
                        }
                    }
                }
            end
        end

        SellVehicleMenu[#SellVehicleMenu+1] = {
            icon = "fas fa-x",
            header = "Close",
            txt = "",
            params = {
                event = "sl-dealerships:client:close"
            }
        }

        exports['qb-menu']:openMenu(SellVehicleMenu)
    end)
end)

RegisterNetEvent('sl-dealerships:client:sellvehiclecategories', function(data)
    local brandsmenu = {}
    local SellVehicle = {
        {
            icon = "fas fa-car",
            header = PlayerJob.label.. " | Vehicle Brands",
            isMenuHeader = true
        },
    }
    for k, v in pairs(QBCore.Shared.Vehicles) do
        if type(QBCore.Shared.Vehicles[k]["shop"]) == 'table' then
            for _, shop in pairs(QBCore.Shared.Vehicles[k]["shop"]) do
                if shop == Config.OttosShopName then 
                    brandsmenu[v.brand] = v.brand
                    
                end
            end
        elseif QBCore.Shared.Vehicles[k]["shop"] == Config.OttosShopName then
            brandsmenu[v.brand] = v.brand
        end
    end

    for k, v in pairs(brandsmenu) do
        SellVehicle[#SellVehicle + 1] = {
            header = v,
            icon = "fa-solid fa-circle",
            params = {
                event = "sl-dealerships:client:sellvehiclelist",
                args = {
                    vehiclename = k,
                    player = vp
                }
            }
        }
    end

        SellVehicle[#SellVehicle+1] = {
            icon = "fa-solid fa-x",
            header = "Exit",
            params = {
                event = "sl-dealerships:client:close"
            }
        }
    exports['qb-menu']:openMenu(SellVehicle)
end)

RegisterNetEvent('sl-dealerships:client:sellvehiclelist', function(data)
    local SellVehicleList = {
        {
            icon = "fas fa-car",
            header = PlayerJob.label.. " | Vehicle Selection",
            isMenuHeader = true
        },
    }
    for k, v in pairs(QBCore.Shared.Vehicles) do
        if QBCore.Shared.Vehicles[k]["brand"] == data.vehiclename then
            if type(QBCore.Shared.Vehicles[k]["shop"]) == 'table' then
                for _, shop in pairs(QBCore.Shared.Vehicles[k]["shop"]) do
                    if shop == Config.OttosShopName then
                        SellVehicleList[#SellVehicleList + 1] = {
                            header = v.name,
                            txt = "Price: $"..v.price,
                            icon = "fa-solid fa-car-side",
                            params = {
                                event = 'sl-dealerships:client:spawnSellingVehicle',
                                args = {
                                    vehicle = v,
                                    --target = data.player.sourceplayer
                                }
                            }
                        }
                    end
                end
            elseif QBCore.Shared.Vehicles[k]["shop"] == Config.OttosShopName then
                SellVehicleList[#SellVehicleList + 1] = {
                    header = v.name,
                    txt = "Price: $"..v.price,
                    icon = "fa-solid fa-car-side",
                    params = {
                        event = 'sl-dealerships:client:spawnSellingVehicle',
                        args = {
                            vehicle = v,
                            --target = data.player.sourceplayer
                        }
                    }
                }
            end
        end
    end

    SellVehicleList[#SellVehicleList+1] = {
            icon = "fa-solid fa-angle-left",
            header = "Return",
            params = {
                event = "sl-dealerships:client:sellvehiclecategories"
            }
        }
    exports['qb-menu']:openMenu(SellVehicleList)
end)

-- TEST DRIVE VEHICLES --

RegisterNetEvent('sl-dealerships:client:testvehiclecategories', function(data)
    local testbrandsmenu = {}
    local SellVehicle = {
        {
            icon = "fas fa-car",
            header = PlayerJob.label.. " | Test-Drive Brand Selection",
            isMenuHeader = true
        },
    }
    for k, v in pairs(QBCore.Shared.Vehicles) do
        if type(QBCore.Shared.Vehicles[k]["shop"]) == 'table' then
            for _, shop in pairs(QBCore.Shared.Vehicles[k]["shop"]) do
                if shop == Config.OttosShopName then 
                    testbrandsmenu[v.brand] = v.brand
                    
                end
            end
        elseif QBCore.Shared.Vehicles[k]["shop"] == Config.OttosShopName then
            testbrandsmenu[v.brand] = v.brand
        end
    end

    for k, v in pairs(testbrandsmenu) do
        SellVehicle[#SellVehicle + 1] = {
            header = v,
            icon = "fa-solid fa-circle",
            params = {
                event = "sl-dealerships:client:testvehiclelist",
                args = {
                    vehiclename = k
                }
            }
        }
    end

        SellVehicle[#SellVehicle+1] = {
            icon = "fa-solid fa-x",
            header = "Exit",
            params = {
                event = "sl-dealerships:client:close"
            }
        }
    exports['qb-menu']:openMenu(SellVehicle)
end)

RegisterNetEvent('sl-dealerships:client:testvehiclelist', function(data)
    local TestDriveVehicleList = {
        {
            icon = "fas fa-car",
            header = PlayerJob.label.. " | Test-Drive Vehicle Selection",
            isMenuHeader = true
        },
    }
    for k, v in pairs(QBCore.Shared.Vehicles) do
        if QBCore.Shared.Vehicles[k]["brand"] == data.vehiclename then
            if type(QBCore.Shared.Vehicles[k]["shop"]) == 'table' then
                for _, shop in pairs(QBCore.Shared.Vehicles[k]["shop"]) do
                    if shop == Config.OttosShopName then
                        TestDriveVehicleList[#TestDriveVehicleList + 1] = {
                            header = v.name,
                            txt = "Price: $"..v.price,
                            icon = "fa-solid fa-car-side",
                            params = {
                                event = 'sl-dealerships:client:spawnTestDriveVehicle',
                                args = {
                                    vehicle = v,
                                }
                            }
                        }
                    end
                end
            elseif QBCore.Shared.Vehicles[k]["shop"] == Config.OttosShopName then
                TestDriveVehicleList[#TestDriveVehicleList + 1] = {
                    header = v.name,
                    txt = "Price: $"..v.price,
                    icon = "fa-solid fa-car-side",
                    params = {
                        event = 'sl-dealerships:client:spawnTestDriveVehicle',
                        args = {
                            vehicle = v,
                        }
                    }
                }
            end
        end
    end

    TestDriveVehicleList[#TestDriveVehicleList+1] = {
            icon = "fa-solid fa-angle-left",
            header = "Return",
            params = {
                event = "sl-dealerships:client:testvehiclecategories"
            }
        }
    exports['qb-menu']:openMenu(TestDriveVehicleList)
end)

function CrownsPed()
    if not DoesEntityExist(ottosmodel) then
        RequestModel(Config.OttosPed)
        while not HasModelLoaded(Config.OttosPed) do
            Wait(0)
        end

        ottosmodel = CreatePed(1, Config.OttosPed, Config.OttosPedLocation.x, Config.OttosPedLocation.y, Config.OttosPedLocation.z, Config.OttosPedLocation.w, false, false)
        SetEntityAsMissionEntity(ottosmodel)
        SetBlockingOfNonTemporaryEvents(ottosmodel, true)
        SetEntityInvincible(ottosmodel, true)
        FreezeEntityPosition(ottosmodel, true)
        TaskStartScenarioInPlace(ottosmodel, "WORLD_HUMAN_CLIPBOARD", 0, true)

        exports['qb-target']:AddTargetEntity(ottosmodel, {
            options = {
                {
                    num = 1,
                    type = "client",
                    event = "sl-dealerships:client:sellavehiclemenu",
                    icon = "fa-solid fa-car",
                    label = "Sell A Vehicle",
                    job = "crownexotics"
                },
                {
                    num = 2,
                    type = "client",
                    event = "sl-dealerships:client:testvehiclecategories",
                    icon = "fa-solid fa-car",
                    label = "Vehicle Test Drive",
                    job = "crownexotics"
                },
                -- {
                --     num = 3,
                --     type = "client",
                --     event = "???",
                --     icon = "fa-solid fa-list",
                --     label = "Stock Vehicles (WIP)",
                -- },
            },
            distance = 2.5,
        })
    end
end
