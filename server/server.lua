-- Server event to call open identification card on valid players
RegisterServerEvent('qidentification:server:showID')
AddEventHandler('qidentification:server:showID', function(item, players)
	if #players > 0 then 
		for _,player in pairs(players) do 
			TriggerClientEvent('qidentification:openID', player, item)
		end 
	end 
end)

-- Creating the card using item metadata.
RegisterServerEvent('qidentification:createCard')
AddEventHandler('qidentification:createCard', function(source,url,type)
	local xPlayer = ESX.GetPlayerFromId(source)
	local card_metadata = {}
	card_metadata.type = xPlayer.name
	card_metadata.citizenid = xPlayer[Config.CitizenID]:sub(-5)
	card_metadata.firstName = xPlayer.variables.firstName
	card_metadata.lastName = xPlayer.variables.lastName
	card_metadata.dateofbirth = xPlayer.variables.dateofbirth
	card_metadata.sex = xPlayer.variables.sex
	card_metadata.height = xPlayer.variables.height
	card_metadata.mugshoturl = url
	card_metadata.cardtype = type
	local curtime = os.time(os.date("!*t"))
	local diftime = curtime + 2629746
	card_metadata.issuedon = os.date('%m / %d / %Y',curtime)
	card_metadata.expireson = os.date('%m / %d / %Y', diftime)
	if type == "identification" then 
		print("Type is identification")
		local sex, identifier = xPlayer.variables.sex
		if sex == 'm' then sex = 'male' elseif sex == 'f' then sex = 'female' end
		card_metadata.description = ('Sex: %s | DOB: %s'):format( sex, xPlayer.variables.dateofbirth )
		xPlayer.addInventoryItem(type, 1, card_metadata)
	elseif type == "drivers_license" then 
		MySQL.Async.fetchAll('SELECT type FROM user_licenses WHERE owner = @identifier', {['@identifier'] = xPlayer.identifier},
		function (licenses)
			local status = false
			for i=1, #licenses, 1 do
				if licenses[i].type == 'drive' or licenses[i].type == 'drive_bike' or licenses[i].type == 'drive_truck' then
					card_metadata.licenses = licenses
					xPlayer.addInventoryItem(type, 1, card_metadata)
					status = true
				else 
					TriggerClientEvent('t-notify:client:Alert', source, {
						style = 'error',
						message = 'Δεν έχεις δίπλωμα οδήγησης, πήγαινε σε μία σχολή για να βγάλεις',
						duration  =  4000
					})
					status = true
				end	
			end
			if status == false then 
				TriggerClientEvent('t-notify:client:Alert', source, {
					style = 'error',
					message = 'Δεν έχεις δίπλωμα οδήγησης, πήγαινε σε μία σχολή για να βγάλεις',
					duration  =  4000
				})
			end		
		end)
		
	elseif type == "firearms_license" then 
		MySQL.Async.fetchAll('SELECT type FROM user_licenses WHERE owner = @identifier', {['@identifier'] = xPlayer.identifier},
		function (licenses)
			local status = false
			for i=1, #licenses, 1 do
				if licenses[i].type == 'weapon' then
					card_metadata.licenses = licenses
					xPlayer.addInventoryItem(type, 1, card_metadata)
					status = true
				else
					TriggerClientEvent('t-notify:client:Alert', source, {
						style = 'error',
						message = 'Δεν έχεις άδεια οπλοφορίας, ',
						duration  =  4000
					})
					status = true
				end
			end
			if status == false then 
				TriggerClientEvent('t-notify:client:Alert', source, {
					style = 'error',
					message = 'Δεν έχεις δίπλωμα οδήγησης',
					duration  =  4000
				})
			end
		end)
	end
end)

-- Server event to call open identification card on valid players
RegisterServerEvent('qidentification:server:payForLicense')
AddEventHandler('qidentification:server:payForLicense', function(identificationData,mugshotURL)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	if xPlayer.getMoney() < identificationData.cost then
		return xPlayer.showNotification("You can't afford this license.")
	end
	xPlayer.removeMoney(identificationData.cost)
	TriggerEvent('qidentification:createCard',_source,mugshotURL,identificationData.item)
end)
