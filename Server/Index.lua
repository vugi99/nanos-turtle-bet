

Package.RequirePackage("rounds")
Package.Require("Config.lua")

INIT_ROUNDS({
    ROUND_TYPE = "BASIC",
    ROUND_START_CONDITION = {"PLAYERS_NB", 1},
    ROUND_END_CONDITION = {"REMAINING_PLAYERS", 0},
    SPAWN_POSSESS = {"TRANSLATE_CAMERA", {1, 0}},
    SPAWNING = {"SPAWNS", {{Race_Start + Race_Camera_Start_Offset, Race_Rotator + Race_Camera_Start_Rotation_Offset}}},
    WAITING_ACTION = {"FREECAM"},
    PLAYER_OUT_CONDITION = {"CODE"},
    PLAYER_OUT_ACTION = {"WAITING"},

    ROUNDS_INTERVAL_ms = TimeToBet,
    CAN_JOIN_DURING_ROUND = true,
})

local persistent_data = Package.GetPersistentData()
if not persistent_data.players_money then
    persistent_data.players_money = {}
end

local Segments = {}
local Start_To_End = Race_End - Race_Start
local Start_To_End_For_Segments = Start_To_End / Race_Segments
for i = 1, Race_Segments do
    table.insert(Segments, {send = Race_Start + Start_To_End_For_Segments * i})
end

local Turtles = {}
local Turtles_Colors = {}
local Players_Bets = {}

local Turtle_That_Won

function table_count(tbl)
    local count = 0
    for k, v in pairs(tbl) do count = count + 1 end
    return count
end

function Buy(ply, price)
    local pmoney = ply:GetValue("Money")
    if (pmoney and pmoney >= price) then
        ply:SetValue("Money", pmoney - price, true)
        if pmoney - price < Min_Money then
            ply:SetValue("Money", Min_Money, true)
        end
        return true
    end
end

function AddMoney(ply, added)
    local pmoney = ply:GetValue("Money")
    if pmoney then
        ply:SetValue("Money", pmoney + added, true)
        return true
    end
end

function NextTurtleSegment(turtle)
    if turtle:IsValid() then
        local segment = turtle:GetValue("AtSegment")
        segment = segment + 1
        turtle:SetValue("AtSegment", segment, false)
        if segment < Race_Segments then
            local r_time = math.random(Min_Time_For_Segment, Max_Time_For_Segment)
            turtle:TranslateTo(Segments[segment].send + Other_Turtle_Race_Offset * (turtle:GetValue("TurtleNumber")-1) + Vector(0, 0, (math.random(0, Max_Segment_Offset_Z * 2)) - Max_Segment_Offset_Z), r_time / 1000, 0)
            Timer.SetTimeout(NextTurtleSegment, r_time, turtle)
        else
            if ROUND_RUNNING then
                Turtle_That_Won = turtle:GetValue("TurtleNumber")
                RoundEnd()
            end
        end
    end
end


Events.Subscribe("RoundStart", function()
    for i = 1, table_count(Turtles_Colors) do
        local turtle = Character(Race_Start + Other_Turtle_Race_Offset * (i-1), Race_Rotator, "turtle-bet-assets::turtle", CollisionType.NoCollision, false)
        --turtle:PlayAnimation("turtle-bet-assets::turtle_anim", AnimationSlotType.FullBody, true, 0, 0, 1, false)
        turtle:SetValue("AtSegment", 0, false)
        turtle:SetValue("TurtleNumber", i, true)

        turtle:SetScale(Vector(10, 10, 10))

        NextTurtleSegment(turtle)

        table.insert(Turtles, turtle)
    end

    Events.BroadcastRemote("HideBetUI")

    Server.BroadcastChatMessage("Round Started !")
end)

function Turtle_RoundEnding()
    for i, v in ipairs(Turtles) do
        v:Destroy()
    end
    Turtles = {}

    if Turtle_That_Won then
        Server.BroadcastChatMessage("Turtle #" .. tostring(Turtle_That_Won) .. " won")

        for k, v in pairs(Players_Bets) do
            local ply
            for k2, v2 in pairs(Player.GetPairs()) do
                if v2:GetID() == k then
                    ply = v2
                    break
                end
            end
            if ply then
                if v[1] == Turtle_That_Won then
                    AddMoney(ply, v[2] * table_count(Turtles_Colors))
                end
            end
        end
    end

    Turtles_Colors = {}
    local turtles_to_spawn = math.random(Min_Racing_Turtles, Max_Racing_Turtles)
    for i = 1, turtles_to_spawn do
        table.insert(Turtles_Colors, Color(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
    end

    Turtle_That_Won = nil

    Events.BroadcastRemote("ShowBetUI", Turtles_Colors)
end
Events.Subscribe("RoundEnding", Turtle_RoundEnding)
Turtle_RoundEnding()

Events.Subscribe("ServerSelectBet", function(ply, turtle_number, bet_value)
    if not ROUND_RUNNING then
        if Turtles_Colors[turtle_number] then
            if not Players_Bets[ply:GetID()] then
                if Buy(ply, bet_value) then
                    Players_Bets[ply:GetID()] = {turtle_number, bet_value}
                    Server.BroadcastChatMessage(ply:GetAccountName() .. " placed a bet of " .. tostring(bet_value) .. " on turtle #" .. tostring(turtle_number) .. ".")
                end
            end
        end
    end
end)

Events.Subscribe("RoundPlayerJoined", function(ply)
    Server.BroadcastChatMessage(ply:GetAccountName() .. " joined")

    if persistent_data.players_money[ply:GetSteamID()] then
        ply:SetValue("Money", persistent_data.players_money[ply:GetSteamID()], true)
    else
        ply:SetValue("Money", Default_Money, true)
    end
end)

Player.Subscribe("Destroy", function(ply)
    Server.BroadcastChatMessage(ply:GetAccountName() .. " left")

    persistent_data.players_money[ply:GetSteamID()] = ply:GetValue("Money")
end)

Package.Subscribe("Unload", function()
    for k, v in pairs(Player.GetPairs()) do
        persistent_data.players_money[v:GetSteamID()] = v:GetValue("Money")
    end
    Package.SetPersistentData("players_money", persistent_data.players_money)
end)