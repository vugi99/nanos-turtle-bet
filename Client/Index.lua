
Package.Require("Config.lua")

World.SetSunSpeed(0)
World.SetTime(14, 30)

GUI = WebUI("Turtle Bet UI", "file:///UI/index.html")

Canvas_Data = {
    Money = nil,
    Tab_showed = false,
}

local CurBetOn = 0

Turtles_Canvas = Canvas(
    true,
    Color.TRANSPARENT,
    0,
    true
)
Turtles_Canvas:Subscribe("Update", function(self, width, height)
    if Canvas_Data.Money then
        self:DrawText("Money : " .. tostring(Canvas_Data.Money), Vector2D(3, Client.GetViewportSize().Y * 0.4), FontType.OpenSans, 16, Color.WHITE, 0, false, true, Color(0, 0, 0, 0), Vector2D(), false, Color.WHITE)
    end

    for k, v in pairs(Character.GetPairs()) do
        local turtle_nb = v:GetValue("TurtleNumber")
        if turtle_nb then
            local Vector_head_text = Calculate_Turtle_Text_Vector(v:GetLocation())
            if Vector_head_text then
                local color = Color.WHITE
                if turtle_nb == CurBetOn then
                    color = Color.YELLOW
                end
                self:DrawText(
                    tostring(turtle_nb),
                    Vector_head_text,
                    FontType.OpenSans,
                    18,
                    color,
                    0,
                    true,
                    true,
                    Color(0, 0, 0, 0),
                    Vector2D(),
                    true,
                    Color.BLACK
                )
            end
        end
    end

    if Canvas_Data.Tab_showed then
        local Players_Order = {}
        for k, v in pairs(Player.GetPairs()) do
            local money = v:GetValue("Money")
            local insert_at_pos = 1
            for i2, v2 in ipairs(Players_Order) do
                if v2:GetValue("Money") < money then
                    insert_at_pos = i2
                    break
                end
            end

            table.insert(Players_Order, insert_at_pos, v)
        end

        local cur_loc_on_screen = Vector2D(Client.GetViewportSize().X * 0.5, 150)
        for i, v in ipairs(Players_Order) do
            self:DrawText(
                v:GetAccountName() .. " : " .. tostring(v:GetValue("Money")),
                cur_loc_on_screen,
                FontType.OpenSans,
                16,
                Color.WHITE,
                0,
                true,
                true,
                Color(0, 0, 0, 0),
                Vector2D(),
                false,
                Color.BLACK
            )
            cur_loc_on_screen = cur_loc_on_screen + Vector2D(0, 25)
        end
    end
end)

local CustomAnim_BP = Blueprint(
    Vector(200, 200, 200),
    Rotator(0, 0, 0),
    "turtle-bet-assets::BP_CustomAnim"
)

function ColorToHex(color)
    return string.format("#%02x%02x%02x", color.R, color.G, color.B)
end

function Calculate_Turtle_Text_Vector(turtle_loc)
    local project = Client.ProjectWorldToScreen(turtle_loc + Vector(0, 0, -1000))
    if (project and project ~= Vector2D(-1, -1)) then
        return project
    end
end

Events.Subscribe("ShowBetUI", function(turtle_colors)
    for i, v in ipairs(turtle_colors) do
        GUI:CallEvent("AddBetRow", ColorToHex(turtle_colors[i]))
    end

    Client.SetInputEnabled(false)
    Client.SetMouseEnabled(true)

    GUI:CallEvent("ShowBetFrame", true)
    GUI:SetFocus()
    GUI:BringToFront()

    CurBetOn = 0
end)

function HideBetUI()
    GUI:CallEvent("ShowBetFrame", false)
    GUI:CallEvent("ResetBetRows")

    Client.SetInputEnabled(true)
    Client.SetMouseEnabled(false)
end
Events.Subscribe("HideBetUI", HideBetUI)

GUI:Subscribe("BetSelected", function(turtle_number, bet_value)
    if tonumber(bet_value) then
        if tonumber(bet_value) <= Client.GetLocalPlayer():GetValue("Money") then
            if tonumber(bet_value) > 0 then
                HideBetUI()
                CurBetOn = math.floor(tonumber(turtle_number))
                Events.CallRemote("ServerSelectBet", math.floor(tonumber(turtle_number)), math.floor(tonumber(bet_value)))
            end
        end
    end
end)

function HandleMoneyValue(value)
    Canvas_Data.Money = value
    --Turtles_Canvas:Repaint()
end

Player.Subscribe("ValueChange", function(ply, key, value)
    if ply == Client.GetLocalPlayer() then
        if key == "Money" then
            HandleMoneyValue(value)
        end
    end
end)

function HandleTurtleSpawn(char)
    if char:GetMesh() == "turtle-bet-assets::turtle" then
        char:AddActorTag("turtleanim")
        CustomAnim_BP:CallBlueprintEvent("SetTurtleAnimBP")
    end
end
Character.Subscribe("Spawn", HandleTurtleSpawn)
for k, v in pairs(Character.GetPairs()) do
    HandleTurtleSpawn(v)
end

Client.Subscribe("SpawnLocalPlayer", function()
    HandleMoneyValue(Client.GetLocalPlayer():GetValue("Money"))
end)

if Client.GetLocalPlayer() then
    HandleMoneyValue(Client.GetLocalPlayer():GetValue("Money"))
end

Input.Register("TAB", "Tab")

Input.Bind("TAB", InputEvent.Pressed, function()
    Canvas_Data.Tab_showed = true
end)

Input.Bind("TAB", InputEvent.Released, function()
    Canvas_Data.Tab_showed = false
end)