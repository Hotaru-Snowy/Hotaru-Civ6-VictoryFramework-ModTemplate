-- =============================================================================================
-- 【Tier 1 示例】Provider —— 只填 GetScore / GetText
--
-- 文件名必须严格等于  "HotaruVictoryFramework_Provider_" .. VictoryType
--   VictoryType = "VICTORY_TPL_TIER1"  →  文件名 HotaruVictoryFramework_Provider_VICTORY_TPL_TIER1.lua
--
-- 这一档解决的问题：官方"总览(Overall)"页签对未注册的胜利会回退成"玩家总分"排序。
-- 填了 GetScore 之后，总览页就会按你自己的指标排名。
--
-- 页签内容仍走官方通用视图（显示 RequirementStrings 的进度文本），
-- 所以**不需要**写 View，也**不需要** PopulateRow。
-- =============================================================================================

local VICTORY_TPL_TIER1 = "VICTORY_TPL_TIER1";

-- ===========================================================================
--  基础数据
-- ===========================================================================
local function PlayerScore(playerID)
    local pPlayer = Players[playerID];
    if pPlayer == nil or not pPlayer:IsAlive() then return 0; end
    return pPlayer:GetCities():GetCount();
end

-- ===========================================================================
--  注册
--  框架全局名：HotaruVictoryFramework
-- ===========================================================================
HotaruVictoryFramework.Register({

    VictoryType = VICTORY_TPL_TIER1,

    -- 页签短名（可选）。留空则用 Victories.Name。
    TabName = "LOC_TPL_TAB_TIER1",

    -- ---------------- 总览(Overall)页 ----------------
    -- ⚠ 参数是 Player 对象，不是 playerID —— 与官方 g_victoryData 的约定一致

    -- 排序键：数值越大越靠前
    GetScore = function(p)
        if p == nil then return 0; end
        return PlayerScore(p:GetID());
    end,

    -- 总览页该胜利行的文本
    -- ⚠ 返回 **LOC 键**，不是已本地化的串 —— 官方会做 Locale.Lookup(键, 分数)，
    --    所以 LOC_TPL_TIER1_OVERALL 的文本里写了 {1_Score} 占位符。
    --    若这里返回 Locale.Lookup(...) 的结果，分数就不会被代入。
    GetText = function(p)
        return "LOC_TPL_TIER1_OVERALL";
    end,

    -- 总览页补充摘要（可省略）
    Summary = function(p)
        if p == nil or not p:IsAlive() then return ""; end
        return "(" .. tostring(p:GetCities():GetCount()) .. ")";
    end,
});
