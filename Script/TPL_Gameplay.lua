-- =============================================================================================
-- 判定脚本（服务端 Gameplay context）—— **只有 D 路线（虚拟建筑）需要本文件**
--
-- 模板里只有 TIER1 / TIER2 用它：它们走"隐藏标记建筑"，需要 Lua 每回合算真实条件，
-- 达成时把标记建筑塞给玩家 → 引擎检测到玩家拥有该建筑 → 判胜。
--
-- ⚠ TIER0 不用本文件：它走 A 路线（条件 = 拥有大本钟），引擎自己判。
--   如果你的胜利能用现有 Requirement 表达（真实建筑 / 完成项目 / 点数），
--   整份脚本都不需要。
--
-- 依赖：胜利框架提供的 VictoryCore.GrantVictory（城市回退 / 幂等去重 / DB 缺失兜底）。
--       不用框架的话，见文件末尾的一行说明。
--
-- 状态持久化：一律用 Player:SetProperty（随存档保存，读档不丢）。
-- =============================================================================================

local VICTORY_TPL_TIER1 = "VICTORY_TPL_TIER1";
local VICTORY_TPL_TIER2 = "VICTORY_TPL_TIER2";

local BUILDING_TPL_TIER1 = "BUILDING_TPL_TIER1_VICTORY";
local BUILDING_TPL_TIER2 = "BUILDING_TPL_TIER2_VICTORY";

-- 演示用：把下面改成 2，第 2 回合就会自动判胜（测试用）
local TEST_TURN = -1;

-- ---------------------------------------------------------------------------------------------
-- 你的真实条件写在这里
--   返回 true = 该玩家达成条件
--   本模板用一个最简单的例子：玩家拥有的城市数 >= 3
-- ---------------------------------------------------------------------------------------------
local function MeetsCondition(pPlayer)
    if pPlayer == nil or not pPlayer:IsAlive() or not pPlayer:IsMajor() then return false; end
    return pPlayer:GetCities():GetCount() >= 3;
end

-- ---------------------------------------------------------------------------------------------
-- 每回合检查
-- ---------------------------------------------------------------------------------------------
local function OnPlayerTurnActivated(playerID)
    local pPlayer = Players[playerID];
    if pPlayer == nil or not pPlayer:IsMajor() or not pPlayer:IsAlive() then return; end

    local turn = Game.GetCurrentGameTurn();

    -- 开关 gate：开始界面未勾选该胜利 → 不判定
    if Game.IsVictoryEnabled(VICTORY_TPL_TIER1) and (MeetsCondition(pPlayer) or turn == TEST_TURN) then
        VictoryCore.GrantVictory(playerID, BUILDING_TPL_TIER1);
    end
    if Game.IsVictoryEnabled(VICTORY_TPL_TIER2) and (MeetsCondition(pPlayer) or turn == TEST_TURN) then
        VictoryCore.GrantVictory(playerID, BUILDING_TPL_TIER2);
    end
end

Events.PlayerTurnActivated.Add(OnPlayerTurnActivated);

print("[TPL] 模板判定脚本已加载");