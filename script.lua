--==============================
-- Console Aim V2（画面距離のみで狙うバージョン）
-- Deadチェック（死体が残る仕様に対応）
--==============================

local fov = 100 -- FOV円の半径を100に変更

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera

local isAiming = false
local AIM_KEY = Enum.KeyCode.ButtonL2 
local DELETE_KEY = Enum.KeyCode.Delete

-- 虹色FOVリング
local hue = 0
local FOVring = Drawing.new("Circle")
FOVring.Visible = true
FOVring.Thickness = 2
FOVring.Filled = false
FOVring.Radius = fov -- ここも自動で100になります

local function updateDrawings()
    FOVring.Position = Cam.ViewportSize / 2
    hue = (hue + 0.01) % 1
    FOVring.Color = Color3.fromHSV(hue, 1, 1)
end

local function lookAt(targetPos)
    local lookVector = (targetPos - Cam.CFrame.Position).Unit
    Cam.CFrame = CFrame.new(Cam.CFrame.Position, Cam.CFrame.Position + lookVector)
end

-- 画面中央に一番近い敵を選択（距離は一切無視）
local function getClosestToCrosshair()
    local closestPlayer = nil
    local closestDist = math.huge
    local center = Cam.ViewportSize / 2

    for _, player in Players:GetPlayers() do
        local character = player.Character
        local head = character and character:FindFirstChild("Head")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        -- Humanoidが存在し、かつHealthが0より大きいプレイヤーのみを対象とする
        if player ~= Players.LocalPlayer and head and humanoid and humanoid.Health > 0 then
            local screenPos, onScreen = Cam:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < fov and dist < closestDist then -- fovが100として機能
                    closestDist = dist
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- 入力
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == DELETE_KEY then
        FOVring:Remove()
        return
    end
    if input.KeyCode == AIM_KEY then
        isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == AIM_KEY then
        isAiming = false
    end
end)

-- メインループ
local currentTarget = nil
RunService.RenderStepped:Connect(function()
    updateDrawings()

    if isAiming then
        
        -- 【Deadチェックの強化】
        -- currentTargetがいて、かつそのHumanoidのHealthが0以下なら、ターゲットを強制リセット
        local targetHumanoid = currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChildOfClass("Humanoid")
        if targetHumanoid and targetHumanoid.Health <= 0 then
            currentTarget = nil
        end

        -- ターゲットが設定されていない、またはリセットされた場合、新しいターゲットを探す
        if not currentTarget then
            currentTarget = getClosestToCrosshair()
        end
        
        -- ターゲットが存在し、そのHeadがある場合のみエイムを実行
        local head = currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("Head")
        if head then
            lookAt(head.Position)
        else
            -- エイム中にHeadが見つからなくなった場合 (稀なケース)、ターゲットをリセット
            currentTarget = nil
        end
    else
        -- エイムボタンが押されていなければ、ターゲットをリセット
        currentTarget = nil
    end
end)
