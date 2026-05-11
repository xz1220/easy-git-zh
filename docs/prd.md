# easy-git-zh PRD

## 1. 我们要做什么

### 目标

做一个符合 **[Agent Skills 开放标准](https://agentskills.io/specification)** 的 skill。把 Git 这一层的复杂度对用户屏蔽掉 —— 让任何在用 Agent 的人，不需要深入理解 Git（最多懂几个最简单的概念，甚至完全不懂）就能直接用上版本管理的能力。

### 为什么需要

Git 是软件工程通用基础设施，但它的概念非常技术化：staging area、commit/push/pull、branch/merge/rebase、reset 三种模式、本地 vs 远端…… 仅这些已经够劝退非工程用户。普通用户的现实是：

- 想用 Agent 写代码 / 写文档 / 做创作，需要版本管理来兜底（不丢工作、能回滚、能多线并行）
- 但学 Git 的成本远大于他们想付出的成本
- 让 Agent 一步步教自己用 Git，每个对话都要重复「commit 一下 push 一下」也很啰嗦

easy-git-zh 在用户与 Git 之间架一层 —— 用户用日常表达描述目标，Agent 在合适时机自动调用 Git 能力，并用清楚的话回报结果。

### 目标用户

**所有用 Agent 工作的用户**，不限于开发者：

- 写代码的（开发者）
- 写文档 / PRD / 笔记的（产品经理、运营、研究者）
- 做创作的（写作、博客、设计稿）
- 用 Agent 管个人项目的（任何不想被 Git 绊倒的人）

只要你在用 Agent，且想让自己的工作有版本管理兜底，easy-git-zh 就该让这件事对你**透明**。

## 2. 功能、安装、怎么用

### 主要功能（一句话版）

1. **自动 commit + push** —— 一段工作完成时自动保存进度、同步到远端，原子化拆分
2. **仓库初始化与 `.gitignore` 自动管理** —— 非 git 目录主动 `git init`；维护忽略列表，常见不该提交的文件（依赖目录、构建产物、密钥）默认拦掉
3. **Commit message 标准化** —— Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) 公开规范，不让用户操心格式
4. **Worktree 管理**（复杂项目）—— 新 feature 自动开 worktree + 新分支；做完问用户怎么合并
5. **自然语言交互层** —— 用户面尽量不暴露 Git 术语
6. **安全护栏** —— 危险操作（force push、reset --hard、commit secret 等）永不主动做

### 安装

easy-git-zh 是符合 [Agent Skills 开放标准](https://agentskills.io/specification) 的 skill，跟 MCP 无关。32+ AI Agent 工具（Claude Code、Codex、Cursor、GitHub Copilot、Gemini CLI、Junie、Goose、Amp、TRAE 等）都支持这个标准，**装一次多个 Agent 都能用**。

**主推渠道**（Agent Skills 官方）：

- Claude Code：`/plugin marketplace add xz1220/easy-git-zh` + `/plugin install easy-git-zh`
- Claude.ai：UI 上传
- Claude API：Skills API 注册
- 其他兼容 Agent：各自的 skill 安装机制

**辅助渠道**：

- 第三方 npx 安装器（如 `npx skills install xz1220/easy-git-zh`，对偏好 npx 的用户）
- 直接 `git clone` 到 Agent 的本地 skill 目录

### 用户怎么用

**短答**：装完不用做任何事。easy-git-zh 装好后，Agent 在跟用户对话的任何时机自己判断要不要调用 Git，举例：

- 你写完一段文档 → Agent 替你保存并同步到 GitHub，回报 "我把这段保存了并同步到 GitHub 了"
- 你说「加一个新功能 …」→ Agent 替你另起一条线工作，回报 "我另起一条线 `feat-xxx` 在 `<目录>` 做这件事"
- 你的新目录里全是构建产物 → Agent 自动加进 `.gitignore`，告诉你 "我让 Git 忽略 `dist/` 这个目录"
- 你说「这个改回去」→ Agent 用 git 帮你回退到上一个保存点（不让你接触 reset 概念）

**少数需要用户决策的场景，Agent 会主动问**：

- worktree 上的新 feature 做完了 → "这条线做完了，你想 (a) 直接合并清理 (b) 提个 PR review 一下 (c) 暂时留着？"
- 检测到要提交的内容里有 `.env` / 密钥 → "这个文件像是密码 / token，要不要排除掉？"
- 检测到要 force push 到 main / rebase 已 push 的 commit / reset --hard 等危险动作 → 拦下来问

## 3. 模块和具体能力

### 自动 commit + push

**触发**：Agent 在对话过程中自己判断「这是一个值得保存的节点」。判断信号：一段任务完成 / 测试通过 / 文档写完 / 即将切换到另一类工作 / 用户在表达「这段做完了」。

**原子化拆分**：单次 task 产生多个语义簇时，按改动性质 + scope + 目的拆成多个 commit，不堆一个大杂烩：

```
feat(api): add /tasks POST endpoint with Zod validation
test(api): add unit + integration tests for tasks POST
docs: update README with new endpoint and example payload
```

每 commit 目标 ≤ 100 行，>1000 行必须再拆（[业界共识](https://engineering.leanix.net/blog/atomic-commit/)）。

**Push 同步**：solo / 个人项目场景默认 commit + push 配对（[现代 solo / trunk-based 共识](https://trunkbaseddevelopment.com/)）。受保护分支 / 与远端 diverge / 会触发 force push 的情况除外，先告知用户。

### 仓库初始化与 `.gitignore` 自动管理

**自动 `git init`**：Agent 要保存进度时检测到当前目录不是 git 仓库（`git rev-parse --git-dir` 失败）→ 主动初始化。流程：路径安全检查 → 告知用户 → `git init -b main` → 创建默认 `.gitignore` → 按文件名 stage → 第一笔 `chore: init repository`。**不主动配 remote**，等用户说"推到 GitHub"再问。

**危险位置先问用户**：`$HOME` 根、`/tmp` / mktemp、`/`、`~/Desktop` / `~/Documents` / `~/Downloads`、已在另一个 git 仓库子目录中 → 先确认再 init。

**`.gitignore` 自动建立**：新仓库 / 缺失 `.gitignore` 的仓库自动建一份，包含语言无关的常见忽略类别：

- **依赖目录**：`node_modules/`、`vendor/`、`.venv/`、`__pycache__/`、`target/` 等
- **构建产物**：`dist/`、`build/`、`.next/`、`out/`、`*.pyc`、`*.class`
- **环境与密钥**：`.env`、`.env.*`（含 `!.env.example` / `!.env.sample` 例外）、`*.pem`、`*.key`、`credentials.json`
- **IDE / 编辑器**：`.vscode/`、`.idea/`、`.DS_Store`、`*.swp`
- **日志与临时文件**：`*.log`、`*.tmp`、`*.cache`

Agent 在 commit 前发现要提交的文件命中以上类别 → 自动加进 `.gitignore` 并告诉用户 "我让 Git 忽略这些文件，它们不该跟代码一起保存"。

### Commit message 规范

完全 follow **[Conventional Commits 1.0.0 规范](https://www.conventionalcommits.org/en/v1.0.0/)**，不引入用户特定风格：

```
<type>(<optional scope>): <subject>

<optional body explaining the why, not the what>

<optional footer / trailers>
```

Type：`feat` / `fix` / `refactor` / `docs` / `test` / `chore` / `style` / `perf` / `build` / `ci` / `revert`。

Subject 规则（业界标准）：

- ≤ 50 字符（中文按 2 字符算）
- 祈使句、首字母小写、结尾不加句号
- 描述「为什么」，不是「改了什么」

**AI 归属**：commit body 末尾自动加 `Co-Authored-By:` trailer 标识 Agent 参与（[行业共识](https://www.deployhq.com/git/committing-ai-generated-code)，机器可读 + 不挤 subject）。具体身份由当前 harness 决定，skill 本身不内嵌固定模板。

### Worktree 管理（复杂项目）

适用场景：项目体量已经大到「在 main 上随便改可能搞坏正在跑的东西」，且用户在请求新 feature。

**识别启发式**（不强制，Agent 自己判断，识别错了用户能纠正）：

- prompt 含「加 / 实现 / 做一个 / 新加 / 引入」+ 名词 → 倾向 feature → 开 worktree
- prompt 含「改 / 修 / 调 / 更新 / 修复 / 优化」→ 倾向直接在当前分支
- 当前不在 main / master → 沿用当前分支
- 改动仅文档 / 配置 / 单 bug fix → 不开 worktree

**Worktree 设置规则**（[业界共识](https://devtoolbox.dedyn.io/blog/git-worktrees-complete-guide)）：

- 路径**跟主仓平级**，永不嵌套（嵌套会让 git 进入无限递归）
- 命名一致：目录 = 分支 = 任务名（短横线小写）
- 一个 worktree 一个 task
- 分支短命（≤ 1-3 天），超期是 smell
- 节制：默认 ≤ 2 个 worktree 同时存在
- 新 worktree 提醒用户初始化环境（`npm install` / `uv sync` 等）

**完成后**：Agent 主动问用户三选一：

- (a) 直接合并到 main + 清理 worktree（最丝滑）
- (b) 提 PR 让用户 review 再合（远端是 GitHub 时可用）
- (c) 暂时保留 worktree

### 自然语言交互层

Agent 跟用户讲的话**优先使用清楚的日常表达**，避免把 Git 术语直接抛给用户。翻译词表来源 = [Git 官方 `giteveryday`](https://git-scm.com/docs/giteveryday) 的常用命令 + 业界公认的用户友好表述。完整词表在 `references/translation.md`，主要条目：

| Git 操作 | 对用户说什么 |
|---|---|
| commit + push 配对 | "保存了一段进度并同步到 GitHub" |
| pull | "拉了一下最新" |
| 开 worktree + 新分支 | "另起一条线做这个新功能，目录在 `<path>`" |
| merge / 解决冲突 | "两边改了同一个地方，要选一下" |
| staged changes | "准备好的修改" |
| untracked files | "还没纳入管理的新文件" |
| pre-commit hook 失败 | "保存前的自动检查没过，我先修一下" |
| status | "看看现在有哪些没保存的修改" |
| `.gitignore` | "告诉它哪些文件不用管" |
| reset / revert / restore | "回到 / 撤销到 …… 的状态" |

报告**结果**，不报告**过程**：

- ✅ "我把 PRD 那段保存了并同步到了 GitHub。"
- ❌ "我执行了 `git add docs/prd.md && git commit -m '...' && git push`。"

### 安全护栏

下列操作 skill **永不主动做**，触发条件命中时必须先问用户：

- **暂存**：`git add -A` / `git add .`（永远按文件名 stage）
- **强制推送**：`git push --force` / `--force-with-lease` 到 `main` / `master` / 受保护分支
- **跳过校验**：`git commit --no-verify` / `--no-gpg-sign`（hook 失败先修问题）
- **修改已发布的历史**：`git commit --amend` 或 `git rebase` 已 push 的 commit（一旦 push 即视为公开历史）
- **销毁性操作**：`git reset --hard`、`git checkout -- .` / `git restore .`、`git clean -f`、`git branch -D`
- **Secrets 入库**：检测到 `.env` / `*.pem` / 看起来像 API key / token 的字符串 → 拦下来问
- **大文件 / 二进制入库**：> 10MB 或非文本文件 → 提醒一下
- **不明本地状态**：陌生分支 / 没听说过的未追踪文件 → 先 inspect 不直接清理
- **嵌套 worktree**：永不在主仓内部建 worktree
- **复用 branch**：不把同一个分支挂到两个 worktree

**hook 失败处理**：修问题 → 重新 stage → **起新 commit**（不 amend，避免改到上一个 commit）。

### v0 不做（高级 Git 操作 → 用户手动）

- `git rebase` / `git cherry-pick` 跨分支历史改写
- merge 冲突自动解决（永远让用户决定）
- `git submodule` 操作
- `git lfs` 大文件管理
- GitHub Issue 操作（跟 git 本身无关）

### 仓库结构（符合 Agent Skills 标准）

```
easy-git-zh/
├── SKILL.md            # 主 skill 文件（v0 待写）
│                         frontmatter 含 name: easy-git-zh, description: ...
├── references/
│   ├── translation.md  # 翻译词表完整版（来自 giteveryday）
│   ├── commit-style.md # Conventional Commits 规范 + 公开范例
│   ├── worktree-flow.md # worktree 生命周期 + 命名规则
│   └── hook-recovery.md # pre-commit hook 失败标准恢复流程
├── scripts/            # 安全检测脚本（secret 扫描、大文件扫描等，可选）
├── docs/prd.md         # 本文档
├── README.md           # 用户面入口（User Story 风格）
└── LICENSE             # MIT
```

## 4. 引用文档与仓库

### Skill 标准

- **[Agent Skills 开放标准（agentskills.io）](https://agentskills.io/specification)** —— skill 自身的格式 / packaging / 验证规范
- **[anthropics/skills（官方仓库）](https://github.com/anthropics/skills)** —— skill 实例 + 模板
- **[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)** —— commit message 规范

### Git 官方文档

- **[Git Everyday](https://git-scm.com/docs/giteveryday)** —— 常用命令参考（翻译词表的来源）
- **[Pro Git Book](https://git-scm.com/book/en/v2)** —— 基础概念依据
- **[git-worktree(1)](https://git-scm.com/docs/git-worktree)** —— worktree 权威定义

### 同类 / 参考 skill（GitHub 上已有的 git 类 skill）

- **[netresearch/git-workflow-skill](https://github.com/netresearch/git-workflow-skill)** —— 社区 git workflow skill，含分支策略 / commit conventions / PR workflow / CI-CD 集成
- **[huggingface/upskill 的 git-commit-messages](https://github.com/huggingface/upskill)** —— 自然语言转 Conventional Commits
- **[addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)** —— production-grade 工程 skill 集，含 `git-workflow-and-versioning`（已分析，easy-git-zh 跟它的差异化是「行动者 vs 参考手册 + 自然语言交互层 + .gitignore 自动管理 + worktree 全流程托管」）
- **[davila7/claude-code-templates](https://github.com/davila7/claude-code-templates)** —— 含 git-commit-helper 模板

### 工程实践与调研

**通用 git 实践**：

- [Atomic Commits — LeanIX Engineering](https://engineering.leanix.net/blog/atomic-commit/)
- [Commit Often, Perfect Later, Publish Once — Seth Robertson](https://sethrobertson.github.io/GitBestPractices/)
- [Git Workflow Best Practices 2026 — dev.to](https://dev.to/_d7eb1c1703182e3ce1782/git-workflow-best-practices-the-developers-guide-for-2026-4gl0)
- [Trunk Based Development（官方）](https://trunkbaseddevelopment.com/)
- [Trunk-based Development — Atlassian](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development)

**AI Agent + git**：

- [How to Use Git with Coding Agents (2026)](https://marketingagent.blog/2026/03/22/how-to-use-git-with-coding-agents-a-complete-2026-guide/)
- [Best Practices for Committing AI-Generated Code — DeployHQ](https://www.deployhq.com/git/committing-ai-generated-code)
- [Best Git Automation Skills for AI Coding Agents — Agensi](https://www.agensi.io/learn/best-git-automation-skills-ai-agents-2026)
- [Agentic Coding Guardrails — Blink](https://blink.new/blog/agentic-coding-best-practices)

**Worktree + AI Agent 并行**：

- [The Claude Code Git Worktree Pattern — MindStudio](https://www.mindstudio.ai/blog/what-is-claude-code-git-worktree-pattern-parallel-feature-branches)
- [Using Git Worktrees for Multi-Feature Development with AI Agents](https://www.nrmitchi.com/2025/10/using-git-worktrees-for-multi-feature-development-with-ai-agents/)
- [Parallel AI Coding with Git Worktrees and Claude Code](https://docs.agentinterviews.com/blog/parallel-ai-coding-with-gitworktrees/)
- [Git Worktrees: The Complete Guide for 2026](https://devtoolbox.dedyn.io/blog/git-worktrees-complete-guide)

**用户痛点参考（README User Story 依据）**：

- [Why Git is so complicated — how-to.dev](https://how-to.dev/why-git-is-so-complicated)
- [Hardest Things About Learning Git — GitKraken / Axosoft](https://www.gitkraken.com/blog/hardest-things-learning-git)
- [15+ Common Git mistakes — Edureka](https://www.edureka.co/blog/common-git-mistakes/)

## PRD 之后要做的事

按以上 4 节框架的内容已经明确，落地前需要补：

- [ ] 写 `SKILL.md`（按 Agent Skills 规范，frontmatter + 主体，控制在 500 行以内）
- [ ] 完整 `references/translation.md` 翻译词表（按 [giteveryday](https://git-scm.com/docs/giteveryday) 全量梳理）
- [ ] 完整 `references/commit-style.md`（[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) + 真实公开范例库）
- [ ] 完整 `references/worktree-flow.md`（worktree 生命周期 + 命名模板，follow [Git Worktrees 2026 Guide](https://devtoolbox.dedyn.io/blog/git-worktrees-complete-guide)）
- [ ] 完整 `references/hook-recovery.md`（pre-commit hook 失败标准恢复）
- [ ] README 重写：以 User Story 风格（参考小红书 / 即刻爆款笔记结构）+ 痛点钩子（Git 学习成本太高、用 Agent 时反复打字提醒）讲清楚「装了它之后你的世界变成什么样」
- [ ] 测试 fixture：搭一个空 sandbox 仓库 + 一组 dry-run 命令，验证 skill 在各类典型场景的行为
- [ ] 详细分析 netresearch/git-workflow-skill 等同类 skill 的覆盖范围，确保 easy-git-zh 差异化清晰、必要时直接 vendor 部分内容
