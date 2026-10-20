# 接入框架 · ModBuddy 操作对照

> 只讲"在 ModBuddy 里点哪里"，不贴 modinfo 源码。
> 手写 modinfo 的人也能看懂：本质就是"加一个 ImportFiles、加一条 Dependencies、删掉 ReplaceUIScript"。

---

## 一、Associations 页

1. **Rulesets**：勾选你的 MOD 支持的规则集（标准 / 风云变幻）。框架依赖风云变幻，走框架就勾 GS。
2. **Dependencies**：点添加，选 **草之爹的胜利框架**（GUID `bb597752-5b2d-425e-b9a0-f9e4d257d0be`）。
   加了这个，游戏会保证框架先于你的 MOD 加载。

---

## 二、Actions 页

### 2.1 要加的：一条 ImportFiles

| 位置 | Action 类型 | 挂什么 |
|---|---|---|
| **InGameActions** | **ImportFiles** | 你的 `HotaruVictoryFramework_Provider_<VictoryType>.lua` |

> 为什么必须是 ImportFiles：框架用 `include()` 读你的文件，而只有 ImportFiles 挂过的文件
> 才会进运行时文件系统。光把文件加进工程、不挂这个 Action，框架会找不到你。

### 2.2 要删的：针对 WorldRankings 的 ReplaceUIScript

如果你原来有这么一条（把官方的世界排名脚本换成自己的）：

| 位置 | Action 类型 | 处理 |
|---|---|---|
| InGameActions | **ReplaceUIScript**，LuaContext = `WorldRankings` | **整条删掉** |

理由：这个槽位是**单赢家**的，框架已经占用了。你再加一条，就是两个 MOD 抢同一个位置，
谁赢取决于加载顺序 —— 表现是"有时候正常有时候不正常"，极难排查。

### 2.3 不用动的

- 你原有的 `UpdateDatabase` / `UpdateText` / `UpdateIcons` / `AddGameplayScripts`：全部保持原样。
- 你原来替换脚本里的业务逻辑：搬到 Provider 文件里（对照见 `3_接入步骤.md` §一）。

---

## 三、加完之后的检查清单

- [ ] Dependencies 里有「草之爹的胜利框架」
- [ ] InGameActions 里有 ImportFiles，且挂的是你的 Provider 文件
- [ ] Provider 文件名 = `HotaruVictoryFramework_Provider_` + `VictoryType`，逐字符一致
- [ ] 原来的 WorldRankings `ReplaceUIScript` 已删除
- [ ] 编译后进游戏，`Lua.log` 里出现 `[HotaruVictoryFramework] 已登记 Provider: VICTORY_XXX`
- [ ] 世界排名页出现你的页签，点击后内容正确
- [ ] 和另一个也用框架的胜利 MOD 同时启用，两个页签都在
