# easy-git PRD

## 我们要做什么

一个 **Claude Code Skill**，让 Coding Agent 自己负责跟 git 相关的所有杂活。用户跟 Agent 说完任务，剩下「什么时候 commit、commit 写什么、什么时候 push」这些由 Agent 自主判断，不用用户每次提醒。

跟用户交流时只用人话，不堆 git 术语。

## 动机

跟 Coding Agent 对话时，绝大多数 git 操作其实有明确的判断逻辑：

- 一段相对完整的工作做完了 → 该 commit
- 文档 / PRD 写完了 → 该 push 到 GitHub 给人 review
- 改动里只动了某几个文件 → stage 那几个文件，不要 `-A`
- pre-commit hook 失败 → 修问题、再 stage、起新 commit，不要 amend / `--no-verify`

这些事情用户不应该每次都重复跟 Agent 说。但很多 Agent 默认不敢动 git，或者会用「commit / push / staged」这种术语把用户拉进技术细节里。easy-git 把这些判断和翻译沉淀成一个 Skill。

## 给谁用（ICP）

每天跟 Coding Agent（Claude Code 为主）协作写代码 / 写文档的人。

两类典型场景：

1. **开发者** ——「跟 Agent 一起写代码，希望 Agent 自己处理 git，不用我每次提醒」
2. **非纯粹开发者** ——「用 Agent 管个人项目（笔记、博客、life-os 这类），git 是手段不是目的，希望尽量看不到 git 术语」

## 核心能力

### 1. 自主判断 commit / push 时机

Agent 应在以下情况自动 commit：

- 一个 task 做完了，diff 是语义上完整的一组改动
- 当 diff 涉及多个语义簇时，**拆成多个 commit**（不是一个大杂烩 commit）
- commit message 前缀按改动性质正确选择（`docs:` / `feat:` / `fix:` / `chore:` / `progress:` 等）

Agent 应在以下情况自动 push：

- 文档类改动写完即 push（用户在 GitHub 上 review，是既有习惯）
- 代码类改动是否同等默认 push，**待定**，见下文「待定决策」

### 2. 人话沟通

用户面上看到的不是 git 术语，是翻译过的描述：

| Git 行为 | 对用户说什么 |
|---|---|
| `git commit` | "保存了一段进度" / "记了一笔" |
| `git push` | "同步到 GitHub" / "上传到云端备份" |
| `git pull` | "拉了一下最新" |
| `git branch <name>` | "另起一条线做" |
| `git merge` / 解决冲突 | "两边改了同一个地方，要选一下" |
| `staged changes` | "准备好的修改" |
| `untracked files` | "还没纳入管理的新文件" |
| pre-commit hook 失败 | "保存前的自动检查没过，我先修一下" |

完整翻译词表在 `references/translation.md`（待写）。

### 3. 沉淀最佳实践

下面这些规则全部内置到 Skill：

**Stage 与 commit**：

- 永远按文件名 stage，**禁止 `git add -A` / `git add .`**
- 一个 commit = 一组语义相关的修改；不要把不相关的东西塞同一个 commit
- 不 commit secrets（`.env`、`credentials.json`、`*.pem` 等）—— 检测到先提醒用户
- 检测大文件 / 二进制 → 先确认是否真的要进 git

**Commit message**：

- conventional commit 风格 + 中文描述（沿用 life-os / drift-bottle 等仓的现有风格）
  - `docs(scope): …`
  - `feat(scope): …`
  - `fix(scope): …`
  - `progress(scope): …`（多用于跟进类项目）
  - `chore: …`
- 描述重点是「为什么」，不是「改了什么」
- 末尾按当前 harness 配置加 co-author 标签

**Push / 远程**：

- 文档类改动写完即 push
- **禁止 `--force` push 到 main / master**
- **禁止 `--no-verify`** —— hook 失败要修，不绕过

**Hook 失败处理**：

- pre-commit hook 失败：修问题 → 重新 stage → **起新 commit**（不要 amend，否则可能改到上一个 commit）

**通用安全**：

- 不主动 `git reset --hard` / `git checkout -- .` / `git clean -f` —— 这些必须先问用户
- 遇到不熟悉的本地状态（陌生分支 / 未追踪文件）先 inspect，不要直接清理

## v0 形态

- **Claude Code Skill**：发布到 `~/.claude/skills/` 或通过现成 skill 安装器（如 `npx skills`）安装
- 结构：`SKILL.md`（主入口）+ `references/`（翻译词表、commit message 风格、hook 错误对照表）

## v0 不做

- 非 Claude Code harness（Cursor / Codex / Windsurf）—— v1+ 考虑 MCP 化
- 复杂的多分支策略（自动开 feature branch 等）—— 假设用户已经在他想要的分支上
- GitHub Issue / PR 操作 —— 是另一个 Skill 的范围
- 替用户做 merge / rebase / cherry-pick 这种高风险操作

## 待定决策

### 语义层

- [ ] **「TroubleMaker」框架的含义**：是 skill 的分类标签（对应有 quiet / passive 类 skill）？还是形容这类「主动替用户处理事情」的 skill 性格？需要先定义清楚再写 SKILL.md description
- [ ] **commit 自主边界**：完全自动 vs 事后告知。"我刚把这段保存了" 够不够？还是要 "我准备保存一下，没问题吧？" 的事前确认？
- [ ] **push 自主边界（核心）**：
  - 文档场景：完全自动（既有习惯）
  - 代码场景：每次自动？只在某些信号下自动（如 task 结束 + 测试通过）？还是默认事后告知不事前确认？
- [ ] **「逻辑提交单元」如何判断**：一个 task 一个 commit / 一组语义相关的修改一个 commit / Agent 自己根据 diff 切？需要一套启发式

### 触发层

- [ ] **触发方式**：Stop hook 自动触发 / 用户显式调用（`/easy-git` 或自然语言）/ 两者结合
- [ ] **是否做交互模式**：纯沉默自动 vs 永远先讲一句再做

### 工程层

- [ ] **仓库结构**：单一 SKILL.md vs 拆多个 references
- [ ] **安装方式**：用户 clone + 软链 / 走 `npx skills install` / 出 `install.sh`
- [ ] **测试**：怎么测一个 skill？需要 fixture 仓库 / 录屏 demo 吗
- [ ] **是否做成 MCP server**：让 Cursor / Codex / Windsurf 也能用（v1+）

### 分发层

- [ ] **README 怎么吸引人**：截图 / GIF / before-after 对话对比
- [ ] **是否换一个更有记忆点的代号**：easy-git 是描述性名字，可以考虑更有「TroubleMaker 气质」的名字

## 关联与对照

- 同类参考：现有的 `agent-skills:git-workflow-and-versioning`。下笔之前需要先看一眼对方覆盖了什么，避免重复造；easy-git 的差异化在于「**主动替用户做、用人话沟通**」而不是给 Agent 一份 git 规范手册
- 上游经验：跟 Coding Agent 协作过程中累积的 git 使用规范（部分已记录在用户的 memory 系统里：禁止 `-A`、文档写完即 push、按文件名 stage 等）
