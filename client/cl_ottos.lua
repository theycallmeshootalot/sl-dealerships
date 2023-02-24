QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()

sellingVehicleName = nil
selingVehiclePrice = nil
sellingVehicleModel = nil
sellingVehiclePlate = nil
sellingVehicleVeh = nil

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then 
        PlayerJob = QBCore.Functions.GetPlayerData().job 
        OttosPed()
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerJob = QBCore.Functions.GetPlayerData().job
    OttosPed()
end)

AddEventHandler('onResourceStop', function(resourceName) 
	if GetCurrentResourceName() == resourceName then
        DeletePed(OttosPed())
	end 
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate')
AddEventHandler('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

function all_trim(s)
    return s:match"^%s*(.*)":match"(.-)%s*$"
end

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
    sellingVehicleModel = data.vehicle.model
    sellingVehicleName = data.vehicle.name
    sellingVehiclePrice = data.vehicle.price
    local location = Config.OttosVehicleSpawn
 
    if QBCore.Functions.SpawnClear(vector3(location.x, location.y, location.z), 2.0) then
        QBCore.Functions.Notify('You have taken out the '..sellingVehicleName..", interact with to vehicle to sell it", 'info')
        QBCore.Functions.TriggerCallback('QBCore:Server:SpawnVehicle', function(netId)
            veh = NetToVeh(netId)
            sellingVehiclePlate = all_trim(GetVehicleNumberPlateText(veh))
            sellingVehicleVeh = veh

            SetVehicleNumberPlateText(veh, sellingVehiclePlate)
            SetVehicleEngineOn(veh, true)
            SetVehicleDoorsLocked(veh, 2)
            SetVehicleFixed(veh)
            exports['cdn-fuel']:SetFuel(veh, 100.0)
            
            local bones = {
                'boot',
                'bonnet',
                'chassis',
                'bumper_r',
                'bumper_f',
                'bodyshell',
                'door_dside_f',
                'door_dside_r',
                'door_pside_f',
                'door_pside_r',
            }

            exports['qb-target']:AddTargetBone(bones, {
                options = {
                    {
                        num = 1,
                        type = "client",
                        event = "sl-dealerships:client:purchasevehiclemenu",
                        icon = "fa-solid fa-dollar-sign",
                        label = "Select Customer for Purchase",
                        job = "ottos"
                    },
                    {
                        num = 2,
                        type = "client",
                        event = "sl-dealerships:client:returnVehicle",
                        icon = "fa-solid fa-rotate-left",
                        label = "Return Vehicle",
                        job = "ottos",
                    }
                },
                distance = 2,
            })
        end, sellingVehicleModel, location, false)
    else
        QBCore.Functions.Notify('The area to bring in the '..sellingVehicleName.." isn't clear, remove all vehicles or players out of the area", 'error')
    end
end)

RegisterNetEvent('sl-dealerships:client:returnVehicle', function(data)
    DeleteVehicle(veh)
    QBCore.Functions.Notify('You have returned the vehicle back into '..PlayerJob.label.." vehicle's stock.", 'success')
    exports['qb-target']:RemoveTargetEntity(veh, "Purchase Vehicle")
    exports['qb-target']:RemoveTargetEntity(veh, "Return Vehicle")
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
            TriggerEvent('vehiclekeys:client:SetOwner', QBCore.Functions.GetPlate(veh))
            exports['cdn-fuel']:SetFuel(veh, 100.0)
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

RegisterNetEvent('sl-dealerships:client:purchasevehiclemenu', function(data)
    local PurchaseVehicleMenu = {
        {
            icon = "fas fa-car",
            header = "Otto's Exotic | Confirmation",
            isMenuHeader = true
        },
    }
    QBCore.Functions.TriggerCallback('sl-dealerships:server:getnearestplayers', function(players)
        for _, vp in pairs(players) do
            if vp and vp ~= PlayerPedId() then
                PurchaseVehicleMenu[#PurchaseVehicleMenu + 1] = {
                    header = "Are you sure you want to bill "..vp.name.." for the "..sellingVehicleName.."?",
                    txt = "Click to send bill of $"..sellingVehiclePrice,
                    icon = "fa-solid fa-dollar-sign",
                    params = {
                        isServer = true,
                        event = "sl-dealerships:server:sellVehicle",
                        args = {
                            sellingVehiclePrice = sellingVehiclePrice,
                            sellingVehicleName = sellingVehicleName,
                            sellingVehicleModel = sellingVehicleModel,
                            sellingVehiclePlate = sellingVehiclePlate,
                            target = vp.sourceplayer
                        }
                    }
                }
            end
        end

        PurchaseVehicleMenu[#PurchaseVehicleMenu+1] = {
            icon = "fa-solid fa-dollar-sign",
            header = "Purchase vehicle for yourself",
            txt = "Click to confirm payment of $"..sellingVehiclePrice.." for the "..sellingVehicleName ,
            params = {
                isServer = true,
                event = "sl-dealerships:server:selfpurchasesellVehicle",
                args = {
                    sellingVehiclePrice = sellingVehiclePrice,
                    sellingVehicleName = sellingVehicleName,
                    sellingVehicleModel = sellingVehicleModel,
                    sellingVehiclePlate = sellingVehiclePlate
                }
            }
        }

        PurchaseVehicleMenu[#PurchaseVehicleMenu+1] = {
            icon = "fas fa-x",
            header = "Exit",
            params = {
                event = "sl-dealerships:client:close"
            }
        }

        exports['qb-menu']:openMenu(PurchaseVehicleMenu)
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

function OttosPed()
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
                    event = "sl-dealerships:client:sellvehiclecategories",
                    icon = "fa-solid fa-car",
                    label = "Sell A Vehicle",
                    job = "ottos"
                },
                {
                    num = 2,
                    type = "client",
                    event = "sl-dealerships:client:testvehiclecategories",
                    icon = "fa-solid fa-car",
                    label = "Vehicle Test Drive",
                    job = "ottos"
                },
            },
            distance = 2.5,
        })
    end
end
