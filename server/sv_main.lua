local QBCore = exports['qb-core']:GetCoreObject()
local src = source
local Player = QBCore.Functions.GetPlayer(src)
local plate = nil

local function GeneratePlate()
    local plate = QBCore.Shared.RandomInt(1) .. QBCore.Shared.RandomStr(2) .. QBCore.Shared.RandomInt(3) .. QBCore.Shared.RandomStr(2)
    local result = MySQL.scalar.await('SELECT plate FROM player_vehicles WHERE plate = ?', {plate})
    if result then
        return GeneratePlate()
    else
        return plate:upper()
    end
end

RegisterNetEvent('sl-dealerships:server:sellVehicle', function(data)
	local src = source
	local Player = QBCore.Functions.GetPlayer(src)
	local Target = QBCore.Functions.GetPlayer(data.target)
    local bank = Target.PlayerData.money['bank']
    local CSN = Player.PlayerData.citizenid
    local Target_CSN = Target.PlayerData.citizenid
    --local vehicle = data.vehicle.name
    local vehiclespawn = data.vehicle.model
    local vehiclehash = GetHashKey(data.vehicle.model)
    local price = data.vehicle.price
    local name = Target.PlayerData.charinfo.firstname .. " " .. Target.PlayerData.charinfo.lastname
    local pname = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    local plate = GeneratePlate()

    if Target then
        if bank >= tonumber(price) then
            TriggerClientEvent('QBCore:Notify', src, "You have sold "..name.." a "..vehicle.." for $"..price, "info")
            TriggerClientEvent('QBCore:Notify', Target.PlayerData.source, "You have been sold a "..vehicle.." for $"..price, "info")
            MySQL.insert('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                Target.PlayerData.license,
                Target_CSN,
                vehiclespawn,
                GetHashKey(vehiclehash),
                '{}',
                plate,
                'pillboxgarage',
                0
            })
            Player.Functions.RemoveMoney('bank', price, 'ottos-vehicle-purchase')
        else
            TriggerClientEvent('QBCore:Notify', src, "You do not have enough money in your bank to purchase this vehicle!", 'error')
        end
    end
end)

QBCore.Functions.CreateCallback('sl-dealerships:server:getnearestplayer', function(source, cb)
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
