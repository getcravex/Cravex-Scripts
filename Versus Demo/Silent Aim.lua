local FOV_RADIUS = _G.SilentAimConfig or 150
_G.SilentAimConfig = nil

local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/getcravex/Cravex-Scripts/refs/heads/main/Versus%20Demo/Services.lua"))()

local Players, Workspace = Services:Get('Players','Workspace')
local RunService = game:GetService("RunService")
local CurrentCamera = Workspace.CurrentCamera

local FOV_ENABLED = true

local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.Color = Color3.fromRGB(255,0,0)
circle.Filled = false
circle.Radius = FOV_RADIUS
circle.Visible = true

RunService.RenderStepped:Connect(function()

    if CurrentCamera and FOV_ENABLED then
    
        local vp = CurrentCamera.ViewportSize
        circle.Position = Vector2.new(vp.X/2,vp.Y/2)
        circle.Visible = true
        
    else
    
        circle.Visible = false
        
    end
    
end)

local function WorldToScreen(pos)

    local screen, onScreen = CurrentCamera:WorldToViewportPoint(pos)
    return Vector2.new(screen.X,screen.Y), onScreen
    
end

local function IsInFOV(headPos)

    if not FOV_ENABLED then return true end
    
    local screenPos, onScreen = WorldToScreen(headPos)
    
    if not onScreen then return false end
    
    local center = Vector2.new(CurrentCamera.ViewportSize.X/2,CurrentCamera.ViewportSize.Y/2)
    
    return (screenPos - center).Magnitude <= FOV_RADIUS
    
end

do

    local _G = getrenv()._G
    local globals = _G.globals
    local exe_map = debug.getupvalues(_G.append_exe_set)[1]
    
    local cli_state = globals.cli_state
    local sol_teams = globals.sol_teams
    local soldiers_spawned = globals.soldiers_spawned
    local soldiers_alive = globals.soldiers_alive
    local soldier_models = globals.soldier_models

    local function get_closest_player()
    
        local closest_player
        local closest_distance = math.huge
        local fpv_id = cli_state.fpv_sol_id
        local team = sol_teams[fpv_id]
        
        for player_id, spawned in pairs(soldiers_spawned) do
        
            if spawned and soldiers_alive[player_id] and player_id ~= fpv_id and sol_teams[player_id] ~= team then
            
                local character = soldier_models[player_id]
                
                if character and character.PrimaryPart then
                
                    local head = character:FindFirstChild("Head") or character.PrimaryPart
                    
                    if IsInFOV(head.Position) then
                    
                        local distance = (head.Position - CurrentCamera.CFrame.Position).Magnitude
                        
                        if distance < closest_distance then
                        
                            closest_distance = distance
                            closest_player = head
                            
                        end
                        
                    end
                    
                end
                
            end
            
        end
        
        return closest_player
        
    end

    local old_spawn = exe_map[_G.exe_func_t.SPAWN_FPV_SOL_BULLET]
    
    exe_map[_G.exe_func_t.SPAWN_FPV_SOL_BULLET] = function(bullet_id, bullet_type, spawn_pos, velocity)
    
        local target = get_closest_player()
        
        if target then
        
            velocity = (target.Position - spawn_pos).Unit * velocity.Magnitude
            
        end
        
        return old_spawn(bullet_id, bullet_type, spawn_pos, velocity)
        
    end
    
end
