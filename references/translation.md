# 翻译词表：Git 操作 → 用户友好表达

来源：[Git Everyday](https://git-scm.com/docs/giteveryday)（Git 官方常用命令） + 业界公认的用户友好表述。

## 翻译总原则

1. **不出现 Git 术语**：commit / push / pull / branch / merge / rebase / stage / reset / HEAD / origin / remote / rebase / cherry-pick / stash → 全部翻译
2. **报告结果，不报告过程**：用户面只看到"发生了什么、对我来说意味着什么"，不看到命令
3. **该简化就简化**：commit 拆成 3 笔 + push → "保存了一段进度并同步到 GitHub"（不强调"3 笔"，除非用户问起）
4. **错误信息也要翻译**：git 的英文错误冒出来时先翻译，再展示

## 核心操作

| Git 操作 | 用户面话术 | 备注 |
|---|---|---|
| `git init` | "把这个目录交给 Git 管起来" | 新仓库创建 |
| `git add <file>` | （不暴露，是 commit 内部步骤） | 永不单独说 |
| `git commit` | "保存了一段进度" | 配合 push 时合并说 |
| `git commit + git push` | "保存了一段进度并同步到 GitHub" | 配对默认表述 |
| `git push` | "同步到 GitHub" / "推到远端" | "远端" 不是术语，用户能理解 |
| `git pull` | "拉了一下最新" / "把别人的新东西拉下来" | |
| `git fetch` | "看了一下远端有什么新东西"（不合并） | 一般不暴露给用户 |
| `git status` | "看看现在有哪些没保存的修改" | |
| `git diff` | "看一下这次的改动" | |
| `git log` | "看看之前都保存过哪些东西" / "看一下历史" | |
| `git clone` | "把这个项目下载下来" | |

## 分支与并行工作

| Git 操作 | 用户面话术 | 备注 |
|---|---|---|
| `git branch` | "看看现在有哪些线" | "线" 是 branch 的日常表达 |
| `git checkout -b xxx` / `git switch -c xxx` | "另起一条线 `xxx`" | |
| `git checkout xxx` / `git switch xxx` | "切到 `xxx` 这条线" | |
| `git merge` | "把这条线合回去" / "合并 …… 到 ……" | |
| `git rebase` | "把这条线接到最新的主线上"（如适用）| skill 不主动做 |
| `git branch -d xxx` | "把 `xxx` 这条线清掉" | 已合并的安全删除 |
| `git branch -D xxx` | （永不主动，要问用户） | 未合并强删，丢工作 |

## Worktree

| Git 操作 | 用户面话术 | 备注 |
|---|---|---|
| `git worktree add ../xxx <branch>` | "另起一条线 `<branch>` 在 `<path>` 单独做" | "Worktree 管理"触发时 |
| `git worktree list` | "看看现在并行开了几条线" | |
| `git worktree remove ../xxx` | "把 `xxx` 这条线收掉了" | 合并清理后 |
| 主仓 + worktree 概念 | "主仓在 …… ，这条新线在 ……" | 不用 worktree 这个词 |

## 远端 / 远程

| Git 概念 | 用户面话术 |
|---|---|
| `origin` / remote | "GitHub 上 / 远端" |
| `origin/main` | "GitHub 上的 main" / "远端的主线" |
| upstream | "上游 / 原仓库" |
| `git remote add` | "把这个项目跟 GitHub 关联起来" |
| `git push -u origin xxx` | "把这条线推到 GitHub 上去" |

## 状态描述

| Git 状态 | 用户面话术 |
|---|---|
| modified（已改未存） | "改了但还没保存" |
| staged | "准备好的修改" / "马上要保存的内容" |
| untracked | "还没纳入管理的新文件" |
| committed | "已经保存了" / "存了一笔" |
| pushed | "已经同步到 GitHub 了" |
| clean working tree | "没什么没保存的改动" / "干干净净" |
| dirty working tree | "有改动还没保存" |
| ahead of origin | "本地比 GitHub 多了几笔保存" |
| behind origin | "GitHub 上比本地新" |
| diverged | "两边都改了，得对一下" |

## 撤销 / 回退

| Git 操作 | 用户面话术 | 何时用 |
|---|---|---|
| `git revert <commit>` | "把刚才那笔撤回去（用一笔反向修改）" | **优先用这个**，不破坏历史 |
| `git reset --soft HEAD~1` | "把上一笔保存退回成未保存状态" | 仅当 commit 没 push |
| `git reset --hard` | （永不主动） | "安全护栏"拦截 |
| `git checkout -- file` | （永不主动） | "安全护栏"拦截，会丢未存的修改 |
| `git restore file` | （永不主动） | 同上 |
| `git stash` | "先把当前修改放一边" | 临时收起未保存内容 |
| `git stash pop` | "把刚才放一边的修改拿回来" | |

## 冲突 / 合并

| 场景 | 用户面话术 |
|---|---|
| merge conflict | "两边改了同一个地方，要选一下" |
| "Auto-merging file.ts" | "正在合并 file.ts" |
| "CONFLICT (content): ..." | "`file.ts` 里有冲突，得人来决定保留哪边" |
| 解决冲突后 | "把选好的版本保存下来" |
| `git merge --abort` | "取消这次合并，回到合之前" |

## Hook / 自动检查

| Git 概念 | 用户面话术 |
|---|---|
| pre-commit hook | "保存前的自动检查" |
| hook 通过 | （不暴露） |
| hook 失败 | "保存前的自动检查没过，我先修一下" |
| `--no-verify` | （永不主动，要问用户） |
| lint / format / typecheck 失败 | 直接说哪类检查没过："格式没过 / 类型检查没过" |

## `.gitignore`

| 场景 | 用户面话术 |
|---|---|
| `.gitignore` 这个文件 | "告诉 Git 哪些文件不用管的列表" |
| 加 `dist/` 到 `.gitignore` | "我让 Git 忽略 `dist/` 这个目录，它是构建产物" |
| 加 `.env` 到 `.gitignore` | "我让 Git 忽略 `.env`，它里面是密钥" |
| 创建 `.gitignore` | "我加了一个忽略列表，常见不该保存的文件都在里面" |

## 错误信息翻译

| Git 原始错误 | 用户面翻译 |
|---|---|
| `non-fast-forward` / push rejected | "远端有新东西，得先拉一下" |
| `fatal: not a git repository` | "这个目录还没交给 Git 管，要不要先初始化？" |
| `Please, commit your changes or stash them` | "你有改动还没保存，得先存一下再切" |
| `Your branch is up to date with origin/...` | "本地跟 GitHub 一致" |
| `nothing to commit, working tree clean` | "现在没什么要保存的" |
| `pathspec 'xxx' did not match any files` | "找不到 `xxx` 这个文件" |
| `failed to push some refs` | "推送失败，远端可能有新东西" |
| `Permission denied (publickey)` | "GitHub 拒绝了，可能 SSH key 没配好" |
| `Updates were rejected because the remote contains work you do not have locally` | "GitHub 上有你本地没有的新东西，得先拉下来" |
| `fatal: refusing to merge unrelated histories` | "两边是不同的历史，没法直接合" |

## 用户主动用 Git 术语提问时

用户问的话里用了术语，可以用同一个术语回答（用户已经理解），但优先用日常表达。

例：
- 用户："现在在哪个分支？" → "在 main 分支" 或 "在主线上"（都行）
- 用户："push 了吗？" → "推上去了" / "同步到 GitHub 了"
- 用户："commit 了吗？" → "保存了" / "存了一笔"

## 反例（永远不要这样说）

- ❌ "执行了 `git add . && git commit -m '...' && git push origin main`"
- ❌ "已 stage 3 个文件，commit 完成（hash: a1b2c3d），push 到 origin/main"
- ❌ "由于 non-fast-forward，push 被拒绝。请先 pull --rebase 再 push"
- ❌ "Cherry-pick commit a1b2c3 到 main"
- ❌ "rebase 当前分支到 origin/main"

✅ 改成：
- "保存了一段进度并同步到 GitHub"
- "保存了 3 笔改动并推到 GitHub 了"
- "推不上去，GitHub 上有新东西，得先拉一下"
- "把那个修改单独搬一份到主线"
- "把这条线接到最新的主线上"

## 例外：何时可以暴露原始 Git 输出

- 用户明确说"给我看原始 git 输出" / "show me git log" → 直接显示
- 调试 / 复杂情况 Agent 自己也不确定 → 可以贴原始信息，但**配上清楚解释**

## 参考

- [Git Everyday](https://git-scm.com/docs/giteveryday) — Git 官方常用命令的来源
- [Pro Git Book — Glossary](https://git-scm.com/book/en/v2/Appendix-C%3A-Git-Commands) — 术语完整定义
- [Why Git is so complicated](https://how-to.dev/why-git-is-so-complicated) — 为什么这层翻译有必要
