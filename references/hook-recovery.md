# pre-commit hook 失败恢复流程

参考：[pre-commit.com](https://pre-commit.com/) + [Git Hooks 官方](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)。

## 黄金原则

**不绕过，修问题。**

- ❌ `git commit --no-verify`（永不主动）
- ❌ `git commit --no-gpg-sign`（永不主动）
- ✅ 读 hook 输出 → 定位问题 → 修复 → 重新 stage → **新 commit**

## 为什么不能 amend

⚠️ **关键**：hook 失败时 commit 实际上**没生成**。如果这时 `git commit --amend`，会改到**上一个** commit（已经存在的那个），而不是你刚才想生成的那个。

正确做法：

1. hook 失败 → commit 没生成
2. 修问题
3. `git add <修复后的文件>`
4. `git commit -m "<原本想写的 message>"`（**新 commit**，不是 amend）

## 标准恢复流程

### 步骤 1：读输出

hook 失败时 git 会输出 hook 的 stderr。常见类型：

| 错误类型 | 关键词 | 怎么修 |
|---|---|---|
| Lint 错误 | `eslint`, `error`, `Parsing error`, `Lint failed` | 修代码 / `eslint --fix` |
| Format 错误 | `prettier`, `not formatted`, `would reformat` | `prettier --write` 或手动调整 |
| Type 错误 | `tsc`, `error TS\d+`, `Type ... is not assignable` | 改类型 / 加类型注解 |
| Test 失败 | `FAIL`, `✕`, `failed`, `expected ... received` | 修测试或修代码 |
| Commit message 不合规 | `commitlint`, `subject may not be empty`, `type must be one of` | 改 message 重写 |
| Secrets 检测 | `gitleaks`, `secret detected`, `API key found` | **优先**：把密钥从代码里挪走，加进 `.gitignore` |
| 大文件 | `file too large`, `git-lfs` | 用 `git lfs track` 或不 commit |

### 步骤 2：定位问题

```bash
# 看 hook 输出（一般 git commit 时直接打出来）
# 如果是 husky + lint-staged，看 stderr 最后几十行

# 想手动跑 hook 验证
.git/hooks/pre-commit
# 或（pre-commit 框架）
pre-commit run --all-files
```

### 步骤 3：修问题

**Lint / format**：

```bash
# 自动修
npx eslint --fix <file>
npx prettier --write <file>
# 或调用项目的 lint 脚本
npm run lint -- --fix
```

**Type 错误**：手动改代码。读错误信息里的具体类型 → 调整类型 / 加 cast / 改逻辑。

**Test 失败**：

- 如果是新加的测试本身错了 → 修测试
- 如果是改动破坏了已有测试 → 看测试期望，改代码或合理更新测试
- ⚠️ **不能为了过 hook 就跳过测试**

**Secrets 检测命中**：

1. **从代码里挪走密钥**（写到 `.env`，从代码读环境变量）
2. **`.env` 加进 `.gitignore`**
3. **从 git 历史里清掉**（如果之前 commit 过）：
   - 这一步 skill **不主动做**，告诉用户怎么用 [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/) 或 [git filter-repo](https://github.com/newren/git-filter-repo)
4. **如果是真密钥已经推到远端**：必须告知用户**立即 rotate 这个 token**

### 步骤 4：重新 stage + 新 commit

```bash
# 1. stage 修复后的文件（按名 stage，不要 -A）
git add path/to/fixed-file.ts

# 2. 起新 commit
git commit -m "原本想写的 message

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 步骤 5：用户面话术

- 失败时：
  > "保存前的自动检查没过（格式 / 类型 / 测试...），我先修一下。"
- 修完时：
  > "修好了，保存了一段进度并同步到 GitHub。"
- 反复修不好：
  > "保存前的检查反复没过：<具体原因>。要不要我先把这些检查临时关掉？不过我**不会主动关**，得你确认。"

## 反复失败的处理

**3 次失败仍未通过** → 停下来，告诉用户：

> "保存前的检查我已经修了 3 次还没过，原因是 `<具体错误>`。
> 选项：
> (a) 我接着试（告诉我具体怎么改）
> (b) 你来看一眼，自己改
> (c) 临时跳过这次检查（我不主动做，需要你明确说"跳过"）"

**绝对不主动用 `--no-verify`**。即使用户说"算了不检查了"，也先确认一遍：

> "你说的是这次跳过保存前检查，对吗？跳过之后这次保存就不做 lint / format / 测试 了，确认？"

## hook 类型速查

| Hook | 触发时机 | 失败后果 |
|---|---|---|
| `pre-commit` | `git commit` 之前 | commit 不生成 |
| `commit-msg` | commit message 写完后 | commit 不生成 |
| `pre-push` | `git push` 之前 | push 不发起 |
| `prepare-commit-msg` | 生成 commit message 模板时 | 一般不阻塞 |
| `post-commit` | commit 成功后 | 不阻塞（已经 commit 了） |

**重点关注**：`pre-commit` + `commit-msg`（最常拦下来）+ `pre-push`（远端校验前）。

## 常见 hook 工具

| 工具 | 配置位置 | 调试方式 |
|---|---|---|
| [husky](https://typicode.github.io/husky/) | `.husky/` 目录 | 直接看 `.husky/pre-commit` 等脚本 |
| [pre-commit (Python)](https://pre-commit.com/) | `.pre-commit-config.yaml` | `pre-commit run --all-files` |
| [lefthook](https://lefthook.dev/) | `lefthook.yml` | `lefthook run pre-commit` |
| [lint-staged](https://github.com/lint-staged/lint-staged) | `package.json` `lint-staged` 字段 | 看哪个 lint / format 工具触发 |
| 自定义 shell | `.git/hooks/pre-commit` | 直接读脚本 |

## 范例：从失败到修复

**场景**：用户让 Agent 加一个登录接口。Agent 写完代码，commit 时 hook 报：

```
ERROR: src/auth/login.ts:42:5
  'response' is assigned a value but never used. (no-unused-vars)
✕ ESLint failed
```

**Agent 处理**：

1. 读输出 → eslint no-unused-vars on `src/auth/login.ts:42`
2. 看 `src/auth/login.ts:42` → 有个 `const response = ...` 没用到（debug 残留）
3. 删掉这行 / 或加 `_response` 前缀（按项目惯例）
4. `git add src/auth/login.ts`
5. `git commit -m "feat(auth): add POST /login endpoint ..."`
6. 用户面：

> "保存前的检查发现一个没用的变量，我删了再保存的。已经存了一笔并同步到 GitHub 了。"

## 参考

- [pre-commit.com — 官方文档](https://pre-commit.com/)
- [Git Hooks — Pro Git Book](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)
- [husky 文档](https://typicode.github.io/husky/)
- [Conventional Commits + commitlint](https://commitlint.js.org/)
- [Best Practices for Committing AI-Generated Code](https://www.deployhq.com/git/committing-ai-generated-code) — "不绕过" 原则
