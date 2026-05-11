<!-- TODO: 加 docs/banner.png -->

<h1 align="center">easy-git</h1>
<p align="center">让 AI Agent 替你搞定 Git — Agent Skills 标准 Skill</p>
<p align="center">自动 commit + push · .gitignore 自动管理 · Worktree 全流程 · 人话翻译 · 安全护栏</p>

---

> **Status**：立项中（2026-05）／ PRD 已稳定 ／ SKILL.md 与 references 实现中 ／ 还不能直接安装。进展见 [`docs/prd.md`](docs/prd.md)。

## 它解决什么

跟 AI Agent 一起干活，两件最痛的事：

- **Agent 一通改了 20 个文件，想回到 10 分钟前 — 回不去。** 没人替你存过节点，靠记忆手动撤是不现实的。AI 写得越快，没有版本管理的代价越大。
- **想用 Git 兜底？** staging / branch / merge / rebase / reset 软硬混合三种模式…… 教程看到第三集还卡在第一个概念里：「我只是想存个进度啊。」

easy-git 在你和 Git 之间架一层 —— 你只管说人话，Git 透明。

## 功能

| 能力 | 触发条件 | Agent 替你做 |
|------|------|------|
| 自动 commit + push | 一段工作完成 | 按语义拆原子 commit，写 [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) 风格 message，同步到远端 |
| `.gitignore` 自动管理 | 仓库缺 `.gitignore` / 命中脏文件 | 建 / 补 `.gitignore`，拦掉依赖目录 / 构建产物 / 密钥 / IDE 配置 |
| Worktree 管理 | 用户说"加个新功能 …" | 自动开 worktree + 新分支；做完问 (a) 合并清理 (b) 提 PR (c) 暂留 |
| 人话翻译 | 任何 git 行为 | "保存了一段进度" / "另起一条线做" / "回到 10 分钟前那个保存点"，不堆 git 术语 |
| 安全护栏 | 危险动作触发 | `force push` 到 main / `reset --hard` / 密钥入库 / `git add -A` 等拦下来问 |

## 技术栈

- **Skill 标准**：[Agent Skills 开放标准（agentskills.io）](https://agentskills.io/specification)，跟 MCP 无关，跨 32+ AI Agent 工具
- **Commit 规范**：[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
- **底层**：[Git](https://git-scm.com/) + [git-worktree](https://git-scm.com/docs/git-worktree)
- **兼容 Agent**：Claude Code · Codex CLI · Cursor · GitHub Copilot · Gemini CLI · Junie · Goose · Amp · TRAE · ……

## 快速开始

```bash
# Claude Code 中：
/plugin marketplace add xz1220/easy-git
/plugin install easy-git
```

其他兼容 Agent 按各自的 skill 安装机制，详见 [PRD 安装章节](docs/prd.md#安装)。装完之后什么都不用做，AI Agent 会自己在合适时机调用。

## 实际用起来是什么样

### 场景一：Agent 改坏了，想回到上一个完好的版本

**没装 easy-git**：

```
你：帮我把搜索功能优化一下
Agent：好，改了 12 个文件……
你：等等，效果比之前还差，能恢复原来的代码吗？
Agent：抱歉我没存过保存点，需要你逐个文件回想……
```

**装了 easy-git**：

```
你：帮我把搜索功能优化一下
Agent：改了 12 个文件，已经存了一笔并同步到 GitHub。
你：效果不对，回到上一个版本
Agent：好，已经回退到刚才那个保存点了。
```

### 场景二：加个新功能不敢动主分支，但又不会 worktree

**没装 easy-git**：

```
你：帮我加一个用户登录功能
Agent：（直接在当前分支改）改了 30 个文件
你：等等，你应该开个分支再做啊
Agent：抱歉我现在 reset 一下重来……
```

**装了 easy-git**：

```
你：帮我加一个用户登录功能
Agent：这个改动比较大，我另起一条线 feat-user-login 做，
       已经切到 ~/repos/my-app-feat-user-login 了。
       做完之后我会问你怎么合回去。
```

## 仓库结构

```
easy-git/
├── SKILL.md            # 主 skill 文件（v0 待写，按 Agent Skills 规范）
├── references/
│   ├── translation.md  # 翻译词表（来自 Git 官方 giteveryday）
│   ├── commit-style.md # Conventional Commits 规范 + 公开范例库
│   ├── worktree-flow.md # worktree 生命周期 + 命名规则
│   └── hook-recovery.md # pre-commit hook 失败恢复流程
├── scripts/            # 安全检测脚本（secret 扫描、大文件扫描）
├── docs/prd.md         # 完整需求与设计
├── README.md
└── LICENSE
```

## Roadmap

- [x] PRD v4 稳定
- [x] User Story 风格 README
- [ ] 做 `docs/banner.png`
- [ ] 写 `SKILL.md`（按 Agent Skills 规范）
- [ ] `references/translation.md`（按 [giteveryday](https://git-scm.com/docs/giteveryday) 全量梳理翻译词表）
- [ ] `references/commit-style.md`（[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) + 公开范例）
- [ ] `references/worktree-flow.md`
- [ ] `references/hook-recovery.md`
- [ ] 测试 fixture（空 sandbox + dry-run 命令集）
- [ ] 详细对比 [netresearch/git-workflow-skill](https://github.com/netresearch/git-workflow-skill) 等同类 skill，确认差异化
- [ ] 发布到 Agent Skills marketplace

详见 [`docs/prd.md`](docs/prd.md)。

## License

MIT
