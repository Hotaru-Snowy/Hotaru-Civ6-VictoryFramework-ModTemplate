# 草之爹的文明6胜利MOD模板

> **前景提要**：默认你会做基础的文明 6 MOD —— 比如做过一个"新单位"MOD，至少知道个大概。如果你完全没接触过，建议丢给AI。

---

## 〇、框架MOD的意义

### 0.1 撞车点只有一个：世界排名页

游戏里"世界排名"那一页是官方 UI，由一个 Lua 脚本（WorldRankings 上下文）驱动。
新的胜利想要自定义**页签**、**页面**，就需要替换这个lua脚本，然后修改里面的内容。当装两个都想改页签的胜利 MOD，后加载的那个赢，而另一个的页签可能会消失或者显示内容原版化了，导致了冲突。

### 0.2 但你可以完全不碰它

胜利 MOD 完全可以**只写数据库**：

- 官方 `PopulateTabs()` 会自动遍历 `GameInfo.Victories()`，给**任何**自定义胜利建一个通用页签；
- 页签上的进度文本，取你在 `RequirementStrings` 里注册的 `VictoryProgress` 那一行。

这条路**零 UI 代码、零冲突**，也不需要本框架。

### 0.3 框架解决的是"我就要自定义页签，而且要能和别人共存"

框架做的事只有一件：**把那个唯一槽位抢过来，改造成一个共享注入点**。

| | 没有框架 | 有框架 |
|---|---|---|
| 谁抢槽位 | 每个胜利 MOD 都抢 | **只有框架抢** |
| 你的 MOD 要做什么 | 写一整份 UI 替换脚本 | 交一个 **Provider** 文件，声明"我的页签长这样" |
| 两个 MOD 同装 | 后加载者赢，另一个消失 | 框架按胜利类型分发，**各自页签都在** |

所以判断标准很简单：

> **你要不要改页签？**
> 不改 → 不用装框架，看完第一章就够了。
> 要改 → 装框架，按第三章接入。

---

## 一、一个基础胜利 MOD 需要哪些东西

### 1.1 五个必需部件

| # | 部件 | 写在哪 | 干什么 | 要填什么 |
|---|---|---|---|---|
| 1 | **类型注册** `Types` | XML | 告诉引擎"有这么个胜利类型" | `Type="VICTORY_XXX"`、`Kind="KIND_VICTORY"` |
| 2 | **胜利定义** `Victories` | XML | 这条胜利叫什么、什么条件算赢 | `VictoryType` / `Name` / `Blurb` / `Description` / `RequirementSetId` / `CriticalPercentage` |
| 3 | **判定条件** | XML | 引擎据此判断"达成没有" | 四张表：`RequirementSets` / `Requirements` / `RequirementArguments` / `RequirementSetRequirements` |
| 4 | **进度文本** `RequirementStrings` | XML | 页签上显示的那句话 | `RequirementId` + `Context="VictoryProgress"` + 文本键 |
| 5 | **本地化** `LocalizedText` / `BaseGameText` | XML | 把上面那些 LOC 键变成人话 | 胜利名 / 简介 / 描述 / 进度文本 |

**逐项说明：**

**① 类型注册**

```xml
<Types>
  <Row Type="VICTORY_MYVICTORY" Kind="KIND_VICTORY"/>
</Types>
```

`Kind` 必须是 `KIND_VICTORY`，否则不会出现在胜利列表里。

→ 在 **InGameActions** 里用 **UpdateDatabase** 载入。

**② 胜利定义**

```xml
<Victories>
  <Row VictoryType="VICTORY_MYVICTORY"
       Name="LOC_VICTORY_MYVICTORY_NAME"
       Blurb="LOC_VICTORY_MYVICTORY_BLURB"
       Description="LOC_VICTORY_MYVICTORY_DESC"
       RequirementSetId="REQSET_MYVICTORY"
       CriticalPercentage="100"/>
</Victories>
```

- `RequirementSetId` 指向第 ③ 步那套条件，**这是唯一的判胜依据**；
- `Icon` 不写就用通用图标；
- `CriticalPercentage` 填 100 最省事（"达成即赢"，不做中途提示）。

→ 在 **InGameActions** 里用 **UpdateDatabase** 载入（和类型注册放同一个 Action，按顺序执行）。

**③ 判定条件（四张表，缺一不可）**

```xml
<RequirementSets>
  <Row RequirementSetId="REQSET_MYVICTORY" RequirementSetType="REQUIREMENTSET_TEST_ALL"/>
</RequirementSets>

<Requirements>
  <Row RequirementId="REQ_MYVICTORY" RequirementType="REQUIREMENT_PLAYER_HAS_BUILDING"/>
</Requirements>

<RequirementArguments>
  <Row RequirementId="REQ_MYVICTORY" Name="BuildingType" Value="BUILDING_BIG_BEN"/>
</RequirementArguments>

<RequirementSetRequirements>
  <Row RequirementSetId="REQSET_MYVICTORY" RequirementId="REQ_MYVICTORY"/>
</RequirementSetRequirements>
```

集合 → 条件 → 参数 → 把条件挂进集合。上面这个例子是"拥有大本钟即胜利"。

**这条链指向什么，就决定了你的胜利靠什么达成** —— 见 §1.3。

→ 在 **InGameActions** 里用 **UpdateDatabase** 载入。

**④ 进度文本（最容易漏，漏了很丑）**

```xml
<RequirementStrings>
  <Row RequirementId="REQ_MYVICTORY" Context="VictoryProgress" Text="LOC_MYVICTORY_PROGRESS"/>
</RequirementStrings>
```

不写这行，官方通用页签会退化成显示内部常量（一串英文 ID）。
（对于有些REQ，写了这行也还是很丑，这也是为什么要自定义页签。）

→ 在 **InGameActions** 里用 **UpdateDatabase** 载入。

**⑤ 本地化**

**每种语言一个文件**：英文走 `BaseGameText`，其它语言用 `LocalizedText` + `Replace`。

```xml
<!-- Text/MyVictory_en_us.xml -->
<GameData>
  <BaseGameText>
    <Row Tag="LOC_VICTORY_MYVICTORY_NAME"><Text>My Victory</Text></Row>
    <Row Tag="LOC_MYVICTORY_PROGRESS"><Text>Condition met</Text></Row>
  </BaseGameText>
</GameData>
```

```xml
<!-- Text/MyVictory_zh_hans_cn.xml -->
<GameData>
  <LocalizedText>
    <Replace Tag="LOC_VICTORY_MYVICTORY_NAME" Language="zh_Hans_CN"><Text>我的胜利</Text></Replace>
    <Replace Tag="LOC_MYVICTORY_PROGRESS" Language="zh_Hans_CN"><Text>已达成条件</Text></Replace>
  </LocalizedText>
</GameData>
```

→ **FrontEndActions 与 InGameActions 各用一条 UpdateText**，把**所有**语言文件都列进去
（开始界面也要显示这些文字）。

### 1.2 三个可选的

**① 开始界面勾选框**（想让玩家能开关这条胜利时才要）

注意这是 **Configuration 数据库**，不是上面那个 Gameplay 数据库：

```xml
<Victories>
  <Row Domain="Expansion2_Victories" VictoryType="VICTORY_MYVICTORY"
       Name="LOC_VICTORY_MYVICTORY_NAME" Description="LOC_VICTORY_MYVICTORY_DESC"/>
</Victories>
```

`Domain` 决定它出现在哪个规则集的勾选列表里：
`Expansion2_Victories`（只在风云变幻） / `StandardVictories`（只在标准） / 两个都写（两边都出现）。
不注册这里 → 高级设置里没有你的开关，玩家关不掉它。

→ 在 **FrontEndActions** 里用 **UpdateDatabase** 载入。

**② 图标**（不想用通用图标时才要）

→ 用 **UpdateIcons** 载入。

**③ 判定脚本**（只有虚拟建筑路线需要）

→ 用 **AddGameplayScripts** 载入，写在 §1.3 的 D 路线里。

### 1.3 先定判定方式（四条路线）

| 路线 | 条件指向什么 | 要写脚本吗 | 官方同类例子 |
|---|---|---|---|
| **A 真实建筑 / 奇观** | `REQUIREMENT_PLAYER_HAS_BUILDING` → 玩家能造的建筑 | ❌ | 官方没拿它做胜利，但这是标准条件类型 |
| **B 完成项目** | `REQUIREMENT_PLAYER_HAS_COMPLETED_PROJECT` → `ProjectType` | ❌ | **科学胜利**（太空项目） |
| **C 点数 / 计数** | `REQUIREMENT_PLAYER_HAS_SCIENCE_VICTORY_POINTS`、`REQUIREMENT_TEAM_HAS_HIGHEST_SCORE` 等 | ❌ | **分数胜利**、**GS 科学胜利** |
| **D 虚拟建筑** | `REQUIREMENT_PLAYER_HAS_BUILDING` → `InternalOnly=1` 的隐藏建筑 | ✅ | 无（官方用不上） |

**A/B/C 由引擎自己判**，你只要把条件写对，玩家满足的那一回合引擎就判胜。

顺带一提，不是所有REQ都可以用来判定胜利的，就算有RequirementStrings也不能很好的显示。除了上面的内容以外其他的只能请大家自行摸索了。

**D 是曲线救国**：Lua 每回合算真实条件，达成时给玩家塞一个标记建筑，引擎按"拥有建筑"判胜。
当你的规则**引擎表达不了**（要遍历地图、要跨回合累积、要按自定义积分算）时就可以走 D。

D 要做三件事：`Types` 里注册 `BUILDING_MYVICTORY_VICTORY`（`Kind="KIND_BUILDING"`）；
建这张建筑时设 `InternalOnly="1" MustPurchase="1" Cost="100000"`；条件写成
`REQUIREMENT_PLAYER_HAS_BUILDING` 指向它，脚本在达成时把它塞给玩家：

```lua
-- Script/MyVictory_Gameplay.lua（每回合算一次）
VictoryCore.GrantVictory(playerID, "BUILDING_MYVICTORY_VICTORY", cityID);
```

`VictoryCore` 由框架提供（会做城市回退、幂等去重、DB 缺失兜底）；不装框架也能写，
自己 `CreateBuilding` 即可，`Script/TPL_Gameplay.lua` 末尾有一行说明。

本模板的三个示例演示了 A 和 D 两种路线：`TIER0` 用大本钟（A，无脚本），`TIER1` / `TIER2` 用标记建筑（D，有脚本）。

---

## 二、在 ModBuddy 里走一遍

> 这一章讲的是**在文明 6 的 MOD 制作器（ModBuddy）里点哪里**，不是手写 modinfo。
> 不同版本的中文菜单叫法可能略有差异，按位置找即可。

**Step 1 · 新建工程**

`文件 → 新建 → 项目` → 选 **Civilization VI** → 模板 **Empty Mod** → 名字填 `MyVictory`。

> 不想从零建？直接双击本模板的 `Hotaru_Victory_Template.civ6proj`，看现成的工程长什么样。

**Step 2 · 加文件，并给每个文件挂载入方式**

右键工程 → `添加 → 新建项`：

| 文件 | 内容 | 怎么载入 |
|---|---|---|
| `Data/MyVictory_Types.xml` | 类型注册 | InGameActions → UpdateDatabase |
| `Data/MyVictory_Victories.xml` | 定义 + 条件 + 进度文本 | InGameActions → UpdateDatabase（和上一条放同一个 Action） |
| `Config/MyVictory_Config.xml` | 开始界面勾选框 | FrontEndActions → UpdateDatabase |
| `Text/MyVictory_en_us.xml` + `_zh_hans_cn.xml` … | 本地化（每语言一个文件） | FrontEndActions + InGameActions 各一条 UpdateText |
| `Script/MyVictory_Gameplay.lua` | 判定脚本（仅 D 路线） | InGameActions → AddGameplayScripts |

> **在工程里加了文件 ≠ 它会被加载。** 真正让它生效的是 Action —— 没挂 Action 的文件只是躺在包里。

**Step 3 · Mod Info 与 Associations**

打开模组信息设计器：**Mod Info** 页填 Name、Description、Teaser、Authors（先填纯文本就行，
以后想本地化再换成 LOC 键）；**Associations** 页勾选支持的规则集 ——
只支持标准就勾标准，用了风云变幻的内容就勾 **Gathering Storm**，勾错了游戏里直接看不到这个 MOD。

**Step 4 · 编译验证**

`生成 → 生成解决方案`。成功后 MOD 出现在 `文档\My Games\Sid Meier's Civilization VI\Mods\MyVictory`。

游戏里：`附加内容 → 模组` 启用它 → 新游戏 → **高级设置**里应该能看到"我的胜利"勾选框 →
进游戏打开**世界排名**，应该有一个"我的胜利"页签，进度文本就是你在 `RequirementStrings` 里写的那句。

> **没看到页签？** 按顺序查：MOD 启用没有 → 资料片勾选对不对 → `Types` 有没有生效 →
> `Victories` 里的 `RequirementSetId` 和实际集合名是否**逐字符**一致。

---

## 三、想自定义页签：接入框架

回到 §0.1：进入世界排名脚本的通道是 `ReplaceUIScript`，**单赢家**。
所以"N 个 MOD 各自包装一下就兼容"行不通 —— 第二个人照做就把第一个人顶掉。
框架就是把那条通道**抢一次**，对外开一个注入点。

### 3.1 三步

**① 写 Provider 文件**

复制 `接入指南/1_Provider模板.lua`，改名为：

```
HotaruVictoryFramework_Provider_<你的VictoryType>.lua
```

> 文件名必须**严格等于** `"HotaruVictoryFramework_Provider_" .. VictoryType`。
> 框架不读注册表，它是遍历 `GameInfo.Victories()` 后按这个约定去 `include` 你的文件。

**② 在 ModBuddy 里挂上**

| 在哪 | 做什么 |
|---|---|
| Associations → Dependencies | 加上「草之爹的胜利框架」 |
| Actions → InGameActions → **ImportFiles** | 加入你的 Provider 文件 |

> 必须要 ImportFiles：框架要用 `include()` 读你的文件，只有 ImportFiles 挂过的文件才在运行时文件系统里。

**③ 填字段**（见 3.2）。什么都不填也能跑，会得到一个和官方通用页签一样的页签。

### 3.2 字段

| 字段 | 必填 | 作用 | 注意 |
|---|---|---|---|
| `VictoryType` | ✅ | 对应哪条胜利 | 与文件名后缀逐字符一致 |
| `TabName` | | 页签短名 | 留空用 `Victories.Name` |
| `Visible` | | `false` = 隐藏式胜利 | 不建页签、不进总览 |
| `Icon` / `HeaderIcon` | | 页签图标 / 直接贴的 dds | 留空回退通用图标 |
| `GetScore(p)` | | 总览页排序键 | 收到的是 **Player 对象** |
| `GetText(p)` | | 总览页那行文字 | ⚠ **返回 LOC 键**，见 3.3 |
| `Summary(p)` | | 总览页补充摘要 | 可返回已本地化串 |
| `PopulateRow(...)` | | 每行的文字 / tooltip / 行高 | 官方渲染完之后调用 |
| `View(victoryType)` | | 整页布局（排序、页头） | 不写则用官方通用布局 |

```lua
HotaruVictoryFramework.Register({ ... });
```

### 3.3 两个坑

**`GetText` 要返回键，不要返回本地化后的串。**

官方会做 `Locale.Lookup(GetText(p), 分数)`。你若已经 lookup 过，第二次是空操作，**分数就丢了** ——
表现为总览页只有文字、没有数字。所以返回 `"LOC_MYVICTORY_OVERALL"`，文本里写 `{1_Score}`。

**读玩家属性不要直接套 `tonumber`。**

```lua
-- ❌ 属性未设置时 GetProperty 返回"零个返回值"，于是变成 tonumber() 无参调用
local v = tonumber(p:GetProperty("MY_PROP")) or 0;

-- ✅ 先落局部变量再判空
local raw = p:GetProperty("MY_PROP");
local v = (raw ~= nil) and (tonumber(raw) or 0) or 0;
```

报错长这样：`bad argument #1 to 'tonumber' (value expected)`，而且发生在 `tonumber` 内部，`or 0` 兜不住。
Provider 模板顶部已经内置了 `NumProp()`，直接用它。

---

## 四、模板文件与示例

> 本目录自带 **`Hotaru_Victory_Template.civ6proj`** —— 用 ModBuddy 直接打开它就能编译，
> 所有 Action、依赖、本地化都配好了。编译时会自动生成 modinfo，不用手写。

| 文件 | 作用 |
|---|---|
| `Hotaru_Victory_Template.civ6proj` | ModBuddy 工程（Action / 依赖 / 模组信息都在这里） |
| `Data/TPL_Types.xml` | 类型注册 |
| `Data/TPL_Victories.xml` | 定义 + 条件 + 进度文本 + 标记建筑 + AI 策略 |
| `Config/TPL_Config.xml` | 开始界面勾选框 |
| `Text/en_us.xml` / `zh_hans_cn.xml` / `zh_hant_hk.xml` | 本地化文本（每语言一个文件） |
| `Script/TPL_Gameplay.lua` | 判定脚本（只有 TIER1/TIER2 用） |
| `UI/HotaruVictoryFramework_Provider_VICTORY_TPL_TIER1.lua` | Provider：只填 `GetScore` / `GetText` |
| `UI/HotaruVictoryFramework_Provider_VICTORY_TPL_TIER2.lua` | Provider：`PopulateRow` + `View` |
| `EndGame/EndGameMenu_VICTORY_TPL.lua` | 结束菜单样式（可选） |
| `接入指南/1_Provider模板.lua` | 复制改名即用的空壳 |
| `接入指南/2_ModBuddy操作对照.md` | 在 ModBuddy 里加哪些 Action、删哪些 |
| `接入指南/3_接入步骤.md` | 迁移对照 + 校验清单 + 共存说明 |

三个示例胜利，故意用了两种判定方式：

| 示例 | 判定方式 | 界面 | 要脚本吗 |
|---|---|---|---|
| `VICTORY_TPL_TIER0` | A 路线：拥有大本钟 | 官方通用页签 | ❌ |
| `VICTORY_TPL_TIER1` | D 路线：隐藏标记建筑 | Provider 改总览排序 | ✅ |
| `VICTORY_TPL_TIER2` | D 路线：隐藏标记建筑 | Provider 自定义页签 | ✅ |

`Data/TPL_Victories.xml` 末尾有 A/B/C 三条路线的注释示例。

**想快速看效果**：把 `Script/TPL_Gameplay.lua` 顶部的 `TEST_TURN` 改成 2，第 2 回合 TIER1 / TIER2 自动判胜。

**注意事项**

- `RequirementStrings` 别漏，否则页签显示内部常量。
- 要 `include` 的 lua 必须用 ImportFiles 挂，只放工程里不算。
- 装了框架就别再 `ReplaceUIScript` WorldRankings。
- 结束菜单是追加式的：`EndGameMenu_*.lua` 由官方脚本按前缀自动加载，多个 MOD 各写各的，天然不冲突。
- 多语言：**每种语言一个文件**。英文走 `BaseGameText`，其它语言走 `LocalizedText` + `Replace`；
  `UpdateText` 里把所有语言文件都列进去（FrontEnd 与 InGame 各一条）。
