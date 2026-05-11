---
name: easy-git-zh
description: ALWAYS use in any git repository. At the start and end of each turn, check for unsaved changes; after file edits, save and sync meaningful progress in plain language. Manage .gitignore, open worktrees for new features, and block dangerous operations.
---

# easy-git-zh

让 Agent 替用户搞定 Git，用户只管说明需求。

## 何时使用本 skill

**触发优先级：高。** 只要当前工作目录在 git 仓库内，就默认使用本 skill；不要等用户说"保存"、"提交"或"同步"才触发。每轮对话都按这个节奏：

1. 开始工作前，快速看一眼有没有没保存的修改，避免踩到用户已有工作。
2. 完成任何文件编辑、测试修复、文档整理、配置变更后，判断是否形成一个值得保存的节点。
3. 形成保存节点时，按本 skill 的流程保存并同步；没有可保存内容时，不需要向用户汇报 Git 状态。

任何在 git 仓库里干活的时刻都适用：

- 用户在写代码 / 文档 / PRD / 笔记 / 博客 / 设计稿
- 用户在做 AI 协作创作，希望有版本管理兜底
- 用户对 Git 不熟（或熟但懒得打字）

**触发后**：你接管所有 git 相关动作。用户面只看到结果（"已保存"、"已同步"、"另起一条线"），不出现任何 Git 术语。

## 黄金原则

1. **Git 对用户透明** — 输出里不出现 commit / push / branch / rebase / reset / stage 等术语。完整词表见 `references/translation.md`。
2. **报告结果，不报告过程** — ✅ "我把 PRD 那段保存了并同步到了 GitHub" ❌ "执行了 `git add` + `git commit` + `git push`"。
3. **危险动作永不主动做** — 见下方"安全护栏"。命中即拦下来问用户。
4. **保存点要勤、要原子** — 每完成一段工作就保存一笔，按语义拆 commit，不堆大杂烩。
5. **不确定就问** — worktree 完成后合不合并、像密钥的文件要不要提交、检测到陌生本地状态 → 全部问用户。

## 核心能力

### 自动 commit + push

**何时触发**（你自己判断）：

- 一段任务做完了（功能写完 / 测试通过 / 文档段落写完）
- 即将切换到另一类工作（写代码 → 写文档；产品 A → 产品 B）
- 用户在话里表达"这段做完了"、"先保存"、"同步一下"
- 单次回合改动累积已经显著（>~50 行 / >3 个文件），即使用户没说

**原子化拆分**（关键）：单次 task 产生多个语义簇时，按改动性质 + scope + 目的拆成多个 commit：

```
feat(api): add /tasks POST endpoint with Zod validation
test(api): add unit + integration tests for tasks POST
docs: update README with new endpoint and example payload
```

拆分启发式：

- 不同 type（feat / fix / refactor / test / docs）→ 拆
- 同 type 但不同 scope（api vs ui）→ 拆
- 重构 + 新功能混在一起 → 拆（先重构再加功能）
- 单 commit > 100 行 → 考虑拆；> 1000 行 → 必须拆

**Push 同步**：solo / 个人项目场景，commit 完默认 push。例外（先告知用户再做）：

- 当前分支与远端 diverge（需要 pull / merge）
- 推送会触发 force push（受保护历史已改动）
- 当前在受保护分支（main / master / release/*）且改动有风险

**怎么向用户报告**：

- ✅ "我把搜索功能那段保存了一笔并同步到 GitHub 了，分了 3 笔：接口实现、测试、文档。"
- ❌ "已执行 `git add . && git commit -m '...' && git push`。"

Commit message 完整规范见 `references/commit-style.md`。

### 仓库初始化与 .gitignore 自动管理

#### 自动 `git init`

**触发条件**：

- Agent 想保存进度（按"自动 commit + push"流程）时，`git rev-parse --git-dir` 失败 → 当前目录不是 git 仓库 → 自动初始化
- 用户在一个明显是项目目录的位置（含 `README` / `package.json` / `pyproject.toml` / `Cargo.toml` / `go.mod` / `requirements.txt` 等）开始干活 → 第一次有可保存内容时主动初始化

**自动初始化流程**：

1. 路径检查（见下方"危险位置"清单），命中 → 先问用户
2. 告知用户："这个目录还没交给 Git 管，我先初始化一下，之后随时能回到当前状态。"
3. `git init -b main`（默认主分支用 `main`）
4. 创建默认 `.gitignore`（见下文模板）
5. 按文件名 stage 该保存的文件（**不用** `git add -A`）
6. 第一笔 commit：`chore: init repository` + Co-Authored-By trailer
7. **不主动配 remote**：等用户说"推到 GitHub" / "建个仓库"时再问 URL，或用 `gh repo create` 引导

**危险位置（先问用户再 init）**：

| 位置 | 原因 |
|---|---|
| `$HOME` 根目录 | 会把整个 home 纳管，影响巨大 |
| `/tmp` / `/var/tmp` / `mktemp` 路径 | 通常是临时文件，init 没意义 |
| `/` 或任何系统目录 | 灾难性 |
| `~/Desktop` / `~/Documents` / `~/Downloads` | 不像项目目录，可能误判 |
| 已经在另一个 git 仓库的子目录（含 worktree） | `git rev-parse --show-toplevel` 返回别的路径 → 提示用户：是想在父仓库里干活，还是要建独立子仓？ |

命中以上 → 用户面话术：

> "你让我做的事看起来需要版本管理，但当前位置是 `<path>`，看起来不像项目目录。确认要在这里建仓库吗？还是想我切到别的地方？"

#### `.gitignore` 自动管理

**触发条件**：

- 仓库还没有 `.gitignore` → 自动创建一份基础版（init 时已建则跳过）
- commit 前发现待提交文件命中常见忽略类别 → 加进 `.gitignore` 后再提交
- 用户的新目录里出现明显的脏文件（`node_modules/`、`dist/` 等）→ 提前加进忽略

**自动忽略的类别**（语言无关）：

| 类别 | 例子 |
|---|---|
| 依赖目录 | `node_modules/` `vendor/` `.venv/` `__pycache__/` `target/` `.bundle/` |
| 构建产物 | `dist/` `build/` `.next/` `out/` `*.pyc` `*.class` `*.o` |
| 环境与密钥 | `.env` `.env.*` `*.pem` `*.key` `credentials.json` `*.p12` |
| IDE / 编辑器 | `.vscode/` `.idea/` `.DS_Store` `*.swp` `*.swo` Thumbs.db |
| 日志与缓存 | `*.log` `*.tmp` `*.cache` `.pytest_cache/` `.mypy_cache/` |

**默认 `.gitignore` 模板**（创建时用这个）：

```gitignore
# Dependencies
node_modules/
vendor/
.venv/
__pycache__/
target/

# Build output
dist/
build/
.next/
out/
*.pyc
*.class

# Env & secrets
.env
.env.*
!.env.example
!.env.sample
*.pem
*.key
credentials.json

# IDE
.vscode/
.idea/
.DS_Store
*.swp

# Logs & cache
*.log
*.tmp
*.cache
.pytest_cache/
.mypy_cache/
```

**用户面话术**：

- ✅ "我让 Git 忽略 `dist/` 这个目录，它是构建产物，不该跟代码一起保存。"
- ❌ "已将 `dist/` 加入 `.gitignore`。"

### Commit message 标准化（Conventional Commits）

完全 follow [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)，不引入用户特定风格。

**格式**：

```
<type>(<optional scope>): <subject>

<optional body explaining the why>

<optional footer / trailers>
```

**Type 全集**：`feat` / `fix` / `refactor` / `docs` / `test` / `chore` / `style` / `perf` / `build` / `ci` / `revert`

**Subject 规则**：

- ≤ 50 字符（中文按 2 字符算）
- 祈使句、首字母小写、结尾不加句号
- 描述"为什么"或"做了什么"，不描述实现细节
- 中文 OK，英文 OK，按当前仓库历史风格保持一致

**Body 规则**（可选）：

- 解释"为什么这么改"，不是"改了哪些行"（diff 已经说明了 what）
- 行宽 ≤ 72 字符
- 与 subject 间空一行

**AI 归属（强制）**：commit body 末尾自动加 `Co-Authored-By:` trailer 标识 Agent 参与：

```
feat(auth): add email verification flow

Sends a one-time code via SendGrid on registration. Code expires
in 10 minutes; resend allowed after 60s.

Co-Authored-By: Claude <noreply@anthropic.com>
```

具体的 Co-Authored-By 身份由**当前 harness** 决定（Claude Code、Cursor、Copilot 等环境变量或上下文里读取），skill 本身不内嵌固定模板。

详细范例 + 反例见 `references/commit-style.md`。

### Worktree 管理（复杂项目）

**何时开 worktree**（启发式，识别错了用户能纠正）：

| 信号 | 倾向 |
|---|---|
| prompt 含"加 / 实现 / 做一个 / 新加 / 引入" + 名词 | 开 worktree |
| prompt 含"改 / 修 / 调 / 更新 / 修复 / 优化" | 直接当前分支 |
| 改动仅文档 / 配置 / 单 bug fix | 不开 worktree |
| 当前不在 main / master | 沿用当前分支 |
| 项目体量小（< 30 文件 / < 1000 行） | 不开 worktree |

**Worktree 设置规则**：

- 路径与主仓**平级**，永不嵌套（嵌套会让 git 递归出错）
- 命名一致：目录名 = 分支名 = 任务名（短横线小写，如 `feat-user-login`）
- 一个 worktree 一个 task，分支短命（≤ 1-3 天）
- 默认 ≤ 2 个 worktree 同时存在，超过先清理旧的
- 新 worktree 创建后提醒用户初始化环境（`npm install` / `uv sync` / `bundle install` 等）

**示例**：

```
主仓在 /repos/my-app
开 worktree → /repos/my-app-feat-user-login
分支名 = feat-user-login
```

**完成后流程**：Agent 主动问用户三选一：

> "这条线（feat-user-login）做完了，你想：
> (a) 直接合并到 main 并清理 worktree（最丝滑）
> (b) 提个 PR 让你 review 再合（远端是 GitHub 时可用）
> (c) 暂时保留这条线"

完整生命周期与命名细则见 `references/worktree-flow.md`。

### 自然语言交互层

跟用户讲的话**优先使用清楚的日常表达**，避免把 Git 术语直接抛给用户。

**核心翻译**（完整词表见 `references/translation.md`）：

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
| diff | "看一下这次的改动" |
| branch | "另一条线 / 这条线" |
| remote | "GitHub 上 / 远端" |

**报告结果，不报告过程**：

- ✅ "我把 PRD 那段保存了并同步到了 GitHub。"
- ❌ "执行了 `git add docs/prd.md && git commit -m '...' && git push`。"

**特殊情况**：

- 用户主动用 Git 术语问（"现在在哪个分支？"）→ 可以用术语回答（"在 main 分支"），但优先用日常表达
- 错误信息从 git 输出原样冒出来 → 转成清楚表达再展示（"远端有新东西，得先拉一下"，而不是 "non-fast-forward"）

### 安全护栏

下列操作 skill **永不主动做**。命中条件即必须先问用户，得到明确同意才执行。

**1. 暂存类**

- ❌ `git add -A` / `git add .` / `git add *`
- ✅ 永远按文件名 stage：`git add path/to/file.ts path/to/other.md`
- 原因：`-A` 容易把陌生文件、密钥、构建产物一把梭进去

**2. 强制推送类**

- ❌ `git push --force` / `--force-with-lease` 到 `main` / `master` / 受保护分支 → 永不主动
- ✅ feature 分支自己开的、明确告知用户后可以用 `--force-with-lease`
- 信号：推送被 reject + "non-fast-forward" → 先告诉用户，让用户决定

**3. 跳过校验类**

- ❌ `git commit --no-verify`
- ❌ `git commit --no-gpg-sign`
- hook 失败 → **修问题**，不是绕过。流程见 `references/hook-recovery.md`

**4. 改写已发布历史类**

- ❌ `git commit --amend` 已 push 的 commit（一旦 push 就是公开历史）
- ❌ `git rebase` 已 push 的 commit
- 例外：只有自己的、还没 push 的、用户明确确认的，才能 amend / rebase

**5. 销毁性操作类**

- ❌ `git reset --hard`
- ❌ `git checkout -- .` / `git restore .`
- ❌ `git clean -f` / `git clean -fd`
- ❌ `git branch -D` 删除未合并分支
- 原因：会丢未提交的工作。用户要求"撤销 / 回退"时优先用 `git revert`（生成新 commit）或 `git stash`，不破坏历史

**6. Secrets 入库**

要 stage 的文件命中以下任一 → 拦下来问：

- 文件名匹配：`.env` `.env.*` `*.pem` `*.key` `*.p12` `credentials.json` `id_rsa` `*.kdbx`
- 文件内容匹配类似密钥的字符串：
  - `(api[_-]?key|secret|token|password)\s*[:=]\s*["'][A-Za-z0-9+/=_-]{16,}["']`
  - GitHub PAT 模式：`ghp_[A-Za-z0-9]{36}` / `github_pat_[A-Za-z0-9_]{82}`
  - AWS Key：`AKIA[0-9A-Z]{16}`
  - Slack：`xox[abps]-[A-Za-z0-9-]{10,}`

辅助脚本：`scripts/scan-secrets.sh`

**7. 大文件 / 二进制入库**

- 文件 > 10MB → 提醒用户
- 非文本文件（基于 `git diff --numstat` 显示 `-`）→ 提醒一下
- 辅助脚本：`scripts/check-large-files.sh`

**8. 不明本地状态**

发现以下情况不要直接处理：

- 陌生分支（不是 main 也不是这次 task 开的）→ 先 `git log` inspect 再问用户
- 未追踪的目录里有看不懂的文件 → 先 ls + 问用户，不主动 add 也不主动删
- 有未提交的 stash → 不主动 pop，告诉用户存在

**9. Worktree 反模式**

- ❌ 在主仓**内部**建 worktree（嵌套会让 git 递归）
- ❌ 把同一个分支挂到两个 worktree（git 直接报错）
- ❌ 在没 commit 的 worktree 上直接 `git worktree remove --force`

### v0 不做（高级 Git → 用户手动）

skill 主动碰这些就出事，所以直接不做，让用户自己决定：

- `git rebase` / `git cherry-pick` 跨分支历史改写
- merge 冲突自动解决（永远让用户决定）
- `git submodule` 操作
- `git lfs` 大文件管理
- GitHub Issue / PR 创建之外的 issue 操作（与 git 本身无关）

## 工作流速查

### 用户说"帮我写一段 ……"

1. 写完
2. 当前不是 git 仓库？ → 按"仓库初始化"流程先 init
3. 判断要不要保存（见"自动 commit + push"触发条件）
4. 检查待提交文件有没有触发"仓库初始化与 .gitignore"或"安全护栏"
5. 写好 commit message（见"Commit message 标准化"）
6. commit + push
7. 用清楚的话报告（见"自然语言交互层"）

### 用户说"加一个新功能 ……"

1. 判断要不要开 worktree（见"Worktree 管理"启发式）
2. 开了的话：创建 worktree → 提醒环境初始化 → 切目录开干
3. 干完后保存进度（同上流程）
4. 主动问用户合并三选一

### 用户说"这个改回去"

1. **不要用** `reset --hard` 或 `checkout -- .`（见"安全护栏"）
2. 优先 `git revert <last-commit>` 生成反向 commit
3. 或者先 `git stash` 暂存当前修改
4. 用清楚的话告诉用户："我把刚才那段撤掉了，回到上一个保存点"

### 用户说"同步一下" / "保存一下" / "推上去"

直接按"自动 commit + push"流程：保存 + 推送 + 用清楚的话报告。

### Hook 失败了

1. **不要** `--no-verify`（见"安全护栏"）
2. 读 hook 输出，定位问题
3. 修问题（lint / format / type check 错误）
4. 重新 stage 修复后的文件
5. **起一个新 commit**（不要 amend）
6. 流程详见 `references/hook-recovery.md`

## 配套文件

- `references/translation.md` — Git 操作 → 用户友好表达完整词表（来源：[giteveryday](https://git-scm.com/docs/giteveryday)）
- `references/commit-style.md` — Conventional Commits 1.0.0 + 真实范例
- `references/worktree-flow.md` — worktree 生命周期 + 命名 + 完成后流程
- `references/hook-recovery.md` — pre-commit hook 失败的标准恢复
- `scripts/scan-secrets.sh` — 检测 staged 内容是否含密钥
- `scripts/check-large-files.sh` — 检测 staged 内容是否含大文件 / 二进制

## 验证清单

每次 commit 前自检：

- [ ] 没有用 `git add -A` / `git add .`
- [ ] 没有 staged `.env` / 密钥 / 大文件 / 二进制
- [ ] commit message 符合 Conventional Commits
- [ ] commit body 末尾有 Co-Authored-By trailer（如适用）
- [ ] commit 体积 ≤ 100 行；> 1000 行已拆
- [ ] 用户面用清楚的话报告，没漏出 Git 术语

每次开 worktree 前自检：

- [ ] 路径与主仓平级，不嵌套
- [ ] 目录名 = 分支名 = 任务名（短横线小写）
- [ ] 当前 worktree 数 ≤ 2
- [ ] 该分支没挂到别的 worktree

每次危险动作前自检：

- [ ] force push / reset --hard / clean -f / branch -D / --no-verify / amend 已 push commit / 跨 worktree 共享分支 / 嵌套 worktree → **必须先问用户**

## 红旗（出现就停下问用户）

- 待 commit 的内容看起来像密钥 / token
- 待 commit 的文件 > 10MB 或是二进制
- 远端与本地 diverge（push 会触发 force）
- 出现陌生分支 / 陌生未追踪目录
- pre-commit hook 反复失败 3 次以上
- worktree 数已经 ≥ 3
- 用户的下一步可能要求改写已 push 的历史

## 同类参考

- [netresearch/git-workflow-skill](https://github.com/netresearch/git-workflow-skill) — 社区 git workflow skill
- [addyosmani/agent-skills 的 git-workflow-and-versioning](https://github.com/addyosmani/agent-skills) — 参考手册类
- easy-git-zh 差异：**行动者**而非参考手册 + 自然语言交互层 + `.gitignore` 自动管理 + worktree 全流程托管
