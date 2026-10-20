-- =============================================================================================
-- 草之爹的胜利框架 HotaruVictoryFramework · Provider 模板
--
-- 使用步骤：
--   1. 复制本文件，改名为   HotaruVictoryFramework_Provider_<你的胜利类型>.lua
--         例：胜利类型是 VICTORY_MYVICTORY  →  文件名 HotaruVictoryFramework_Provider_VICTORY_MYVICTORY.lua
--      ⚠ 文件名必须**严格等于** "HotaruVictoryFramework_Provider_" 拼接 VictoryType，框架靠它自动找到你。
--   2. 在 ModBuddy 的 Actions 页给它加一条 ImportFiles（见 2_ModBuddy操作对照.md）。
--   3. 填好下面各字段，删除不需要的行。
--   4. 在 ModBuddy 的 Actions 页里**删掉**对 WorldRankings 的 ReplaceUIScript（如有）。
--
-- 本文件在框架的 WorldRankings 上下文内被执行，因此可以直接调用官方的
-- ViewGeneric / PopulateGenericHeader / AddTab / g_victoryData 等函数。
-- =============================================================================================

-- =============================================================================================
-- 【必备工具】安全读玩家属性
--
-- ⚠⚠ Civ6 最经典的坑之一：
--     玩家属性**未设置**时，Player:GetProperty() 返回的是"零个返回值"（不是 nil）。
--     所以 `tonumber(p:GetProperty("X"))` 实际变成了 `tonumber()` 的无参调用 →
--       Runtime Error: bad argument #1 to 'tonumber' (value expected)
--     而且这个错误发生在 tonumber 内部，写成 `tonumber(...) or 0` 也兜不住。
--
--     必须**先落成局部变量**再判空。下面这个函数就是标准写法，直接复制使用。
-- =============================================================================================
local function NumProp(pPlayer, key, default)
    if pPlayer == nil then return default; end
    local v = pPlayer:GetProperty(key);
    if v == nil then return default; end
    return tonumber(v) or default;
end

-- 框架全局名：HotaruVictoryFramework
HotaruVictoryFramework.Register({

    -- ===================== 必填 =====================
    VictoryType = "VICTORY_XXX",        -- 与 DB 表 Victories.VictoryType 完全一致

    -- ===================== 可选 =====================
    -- 页签短名。留空则用 Victories.Name 的本地化文本作为页签标签。
    -- 可用 LOC 键（如 "LOC_MYVICTORY_TAB"）或已本地化字符串。
    TabName = nil,

    -- false = 隐藏式胜利：不建页签、不进总览（如"突然达成"类胜利）。
    -- 默认 true。
    Visible = true,

    -- 图标名。留空 / nil 则回退原版通用图标 ICON_VICTORY_GENERIC。
    -- ⚠ 若填写，须是你自己用 UpdateIcons 注册过的图标名。
    Icon = nil,

    -- 直接贴图的纹理文件名（如 "MY_ICON_80.dds"）。
    -- ⚠ 只有 IconManager 解析不到你的图标时才需要填（此时框架会直接把这张 dds 贴到页头）。
    -- 生效条件：Icon 字段填了对应图标名，框架靠它匹配到你这个 Provider。
    HeaderIcon = nil,

    -- ---------------- 总览(Overall)页 ----------------
    -- ⚠ 参数约定与官方 g_victoryData 完全一致：收到的是 **Player 对象**，不是 playerID。
    --    例：function(p) return p:GetStats():GetDiplomaticVictoryPoints() end

    -- 排序键：数值越大越靠前
    GetScore = function(p)
        return 0;
    end,

    -- 总览页该胜利行的文本
    -- ⚠ 返回 **LOC 键**（不是已本地化的串）。官方会做
    --    Locale.Lookup(键, 分数)，所以你的文本里要写 {1_Score} 占位符，
    --    例如 LOC_XXX_OVERVIEW_SCORE = "我的积分：{1_Score}"。
    --    若返回已 Locale.Lookup 过的串，分数不会被代入（只显示文字、没有数字）。
    GetText = function(p)
        return "LOC_XXX_OVERVIEW_SCORE";
    end,

    -- 总览页补充摘要（可留空）
    Summary = function(p)
        return "";
    end,

    -- ---------------- 行级后处理（可选）----------------
    -- 官方行渲染完成后调用，用来覆盖 Details 文本 / tooltip / 行高。
    -- 与 View 可并用：View 管整页布局（如排序），PopulateRow 管每一行。
    --
    -- 💡 框架会在调用本函数**之前**自动清空 ButtonBG 的 tooltip
    --    （官方有潜伏 bug：外交胜利页签会给 ButtonBG 设 tooltip，而实例池跨页签复用
    --      且官方从不清理 → 从有 tooltip 的页签切到没 tooltip 的页签会串）。
    --    所以：**你要 tooltip 就在这里设**，不设就保持干净，不会串到别的胜利。
    --
    -- ⚠ 不要在里面再调用 PopulateGenericInstance（会无限递归）。
    PopulateRow = function(instance, playerData, victoryType, showTeamDetails)
        -- instance.Details:SetText("...");
        -- instance.ButtonBG:SetToolTipString("...");   -- 要 tooltip 就写这行
        -- instance.ButtonBG:SetSizeY(math.max(60, instance.Details:GetSizeY() + 25));
    end,

    -- ---------------- 自定义页签视图 ----------------
    -- 不提供则使用官方通用视图（显示 RequirementStrings 里
    -- Context="VictoryProgress" 的进度文本）。
    --
    -- 提供时，框架会在用户点击你的页签时调用它。
    -- 建议照官方 ViewGeneric 的骨架来写（见下方示例）。
    View = function(victoryType)
        -- ★ 下面是一份可直接套用的骨架：
        ResetState(function() ViewGeneric(victoryType); end);
        Controls.GenericView:SetHide(false);
        ChangeActiveHeader("GENERIC", m_GenericHeaderIM, Controls.GenericViewHeader);

        local victoryInfo = GameInfo.Victories[victoryType];
        if victoryInfo ~= nil then
            PopulateGenericHeader(RealizeGenericStackSize,
                victoryInfo.Name, nil, victoryInfo.Description,
                victoryInfo.Icon or ICON_GENERIC);
        end

        g_GenericIM:ResetInstances();
        g_GenericTeamIM:ResetInstances();

        local genericData = GatherGenericData();
        for _, teamData in ipairs(genericData) do
            if #teamData.PlayerData > 1 then
                PopulateGenericTeamInstance(g_GenericTeamIM:GetInstance(), teamData, victoryType);
            else
                PopulateGenericInstance(g_GenericIM:GetInstance(),
                    teamData.PlayerData[1], victoryType, true);
            end
        end

        RealizeGenericStackSize();
    end,
});
