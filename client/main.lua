local armourNextUsableTime = 0

for _, value in pairs(Config.armours) do
    local itemname = value.itemname
    local amount = value.amount
    local useDuration = value.useDuration
    local cooldown = value.cooldown

    local nextUsableTime = 0

    local eventName = cslib.resource.event(string.format("onArmourUsed_%s", itemname))
    cslib.onNet(eventName, function()
        local timeNow = GetGameTimer()
        if (timeNow < armourNextUsableTime) or (timeNow < nextUsableTime) then
            ESX.ShowNotification("You can't use this item yet.")
            return
        end

        armourNextUsableTime = timeNow + useDuration
        nextUsableTime = timeNow + cooldown

        cslib.streaming.animDict.request.await("clothingshirt")

        TaskPlayAnim(PlayerPedId(), "clothingshirt", "try_shirt_positive_d", 8.0, 8.0, -1, 50, 0, false, false, false)
        Wait(useDuration)
        local newArmour = math.min(GetPedArmour(PlayerPedId()) + amount, 100)
        StopAnimTask(PlayerPedId(), "clothingshirt", "try_shirt_positive_d", 1.0)
        SetPedArmour(PlayerPedId(), newArmour)
        cslib.emitServer(cslib.resource.event(string.format("remove_%s", itemname)))

        --[[ Clothing options ]]
        cslib.emit("skinchanger:getSkin", function(skin)
            local bMale = skin.sex == 0
            cslib.emit("skinchanger:loadClothes", skin, {
                ["bproof_1"] = bMale and 6 or 6,
                ["bproof_2"] = bMale and 1 or 1
            })
        end)
    end)
end
