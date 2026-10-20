-- =============================================================================================
-- 结束菜单样式（可选，三档都可用）
--
-- 加载机制：官方 EndGameMenu.lua 最后一行是  include("EndGameMenu_", true)
--           —— 第二个参数 true = **前缀匹配加载**，所以任何名为 EndGameMenu_*.lua 的文件
--           都会被自动收进 EndGameMenu 上下文。
--           Styles 表是**追加式**的 → 多个 MOD 各写各的，天然不冲突。
--           所以这一层**不需要框架**，直接按约定命名即可。
--
-- 字段说明（全部可选，缺省走 GENERIC_VICTORY）：
--   RibbonIcon / Ribbon / RibbonTile / Background / Color  → 视觉
--   Movie      → 胜利影片（.bk2 文件名，**可以写成一个函数**做动态选择）
--   SndStart / SndStop → 音频事件名，**只能复用官方已有事件**
--   FadeOutTime → 背景淡出秒数
-- =============================================================================================

-- ---------------------------------------------------------------------------------------------
-- Tier 0 示例：全部走原版资源（最省事，零美术投入）
-- ---------------------------------------------------------------------------------------------
Styles["VICTORY_TPL_TIER0"] = {
    RibbonIcon = "ICON_VICTORY_GENERIC",
    Ribbon     = "EndGame_Ribbon_Time",
    RibbonTile = "EndGame_RibbonTile_Time",
    Background = "EndGame_BG_Time",
    Color      = "COLOR_VICTORY_DEFAULT",
    -- Movie 不填 → 不播放影片，只显示结算画面
};

-- ---------------------------------------------------------------------------------------------
-- Tier 1 示例：借用官方的"时间胜利"影片与音效
--   ⚠ SndStart / SndStop 只能填**官方已有**的音频事件名，可选值：
--     Play_Cinematic_Endgame_Time / Science / Culture / Domination / Religion / Defeat
--     （对应 Stop_ 前缀的同名事件）
--   自定义新事件需要改 Wwise 音库，超出常规 MOD 范围。
-- ---------------------------------------------------------------------------------------------
Styles["VICTORY_TPL_TIER1"] = {
    RibbonIcon = "ICON_VICTORY_GENERIC",
    Ribbon     = "EndGame_Ribbon_Time",
    RibbonTile = "EndGame_RibbonTile_Time",
    Background = "EndGame_BG_Time",
    Movie      = "Time.bk2",
    SndStart   = "Play_Cinematic_Endgame_Time",
    SndStop    = "Stop_Cinematic_Endgame_Time",
    Color      = "COLOR_VICTORY_DEFAULT",
    FadeOutTime = 3,
};

-- ---------------------------------------------------------------------------------------------
-- Tier 2 示例：自制影片（把下面注释打开，并把你自己的 .bk2 放进
--             Platforms/Windows/Movies/ 后在 modinfo 里 ImportFiles）
--
--   ⚠ 语言问题：音频烧进 Bk2 = 单语言；想多语言就得复用官方事件。
--   ⚠ 字幕问题：原版可能存在与影片同名的字幕文件（引擎侧按文件名绑定）。
--              若要自制字幕，请先确认其确切文件名与路径。
--   💡 Movie 可以是函数：Movie = function() return "你的影片.bk2"; end
-- ---------------------------------------------------------------------------------------------
Styles["VICTORY_TPL_TIER2"] = {
    RibbonIcon = "ICON_VICTORY_GENERIC",
    Ribbon     = "EndGame_Ribbon_Time",
    RibbonTile = "EndGame_RibbonTile_Time",
    Background = "EndGame_BG_Time",
    -- Movie   = "YourVictory.bk2",
    -- SndStart = "Play_Cinematic_Endgame_Time",
    -- SndStop  = "Stop_Cinematic_Endgame_Time",
    Color      = "COLOR_VICTORY_DEFAULT",
};
