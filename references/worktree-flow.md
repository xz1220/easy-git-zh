# Worktree 生命周期 + 命名

参考：[git-worktree(1)](https://git-scm.com/docs/git-worktree) + [Git Worktrees: The Complete Guide for 2026](https://devtoolbox.dedyn.io/blog/git-worktrees-complete-guide) + [Claude Code Git Worktree Pattern](https://www.mindstudio.ai/blog/what-is-claude-code-git-worktree-pattern-parallel-feature-branches)。

## 什么是 worktree（用户不需要知道，Agent 必须懂）

一个 git 仓库可以同时 checkout 多个分支到**不同目录**，每个目录是一个 worktree。共享同一份 `.git/`，但工作目录、当前分支、未提交修改各自独立。

**对 AI Agent 的价值**：

- 主仓里跑着的东西不会被新 feature 改动打断
- 多 Agent / 多任务并行不互相干扰
- 实验失败直接删 worktree 目录，主仓干干净净
- 不用 `git stash` 来回切

## 何时开 worktree

由 SKILL.md M4 的启发式判断。本文档讲**开起来之后**的事。

## 命名规则

**铁律**：目录名 = 分支名 = 任务名。

**任务名**：

- 短横线小写：`feat-user-login`、`fix-payment-timeout`、`refactor-auth-middleware`
- 长度 ≤ 30 字符
- type 前缀（与 Conventional Commits 对齐）：
  - `feat-` 新功能
  - `fix-` bug 修复
  - `refactor-` 重构
  - `docs-` 文档
  - `exp-` 实验性 / 探索性
- 任务名应能让用户一眼看懂这条线在干嘛

**示例**（假设主仓在 `/repos/my-app`）：

| 用户 prompt | 分支 / 目录名 | 完整路径 |
|---|---|---|
| "加一个登录功能" | `feat-login` | `/repos/my-app-feat-login` |
| "修一下支付超时" | `fix-payment-timeout` | `/repos/my-app-fix-payment-timeout` |
| "把 auth 重写一下" | `refactor-auth` | `/repos/my-app-refactor-auth` |
| "试一下用 SQLite 代替 Postgres" | `exp-sqlite` | `/repos/my-app-exp-sqlite` |

## 路径规则

**铁律**：路径与主仓**平级**，永不嵌套。

```
✅ 正确（平级）：
/repos/my-app/             ← 主仓
/repos/my-app-feat-login/  ← worktree

❌ 错误（嵌套）：
/repos/my-app/
└── worktrees/             ← 嵌套在主仓内
    └── feat-login/
```

嵌套会让 git 进入无限递归（worktree 也是 git 仓库，git 看主仓时会扫到嵌套的 worktree，导致 status / log 混乱）。

## 创建流程

```bash
# 1. 在主仓根目录执行
cd /repos/my-app

# 2. 开 worktree + 新分支（一步到位）
git worktree add ../my-app-feat-login -b feat-login

# 3. 切到 worktree 目录
cd ../my-app-feat-login

# 4. （重要）初始化环境
#    Node: npm install / pnpm install / bun install
#    Python: uv sync / poetry install / pip install -r requirements.txt
#    Ruby: bundle install
#    Rust: 不用（Cargo 自动）
#    Go:   不用（go.mod 自动）
```

**Agent 创建后必须**：

1. **切到新目录**（后续所有改动在这里做）
2. **告知用户**新路径 + 提醒环境初始化
3. **记住**当前是在 worktree 上，不是主仓

**用户面话术**：

> "这个改动比较大，我另起一条线 `feat-login` 做，现在切到 `/repos/my-app-feat-login` 了。
> 这是个独立目录，跟主仓互不干扰。
>
> 提醒：新目录需要装一下依赖（运行 `npm install`），不然跑不起来。"

## 工作期间

- 在 worktree 目录里像普通仓库一样操作（commit / push）
- push 时 git 会自动把 `feat-login` 推到远端（如果 remote 配好了）
- 主仓那边继续保持干净

## 完成后流程

任务做完了，Agent **主动**问用户三选一：

> "这条线 `feat-login` 做完了，你想：
>
> **(a) 直接合并到主线 + 清理这条线**（最丝滑，适合个人项目）
> **(b) 提个 PR 让你 review 再合**（远端是 GitHub 时可用，适合想留 review 痕迹的）
> **(c) 暂时保留这条线**（还要继续在上面做的）"

### 选 (a) — 直接合并 + 清理

```bash
# 1. 切回主仓
cd /repos/my-app

# 2. 确保主仓在 main 上、与远端同步
git switch main
git pull

# 3. 合并 feat-login 进来（用 --no-ff 保留分支痕迹，可选）
git merge feat-login

# 4. push 主线
git push

# 5. 清理 worktree
git worktree remove ../my-app-feat-login

# 6. 删分支
git branch -d feat-login

# 7. 删远端分支（如果之前 push 过）
git push origin --delete feat-login
```

**用户面**："已经把那条线合回主线，同步到 GitHub 了，原来的目录也清掉了。"

**遇到冲突**：

- ❌ 不要自动解决
- ✅ 停下来告诉用户："两边改了同一个地方，要选一下"，列出冲突文件

### 选 (b) — 提 PR review

```bash
# 1. 确保 worktree 里所有改动都已 push
cd /repos/my-app-feat-login
git push -u origin feat-login

# 2. 用 gh CLI 开 PR（前提是远端是 GitHub + 装了 gh）
gh pr create --title "feat: add login flow" --body "..." --base main
```

**PR title / body**：

- title：follow Conventional Commits 风格（不带 type 也行，多看一眼仓库现有 PR 风格）
- body：列改动 + 测试方式 + 任何 reviewer 该注意的点
- 末尾加 `🤖 Generated with [Claude Code](https://claude.com/claude-code)` 之类的归属（看 harness）

**用户面**："提了个 PR：<url>。等你 review 通过后再合，我先不动这条线。"

PR 合并后用户回来说"合了"→ 走 (a) 的清理流程（worktree remove + branch -d）。

### 选 (c) — 暂时保留

```bash
# 什么都不做，保持原状
```

**用户面**："好，这条线先放着。下次要继续做就跟我说一声。"

**之后用户回来继续做**：

```bash
cd /repos/my-app-feat-login
# 接着干
```

## 节制原则

**默认 ≤ 2 个 worktree 同时存在**。理由：

- 每个 worktree 独立环境（依赖装一遍 / 测试跑一遍），多了浪费
- 多于 3 个 → Agent 自己也分不清在哪条线上
- 分支短命（≤ 1-3 天），超期是 smell

**已经 ≥ 2 个 worktree 时用户要求开第 3 个**：

> "现在并行有 2 条线在做（`feat-login`、`refactor-auth`）。你想：
>
> (a) 先处理掉一条再开第 3 条（推荐）
> (b) 确认仍要开第 3 条（我会建好，但建议尽快收）"

## 反模式（永远不做）

| 反模式 | 后果 |
|---|---|
| 嵌套 worktree | git 递归扫描，状态混乱 |
| 同一分支挂到两个 worktree | git 直接报错 `fatal: already checked out` |
| worktree 里有未 commit 修改就 `worktree remove --force` | **丢工作** |
| 分支已经合并但 worktree 没删 | 占空间 + 误导 |
| 分支跨越数周才合并 | 与主线 diverge，merge 冲突累积 |
| 在 worktree 上操作主仓的 `.git/`（reset、reflog 等） | 容易破坏共享状态 |

## 异常恢复

### worktree 目录被手动删了，但 git 还记得

```bash
# git worktree list 显示 prunable
git worktree prune
# 或单独清
git worktree remove --force ../<已删的路径>
```

### 想丢弃整条线（实验失败）

```bash
# 1. 切回主仓
cd /repos/my-app

# 2. 删 worktree（强制，因为有未合并的改动）
#    ⚠️ 这会丢未 push 的工作！先问用户。
git worktree remove --force ../my-app-exp-sqlite

# 3. 删本地分支
git branch -D exp-sqlite

# 4. 删远端分支（如果 push 过）
git push origin --delete exp-sqlite
```

**用户面**：

> "这条 `exp-sqlite` 线还没保存到 GitHub，删了就找不回来了。确认要丢？"

得到明确同意后才执行。

## 参考

- [git-worktree(1) — Git 官方](https://git-scm.com/docs/git-worktree) — worktree 权威定义
- [Git Worktrees: The Complete Guide for 2026](https://devtoolbox.dedyn.io/blog/git-worktrees-complete-guide) — 命名 / 路径规则依据
- [The Claude Code Git Worktree Pattern](https://www.mindstudio.ai/blog/what-is-claude-code-git-worktree-pattern-parallel-feature-branches) — AI Agent 并行场景
- [Using Git Worktrees for Multi-Feature Development with AI Agents](https://www.nrmitchi.com/2025/10/using-git-worktrees-for-multi-feature-development-with-ai-agents/)
- [Parallel AI Coding with Git Worktrees](https://docs.agentinterviews.com/blog/parallel-ai-coding-with-gitworktrees/)
