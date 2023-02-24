local QBCore = exports['qb-core']:GetCoreObject()
local src = source
local Player = QBCore.Functions.GetPlayer(src)

QBCore.Functions.CreateCallback('sl-dealerships:server:getnearestplayers', function(source, cb)
	local src = source
	local players = {}
	local PlayerPed = GetPlayerPed(src)
	local pCoords = GetEntityCoords(PlayerPed)
	for _, v in pairs(QBCore.Functions.GetPlayers()) do
		local Target = GetPlayerPed(v)
		local tCoords = GetEntityCoords(Target)
		local dist = #(pCoords - tCoords)
		if PlayerPed ~= Target and dist < 10 then
			local ped = QBCore.Functions.GetPlayer(v)
			players[#players+1] = {
                id = v,
                coords = GetEntityCoords(Target),
                name = ped.PlayerData.charinfo.firstname .. " " .. ped.PlayerData.charinfo.lastname,
                citizenid = ped.PlayerData.citizenid,
                grade = ped.PlayerData.job.grade,
                job = ped.PlayerData.job.name,
                joblabel = ped.PlayerData.job.label,
                sources = GetPlayerPed(ped.PlayerData.source),
                sourceplayer = ped.PlayerData.source
			}
		end
	end
		table.sort(players, function(a, b)
			return a.name < b.name
		end)
	cb(players)
end)

RegisterNetEvent('sl-dealerships:server:sellVehicle', function(data)
	local src = source
    local vehiclehash = GetHashKey(data.sellingVehicleModel)

    -- EMPLOYEE --
	local Player = QBCore.Functions.GetPlayer(src)
    local bank = Player.PlayerData.money['bank']
    local CSN = Player.PlayerData.citizenid
    local pname = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    
    -- CUSTOMER --
    local Target = QBCore.Functions.GetPlayer(data.target)
    local tbank = Target.PlayerData.money['bank']
    local tcash = Target.PlayerData.money['cash']
    local tCSN = Target.PlayerData.citizenid
    local tname = Target.PlayerData.charinfo.firstname .. " " .. Target.PlayerData.charinfo.lastname

    if tbank >= tonumber(data.sellingVehiclePrice) then
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, "You have purchased the "..data.sellingVehicleName.." for $"..data.sellingVehiclePrice, "success")
        TriggerClientEvent('QBCore:Notify', src, "You have sold the "..data.sellingVehicleName.." for $"..data.sellingVehiclePrice.." to "..tname, "success")
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            Target.PlayerData.license,
            tCSN,
            data.sellingVehicleModel,
            GetHashKey(vehiclehash),
            '{}',
            data.sellingVehiclePlate,
            'legionsquare',
            0
        })

        TriggerClientEvent('vehiclekeys:client:SetOwner', Target.PlayerData.source, data.sellingVehiclePlate)
        FreezeEntityPosition(data.sellingVehicleModel, false)
        Target.Functions.RemoveMoney('bank', data.sellingVehiclePrice, 'ottos-vehicle-purchase')
        exports['Renewed-Banking']:addAccountMoney("ottos", data.sellingVehiclePrice)
        TriggerEvent('qb-log:server:CreateLog', 'ottos', 'sl-dealerships', 'red', '**Salesmen Action** | **Vehicle Sold** *('..Player.PlayerData.job.label..')* \n\n **FiveM Name**: `'..GetPlayerName(src) .. '` \n**Player Name**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .."` \n**Player Job**: `"..Player.PlayerData.job.label..'` \n**CSN**: `'..Player.PlayerData.citizenid..'`\n**Player ID**: `'..src..'`\n**FiveM License**: `'..Player.PlayerData.license.."` \n\n**Customer Information** \n\n**FiveM Name**: `"..GetPlayerName(Target.PlayerData.source).."` \n**Customer Name**: `"..tname.."` \n**Customer Job**: `"..Player.PlayerData.job.label.."` \n**Customer CSN**: `"..Target.PlayerData.citizenid.."` \n**Customer Player ID**: `"..Target.PlayerData.source.."`\n**FiveM License**: `"..Target.PlayerData.license.."` \n\n**Vehicle Information** \n\n**Vehicle Name**: `"..data.sellingVehicleName.."` \n**Vehicle Spawncode**: `"..data.sellingVehicleModel.."` \n**Vehicle Plate**: `"..data.sellingVehiclePlate.."` \n**Vehicle Price**: `$"..data.sellingVehiclePrice.."` \n**Vehicle Owner**: `"..tname.."`", false)
    else
        TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, "You do not have enough money in both your bank to purchase this vehicle!", 'error')
        TriggerClientEvent('QBCore:Notify', src, "The customer doesn't have enough money in their bank to purchase this vehicle!", 'error')
    end
end)

RegisterNetEvent('sl-dealerships:server:selfpurchasesellVehicle', function(data)
	local src = source
    local vehiclehash = GetHashKey(data.sellingVehicleModel)

    -- EMPLOYEE --
	local Player = QBCore.Functions.GetPlayer(src)
    local bank = Player.PlayerData.money['bank']
    local cash = Player.PlayerData.money['cash']
    local CSN = Player.PlayerData.citizenid
    local pname = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname

    if bank >= tonumber(data.sellingVehiclePrice) then
        TriggerClientEvent('QBCore:Notify', src, "You have purchased the "..data.sellingVehicleName.." for $"..data.sellingVehiclePrice, "success")
        MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            Player.PlayerData.license,
            CSN,
            data.sellingVehicleModel,
            GetHashKey(vehiclehash),
            '{}',
            data.sellingVehiclePlate,
            'legionsquare',
            0
        })

        TriggerClientEvent('vehiclekeys:client:SetOwner', src, data.sellingVehiclePlate)
        FreezeEntityPosition(data.sellingVehicleModel, false)
        Player.Functions.RemoveMoney('bank', data.sellingVehiclePrice, 'ottos-vehicle-purchase')
        exports['Renewed-Banking']:addAccountMoney("ottos", data.sellingVehiclePrice)
        TriggerEvent('qb-log:server:CreateLog', 'ottos', 'sl-dealerships', 'red', '**Salesmen Action** | **Vehicle Sold** *('..Player.PlayerData.job.label..')* \n\n **FiveM Name**: `'..GetPlayerName(src) .. '` \n**Player Name**: `'..Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname .."` \n**Player Job**: `"..Player.PlayerData.job.label..'` \n**CSN**: `'..Player.PlayerData.citizenid..'`\n**Player ID**: `'..src..'`\n**FiveM License**: `'..Player.PlayerData.license.."` \n\n**Vehicle Information** \n\n**Vehicle Name**: `"..data.sellingVehicleName.."` \n**Vehicle Spawncode**: `"..data.sellingVehicleModel.."` \n**Vehicle Plate**: `"..data.sellingVehiclePlate.."` \n**Vehicle Price**: `$"..data.sellingVehiclePrice.."` \n**Vehicle Owner**: `"..pname.."` \n\n***This vehicle was a self-purchase by the employee!***", false)
    else
        TriggerClientEvent('QBCore:Notify', src, "You do not have enough money in your bank to purchase this vehicle!", 'error')
    end
end)