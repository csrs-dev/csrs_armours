if not (ESX) then
    ESX = exports["es_extended"]:getSharedObject()
end

local function xPlayerhasItem(xPlayer, itemname, amount)
    amount = amount or 1
    local item = xPlayer.getInventoryItem(itemname)
    return item.count >= amount
end

for _, value in pairs(Config.armours) do
    local itemname = value.itemname
    local autherizeJobs = {}
    local authJobsLength = #value.autherizedJobs
    for _, value in pairs(value.autherizedJobs) do
        autherizeJobs[value] = true
    end

    ESX.RegisterUsableItem(itemname, function(src)
        local xPlayer = ESX.GetPlayerFromId(src)
        if not (xPlayerhasItem(xPlayer, itemname)) then return end
        if (authJobsLength > 0) then
            if not (autherizeJobs[xPlayer.job.name]) then return end
        end
        local eventName = cslib.resource.event(string.format("onArmourUsed_%s", itemname))
        cslib.emitClient(eventName, src)
    end)

    cslib.onNet(cslib.resource.event(string.format("remove_%s", itemname)), function()
        local src = source
        local xPlayer = ESX.GetPlayerFromId(src)
        if not (xPlayerhasItem(xPlayer, itemname)) then return end
        xPlayer.removeInventoryItem(itemname, 1)
    end)
end
