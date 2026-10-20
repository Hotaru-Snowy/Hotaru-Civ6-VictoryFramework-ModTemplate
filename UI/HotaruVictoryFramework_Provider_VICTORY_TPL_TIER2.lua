-- =============================================================================================
-- 【Tier 2 示例】Provider —— 行内容（PopulateRow）+ 整页布局（View）
--
-- 文件名必须严格等于  "HotaruVictoryFramework_Provider_" .. VictoryType
--   VictoryType = "VICTORY_TPL_TIER2"  →  文件名 HotaruVictoryFramework_Provider_VICTORY_TPL_TIER2.lua
--
-- 数据源：本示例用"玩家城市数"当指标（真实 MOD 一般读 Gameplay 写进玩家属性的值）
--
-- 两个钩子的分工：
--   · PopulateRow —— 管"每一行长什么样"（文字 / tooltip / 行高）
--   · View        —— 管"整页怎么排"（这里演示按分数降序）
-- 只改文字的话，其实只写 PopulateRow 就够了，View 可以不写（走官方通用布局）。
--
-- 本文件在框架的 WorldRankings 上下文内被执行，所以可以直接调用官方的
-- ViewGeneric / PopulateGenericHeader / PopulateGenericInstance / GatherGenericData /
-- RealizeGenericStackSize / Controls / g_GenericIM 等 —— 与写官方 UI 脚本无异。
-- =============================================================================================

local VICTORY_TPL_TIER2 = "VICTORY_TPL_TIER2";

-- 行高常量（与官方 WorldRankings 口径一致）
local PADDING_GENERIC_ITEM_BG = 25;
local SIZE_GENERIC_ITEM_MIN_Y  = 54;

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

    VictoryType = VICTORY_TPL_TIER2,
    TabName     = "LOC_TPL_TAB_TIER2",

    -- ---------------- 总览(Overall)页 ----------------
    -- ⚠ GetText 返回 **LOC 键**，官方会 Locale.Lookup(键, 分数) 代入 {1_Score}
    GetScore = function(p)
        if p == nil then return 0; end
        return PlayerScore(p:GetID());
    end,
    GetText  = function(p) return "LOC_TPL_TIER2_OVERALL"; end,
    Summary  = function(p) return ""; end,

    -- ---------------- 行级后处理 ----------------
    -- 官方行（PopulateGenericInstance）渲染完成后再调用，用来覆盖这一行的内容。
    -- 💡 框架会在调用本函数**之前**自动清空 ButtonBG 的 tooltip，
    --    所以"要 tooltip 就在这里设，不设就保持干净"，不会串到别的胜利页签。
    -- ⚠ 不要在这里再调用 PopulateGenericInstance，会无限递归。
    PopulateRow = function(instance, playerData, victoryType, showTeamDetails)
        if playerData == nil then return; end

        instance.Details:SetText(
            Locale.Lookup("LOC_TPL_TIER2_ROW", PlayerScore(playerData.PlayerID)));

        if instance.ButtonBG ~= nil then
            instance.ButtonBG:SetSizeY(math.max(SIZE_GENERIC_ITEM_MIN_Y,
                instance.Details:GetSizeY() + PADDING_GENERIC_ITEM_BG));
        end
    end,

    -- ---------------- 整页布局：按分数降序 ----------------
    -- 骨架照抄官方 ViewGeneric（原版 WorldRankings.lua L2174-2202），
    -- 只在中间加了一次排序。每一行的内容由上面的 PopulateRow 负责。
    View = function(victoryType)
        ResetState(function() ViewGeneric(victoryType); end);
        Controls.GenericView:SetHide(false);

        ChangeActiveHeader("GENERIC", m_GenericHeaderIM, Controls.GenericViewHeader);

        -- 页头：标题 / 描述 / 图标都取自数据库里的 Victories 行
        local victoryInfo = GameInfo.Victories[victoryType];
        if victoryInfo ~= nil then
            PopulateGenericHeader(RealizeGenericStackSize,
                victoryInfo.Name, nil, victoryInfo.Description,
                victoryInfo.Icon or ICON_GENERIC);
        end

        g_GenericIM:ResetInstances();
        g_GenericTeamIM:ResetInstances();

        -- 收集 + 排序
        local rows = {};
        for _, teamData in ipairs(GatherGenericData()) do
            table.insert(rows, {
                teamData = teamData,
                score    = PlayerScore(teamData.PlayerData[1].PlayerID),
            });
        end
        table.sort(rows, function(a, b) return a.score > b.score; end);

        -- 渲染（PopulateRow 会自动接手每行文本）
        for _, row in ipairs(rows) do
            if #row.teamData.PlayerData > 1 then
                PopulateGenericTeamInstance(g_GenericTeamIM:GetInstance(), row.teamData, victoryType);
            else
                PopulateGenericInstance(g_GenericIM:GetInstance(),
                    row.teamData.PlayerData[1], victoryType, false);
            end
        end

        RealizeGenericStackSize();
    end,
});
