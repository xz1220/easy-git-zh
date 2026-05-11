# Commit Message 规范：Conventional Commits 1.0.0

完全 follow **[Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)** 公开规范。本文档是落地规则 + 范例库。

## 格式

```
<type>(<optional scope>): <subject>

<optional body>

<optional footer / trailers>
```

### Subject 行（必填）

- ≤ 50 字符（中文按 2 字符算）
- 祈使句、首字母小写、结尾不加句号
- 描述"做了什么 / 为什么"，不描述实现细节
- 中文 OK，英文 OK，按当前仓库历史风格保持一致

### Body（可选，>1 行修改建议加）

- 与 subject 间空一行
- 行宽 ≤ 72 字符
- 解释**为什么**，不是**改了哪几行**（diff 已经说明了 what）
- 多段用空行分隔

### Footer / Trailers（可选）

- 与 body 间空一行
- 每行 `Token: value` 格式
- 常用 trailer：
  - `Co-Authored-By: Name <email>` — AI 协作归属（**强制加**）
  - `Fixes: #123` — 关联 issue
  - `Refs: #456` — 引用 issue
  - `BREAKING CHANGE: <description>` — 破坏性变更说明

## Type 全集

| Type | 含义 | 范例 subject |
|---|---|---|
| `feat` | 新功能 | `feat(auth): add email verification` |
| `fix` | bug 修复 | `fix(api): handle null in /users response` |
| `refactor` | 重构（不改变行为） | `refactor: extract validation to shared utility` |
| `docs` | 仅文档 | `docs: update README with new endpoint` |
| `test` | 新增 / 修改测试 | `test(auth): add integration tests for login` |
| `chore` | 杂活（依赖、配置） | `chore: bump zod to 3.22` |
| `style` | 格式 / 空格 / 分号（不影响代码含义） | `style: fix indentation in auth.ts` |
| `perf` | 性能优化 | `perf(query): index users.email column` |
| `build` | 构建系统 / 依赖变更 | `build: switch from webpack to vite` |
| `ci` | CI 配置变更 | `ci: add lint step to PR workflow` |
| `revert` | 回滚之前的 commit | `revert: feat(auth): add email verification` |

**选择 type 的优先级**（多种命中时）：

1. `feat` / `fix` 优先（用户能感知的功能 / 问题）
2. `perf` / `refactor`（开发者能感知）
3. `docs` / `test` / `style`
4. `build` / `ci` / `chore`

## Scope（可选）

- 表示影响的模块、目录或子系统
- 短横线小写：`auth` / `api` / `user-profile` / `payment`
- 单一项目 / 模块边界不清晰时可省略
- 例：`feat(auth): ...` / `fix(payment): ...` / `docs: ...`

## AI 协作归属（强制）

每个 commit 的 body 末尾**自动加** `Co-Authored-By:` trailer 标识 Agent 参与。这是 [GitHub trailers 规范](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors)，机器可读 + GitHub 会在 commit 页显示协作者头像。

### 当前 harness 检测

具体的 `Co-Authored-By` 身份由当前 harness 决定：

| Harness | trailer 行 |
|---|---|
| Claude Code (Anthropic) | `Co-Authored-By: Claude <noreply@anthropic.com>` |
| Cursor | `Co-Authored-By: Cursor <noreply@cursor.sh>` |
| GitHub Copilot | `Co-Authored-By: Copilot <noreply@github.com>` |
| Gemini CLI | `Co-Authored-By: Gemini <noreply@google.com>` |
| Codex CLI | `Co-Authored-By: Codex <noreply@openai.com>` |
| 未知 harness | `Co-Authored-By: AI Agent <noreply@example.com>` |

**判定方式**：

1. 读环境变量（`CLAUDE_CODE_VERSION` / `CURSOR_*` / 等）
2. 看 process tree / parent process
3. 看当前 model id（"claude-*" / "gpt-*" / "gemini-*"）
4. 都没识别到 → fallback 到 generic

### 多 Agent / 用户协作

如果是用户主导、Agent 辅助：

```
Co-Authored-By: Claude <noreply@anthropic.com>
```

如果是多个 Agent 共同 commit（少见，但可能）：

```
Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Copilot <noreply@github.com>
```

## 范例库

### ✅ 好例子

**单行 subject（小改动）**：

```
fix(api): return 404 instead of 500 on missing user

Co-Authored-By: Claude <noreply@anthropic.com>
```

**带 body 的中等改动**：

```
feat(auth): add rate limiting to /login endpoint

Prevents brute-force attacks by limiting to 5 attempts per IP
per minute. Uses redis-backed sliding window counter. Returns
429 with Retry-After header when limit hit.

Co-Authored-By: Claude <noreply@anthropic.com>
```

**带 BREAKING CHANGE**：

```
refactor(api)!: change user ID from int to UUID

User IDs are now UUIDs to support distributed ID generation.
All existing endpoints accept both formats during migration.

BREAKING CHANGE: User.id is now string (UUID) instead of number.
Clients calling /api/users/:id with numeric IDs still work but
should migrate to UUID format. Migration deadline: 2026-08-01.

Co-Authored-By: Claude <noreply@anthropic.com>
```

**revert**：

```
revert: feat(auth): add email verification

This reverts commit a1b2c3d4. The email verification flow
broke registration for users without email clients configured.
Will re-introduce after email-optional flow is built.

Refs: #234

Co-Authored-By: Claude <noreply@anthropic.com>
```

**中文 subject（中文项目 OK）**：

```
docs(prd): 补充 worktree 完成流程的三选一

新增 (a) 合并清理 / (b) 提 PR / (c) 保留 三种用户决策路径。

Co-Authored-By: Claude <noreply@anthropic.com>
```

### ❌ 反例 + 修改

**太宽泛**：
- ❌ `update auth.ts`
- ❌ `fix bug`
- ❌ `misc changes`
- ❌ `WIP`
- ✅ `fix(auth): handle expired session token in middleware`

**描述 what 不描述 why**：
- ❌ `feat: add 50 lines to user.ts`
- ❌ `refactor: rename foo to bar`（rename 只是手段，目的是？）
- ✅ `refactor(user): rename foo to canonicalize for clarity`

**结尾加句号**：
- ❌ `feat: add login endpoint.`
- ✅ `feat: add login endpoint`

**首字母大写**：
- ❌ `Feat: Add login endpoint`
- ✅ `feat: add login endpoint`

**Subject 超长**：
- ❌ `feat(auth): add comprehensive email verification flow with rate limiting and ...`
- ✅ subject: `feat(auth): add email verification flow`
- ✅ body: 解释 rate limiting / 细节

**混合多种 type**：
- ❌ `feat: add login + fix sidebar + update deps`
- ✅ 拆 3 个 commit：`feat(auth): ...` + `fix(ui): ...` + `chore: ...`

## 拆分 commit 的判断

单次 task 产生多个语义簇 → 拆 commit，不堆大杂烩。

**拆分信号**：

| 信号 | 操作 |
|---|---|
| 改动不同 type（feat / fix / refactor / test / docs）| 拆 |
| 同 type 但不同 scope（auth vs payment）| 拆 |
| 重构 + 新功能混在一起 | 先重构 commit，再新功能 commit |
| 单 commit > 100 行 | 考虑拆 |
| 单 commit > 1000 行 | 必须拆 |
| 包含完全无关的改动（顺手改的） | 拆出来 |

**不拆的情况**：

- 修复一个 bug 同时加了对应测试 → 可以放一个 commit（"fix + test 配对"是惯例）
- 重命名导致 20 个文件都改了 → 一个 commit（同语义）

### 拆分范例

**原始 task**：实现用户注册接口

**拆成**：

```
refactor(auth): extract email validation to shared utility

Pulls regex + dns-mx check out of registration handler so
the upcoming email-change flow can reuse it.

Co-Authored-By: Claude <noreply@anthropic.com>

---

feat(auth): add POST /register endpoint

Accepts {email, password, name}. Validates email format and
uniqueness. Hashes password with argon2id. Returns user ID
on success, 409 on duplicate email.

Co-Authored-By: Claude <noreply@anthropic.com>

---

test(auth): add unit + integration tests for /register

Covers happy path, duplicate email, weak password, malformed
email. Integration test uses test database fixture.

Co-Authored-By: Claude <noreply@anthropic.com>

---

docs: update README with /register endpoint usage

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Subject 措辞参考

**好动词**：add / remove / fix / refactor / extract / inline / rename / update / handle / prevent / enable / disable / support / introduce / drop / migrate

**含糊动词（少用）**：change / modify / improve / clean up / tweak（→ 改成具体动作）

## 跟项目历史保持一致

新仓库：直接按本规范开干。

已有历史：用 `git log --oneline -20` 看一下风格：

- 已经在用 Conventional Commits → 完全沿用
- 用别的风格（如 ticket 编号开头） → 跟既有风格融合，subject 实质内容仍按本规范
- 全是 "fix"、"update" 这类宽泛 message → 从这次起按 Conventional Commits，逐步带动整个仓库

## 参考

- [Conventional Commits 1.0.0 规范](https://www.conventionalcommits.org/en/v1.0.0/) — 完整规范
- [Conventional Commits 类型扩展（Angular 约定）](https://github.com/angular/angular/blob/main/CONTRIBUTING.md#-commit-message-format)
- [Atomic Commits — LeanIX](https://engineering.leanix.net/blog/atomic-commit/) — 拆分依据
- [Commit Often, Perfect Later, Publish Once — Seth Robertson](https://sethrobertson.github.io/GitBestPractices/) — 频率依据
- [Best Practices for Committing AI-Generated Code — DeployHQ](https://www.deployhq.com/git/committing-ai-generated-code) — AI 归属 trailer 依据
- [GitHub: Creating a commit with multiple authors](https://docs.github.com/en/pull-requests/committing-changes-to-your-project/creating-and-editing-commits/creating-a-commit-with-multiple-authors) — trailer 机器可读规范
