# easy-git PRD

## 我们要做什么

一个 **Claude Code Skill**，让 Coding Agent 自己负责跟 git 相关的所有杂活。用户跟 Agent 说完任务，Agent 在合适时机自动判断、自动执行 commit / push / worktree 等操作，跟用户交流时只用人话，不堆 git 术语。

## 动机

跟 Coding Agent 协作时已经有两类常见但用户「该懂但不一定懂」的 git 操作：

- **commit + push** —— 一段工作做完该保存进度并同步到云端
- **worktree + 分支** —— 加新 feature 时为了不破坏 main 上的工作开一条独立线

2026 年大量 Claude Code / Cursor 用户的尴尬：会用 Agent 写代码，但对 git 不熟、对 worktree 更不熟，每次都要让 Agent 一步步告诉自己「现在该 commit / 现在该 push / 现在该开 worktree」。让他们专门去学 Git 又有相当的理解门槛。easy-git 把这些判断 + 执行 + 翻译沉淀到一个 Skill，**屏蔽掉 git 这一层复杂度**。

具体来说，下面这些事用户不应该每次都重复跟 Agent 说，Agent 有足够信号自己判断：

- 一段相对完整的工作做完了 → 该 commit + push
- 用户说「加一个新功能」→ 该开 worktree + 新分支
- 改动里只动了某几个文件 → stage 那几个文件，不要 `-A`
- pre-commit hook 失败 → 修问题、再 stage、起新 commit，不要 amend / `--no-verify`

## 给谁用（ICP）

每天跟 Coding Agent（Claude Code 为主）协作写代码 / 写文档的人。

两类典型场景：

1. **开发者** ——「跟 Agent 一起写代码，希望 Agent 自己处理 git，不用我每次提醒」
2. **非纯粹开发者** ——「用 Agent 管个人项目（笔记、博客、life-os 这类），git 是手段不是目的，希望尽量看不到 git 术语」

## 触发与运行模式

**Agent 在两个时机自动触发 easy-git**：

| 时机 | 触发逻辑 |
|---|---|
| **任务开始时**（user prompt 进来） | 识别是不是「加新 feature」语义；如果是、且当前在 main / master 上 → 自动开 worktree + 新分支并跳到新 worktree 工作 |
| **任务结束时**（Stop hook 或同等机制） | 自动跑 `git status` + `git diff` → 有改动就自动决策 commit + push 并执行；没改动就静默退出 |

用户面什么都不需要做，最多在 commit / push / 开 worktree 之后看到 Agent 一句翻译过的状态描述。

## 核心能力

### 1. 自动判断「提交节点」

Agent 决定什么时候算「一个值得保存的节点」。判断信号：

- 一段任务做完了（Agent 自己声称完成的语义边界）
- 测试 / 类型检查通过
- 文档写完了
- 即将切换到另一类工作（从写代码切到改配置 / 切到写文档）

不在每修改一个文件后就 commit；也不在「半成品状态」commit（如导入了但没用、函数签名改了但 caller 没改完）。

### 2. 自动切「逻辑提交单元」（原子 commit）

绝大多数 task 不只产生一个语义簇的改动。例：用户让 Agent「加一个 endpoint + 测试 + 更新 README」会产生三类改动。skill 应**把这一类拆成多个 commit**，不堆一个大杂烩：

```
feat(api): add /tasks POST endpoint with Zod validation
test(api): add unit + integration tests for tasks POST
docs: update README with new endpoint and example payload
```

聚类启发式（优先级从高到低）：

1. **按改动性质**：feat / fix / refactor / docs / test / chore 不混
2. **按 scope**：不同 module / 不同顶层目录不混
3. **按目的**：一个 PR 描述能说清的一组改动 = 一个 commit

每个 commit 目标 ≤ 100 行，≤ 300 行可接受，>1000 行必须再拆。

### 3. Commit message 自动生成

风格 = **conventional commit type + scope + 中文描述**，沿用 life-os / drift-bottle 既有风格：

```
<type>(<scope>): <为什么改，不是改了什么>

<可选 body：补充上下文 / 决策依据 / 副作用>

Co-Authored-By: Claude <noreply@anthropic.com>
Co-Authored-By: Happy <yesreply@happy.engineering>
```

Type 候选：`feat` / `fix` / `refactor` / `docs` / `test` / `chore` / `progress`（多用于跟进类项目）/ `init`（仓库首次提交）。

**规则**：

- subject 中文，长度 ≤ 50 字符（中文按 2 字符算）
- 描述「为什么」，不是「改了什么」（diff 自己看）
- 避免「AI fixes」「Cursor suggestions」这种模糊 subject —— AI 介入信息走 body / trailer，不挤 subject
- co-author 标签按 harness 当前配置自动加（不需要用户每次提醒）

### 4. Commit + push 配对

**solo / 个人项目场景下默认 commit + push 配对**：一旦决定 commit，紧接着自动 push 到 origin 同分支。

理由：

- 用户的实际工作流就是配对（既有习惯）
- Solo / 个人项目 / trunk-based 都把配对当默认（业界共识）
- 让「保存进度」和「同步到 GitHub」对用户合并成一个动作，减少认知负担
- 一旦 push，commit 即视为公开历史 —— 强制 skill 内部不再 amend / rebase 该 commit

例外（不主动 push，先告知用户）：

- 当前分支是受保护分支且 push 会因为 CI / 保护规则失败
- 检测到 push 会触发 force-push 场景（本地 reset 过 / rebase 过 / 与远端 diverge）

不论何种场景，永远不 `--force` push 到 `main` / `master`。

### 5. Feature 分支与 worktree

「加新 feature」语义触发时（task 开始时识别），自动开 worktree + 新分支并跳过去工作：

```
~/repos/<project>/                     ← main，主仓
~/repos/<project>-<feature-name>/      ← worktree，跟主仓平级
                                          目录名 = 分支名 = 任务名
```

**规则**：

- worktree 路径**跟主仓平级**，永不嵌套在主仓内（嵌套会让 git 进入无限递归）
- 命名一致：worktree 目录 = 分支名 = 任务名（终端 prompt 一眼能看出在哪条线）
- 一个 worktree 只做一个 task
- 分支短命（≤ 1-3 天），超期是 smell（提醒用户）
- 节制：默认 ≤ 2 个 worktree 同时存在
- 每个新 worktree 提醒用户初始化环境（`npm install` / `bundle install` / `uv sync` 等）
- 完成后合并 + 清理 worktree（**待定**：自动合并 / 提 PR / 告知用户三选一，见「待定决策」）

「加新 feature」识别启发式（v0 粗规则，需 dry-run 校准）：

- prompt 出现「加 / 实现 / 做一个 / 新加 / 引入」+ 名词 → 倾向 feature，开 worktree
- prompt 出现「改 / 修 / 调 / 更新 / 修复 / 优化」→ 倾向直接在当前分支做
- 当前不在 main / master 上 → 沿用当前分支，不开新 worktree
- 改动只涉及文档 / 配置 / 单个 bug fix → 不开 worktree

### 6. 人话沟通

Agent 跟用户讲的话里**完全不出现 git 术语**。翻译表（待补全到 `references/translation.md`）：

| Git 行为 | 对用户说什么 |
|---|---|
| `git commit` + `git push` 配对 | "保存了一段进度并同步到 GitHub" / "记了一笔并上传了" |
| `git pull` | "拉了一下最新" |
| 开 worktree + 新分支 | "我另起一条线做这个新功能，目录在 `xxx`" |
| `git merge` / 解决冲突 | "两边改了同一个地方，要选一下" |
| `staged changes` | "准备好的修改" |
| `untracked files` | "还没纳入管理的新文件" |
| pre-commit hook 失败 | "保存前的自动检查没过，我先修一下" |
| `git status` | "看看现在有哪些没保存的修改" |
| `.gitignore` | "告诉它哪些文件不用管" |

执行后只汇报结果，不汇报过程：

- ✅ "我把 PRD 那段保存了并同步到了 GitHub。"
- ✅ "我另起一条线 `feat-tasks-api` 做这个新功能，已经切到那个目录了。"
- ❌ "我执行了 `git worktree add ../<project>-feat-tasks-api -b feat-tasks-api && git add docs/prd.md && git commit -m '...' && git push`。"

## 安全护栏（绝不越）

下面这些动作 skill 永远不主动做，触发时必须先问用户：

- **暂存**：`git add -A` / `git add .`（永远按文件名 stage）
- **强制推送**：`git push --force` / `--force-with-lease` 到 `main` / `master` / 受保护分支
- **跳过校验**：`git commit --no-verify` / `--no-gpg-sign`（hook 失败先修问题）
- **修改已发布的历史**：`git commit --amend` 已 push 的 commit、`git rebase` 已 push 的 commit（一旦 push 就当公开历史，硬约束）
- **销毁性操作**：`git reset --hard`、`git checkout -- .` / `git restore .`、`git clean -f`、`git branch -D`
- **secrets 入库**：检测到 `.env` / `*.pem` / 看起来像 API key / token 的字符串 → 拦下来问
- **大文件 / 二进制入库**：> 10MB 或非文本文件 → 提醒一下
- **不明本地状态**：陌生分支 / 没听说过的未追踪文件 → 先 inspect，不直接清理
- **嵌套 worktree**：永不在主仓内部建 worktree，永远平级
- **复用 branch**：不把同一个分支挂到两个 worktree（git 也会拦，但 skill 不应该尝试）

hook 失败处理：修 → 重新 stage → **起新 commit**（不 amend，避免改到上一个 commit）。

## 与 `agent-skills:git-workflow-and-versioning` 的关系

那个 skill 是**参考资料**（passive reference）—— 告诉 Agent 什么是好的 git 实践（trunk-based development、atomic commits、commit message 格式、bisect 调试等），需要 Agent 自己读并决定何时应用。

easy-git 是**行动者**（active doer）：

| 维度 | git-workflow-and-versioning | easy-git |
|---|---|---|
| 角色 | 参考手册 | 自动执行者 |
| 触发 | Agent 在做 git 操作时主动查 | Agent 在 task 开始 / 结束自动启动 |
| 沟通对象 | Agent 自己（内化为行为） | 终端用户（翻译成人话） |
| 内化的偏好 | 行业通用最佳实践 | 用户个人偏好（commit+push 配对 / 禁 `-A` / co-author / commit 风格 / worktree）+ 通用实践 |
| 决策范围 | 「应该这样」 | 「现在就这样做」 |

合规关系：easy-git 的行为应**全部满足** git-workflow-and-versioning 的规范（atomic、conventional commit、separate concerns、size 控制等）。可在 SKILL.md 里把它列为依据 reference。

## 调研依据（截至 2026-05）

**通用 git 工程实践**：

- [Atomic Commits（LeanIX Engineering）](https://engineering.leanix.net/blog/atomic-commit/) —— 一个 commit 对应一个语义单元，可被 revert / cherry-pick / bisect
- [Commit Often, Perfect Later, Publish Once（Seth Robertson）](https://sethrobertson.github.io/GitBestPractices/) —— 本地频繁 commit，发布前整理
- [Conventional Commits 规范](https://www.conventionalcommits.org/en/v1.0.0/) —— `<type>(<scope>): <subject>` 格式
- [Git Workflow Best Practices 2026（dev.to）](https://dev.to/_d7eb1c1703182e3ce1782/git-workflow-best-practices-the-developers-guide-for-2026-4gl0) —— PR ≤ 400 行；自动化 hook / CI 落地
- [Git Workflows for Solo Developers (2026)](https://dasroot.net/posts/2026/03/git-workflows-solo-developers-content-creators/) —— solo 场景 commit+push 配对是常态；非共享分支 rebase 自由
- [Trunk Based Development（官方）](https://trunkbaseddevelopment.com/) —— 小而频繁集成回 main，分支短命 ≤ 1-3 天
- [Trunk-based Development — Atlassian](https://www.atlassian.com/continuous-delivery/continuous-integration/trunk-based-development) —— small frequent commits + 短命分支 + 配 feature flags

**AI Agent + git**：

- [How to Use Git with Coding Agents（2026）](https://marketingagent.blog/2026/03/22/how-to-use-git-with-coding-agents-a-complete-2026-guide/) —— AI 倾向一次性生成大块代码，要主动拆 atomic；AI 参与信息走 trailer，不挤 subject
- [Best Practices for Committing AI-Generated Code（DeployHQ）](https://www.deployhq.com/git/committing-ai-generated-code) —— Co-Authored-By 走 trailer 做机器可读归属
- [Best Git Automation Skills for AI Coding Agents（Agensi）](https://www.agensi.io/learn/best-git-automation-skills-ai-agents-2026) —— git-commit-writer / pr-description-writer / changelog-generator 三类 skill 形态
- [Agentic Coding Guardrails（Blink）](https://blink.new/blog/agentic-coding-best-practices) —— 高自主 = 高风险；分级 autonomy（读 = 全自动，低风险写 = 条件自动，高风险写 = 必须 human approval）

**Worktree + AI Agent 并行开发**：

- [The Claude Code Git Worktree Pattern（MindStudio）](https://www.mindstudio.ai/blog/what-is-claude-code-git-worktree-pattern-parallel-feature-branches) —— Claude Code 内置 `-w` flag；每个 task 一个 worktree
- [Using Git Worktrees for Multi-Feature Development with AI Agents](https://www.nrmitchi.com/2025/10/using-git-worktrees-for-multi-feature-development-with-ai-agents/) —— 多 Agent 并行同 spec 不同实现
- [Parallel AI Coding with Git Worktrees and Claude Code](https://docs.agentinterviews.com/blog/parallel-ai-coding-with-gitworktrees/) —— 2-4 个并行 session 是合理上限
- [Git Worktrees: The Complete Guide for 2026](https://devtoolbox.dedyn.io/blog/git-worktrees-complete-guide) —— 目录命名 / 平级放 / IDE 一窗一 worktree
- [Common workflows — Claude Code Docs](https://code.claude.com/docs/en/common-workflows) —— 官方 worktree 用法
- [How we're shipping faster with Claude Code and Git Worktrees — incident.io](https://incident.io/blog/shipping-faster-with-claude-code-and-git-worktrees) —— 团队实战经验

**关键洞察**：

- AI 写代码时一次产出量大 → easy-git 在拆 commit 上需比一般人更主动
- AI 归属不应隐藏 → Co-Authored-By 走 trailer 是行业共识
- **worktree + AI Agent 是 2026 年 AI 并行开发的主流模式**，且很多用户「会用 Claude Code 但不会用 worktree」—— 这是 easy-git 屏蔽掉的核心复杂度之一
- Solo 场景 commit + push 配对是当前共识；非共享分支 rebase / amend 自由，但**一旦 push 就当公开历史**是硬约束

## v0 形态

- **Claude Code Skill**：发布到 `~/.claude/skills/` 或通过 skill 安装器安装
- 结构：
  - `SKILL.md`（主入口：触发条件、核心逻辑、安全护栏）
  - `references/translation.md`（翻译词表完整版）
  - `references/commit-style.md`（commit message 模板 + 真实示例库）
  - `references/worktree-flow.md`（feature 分支识别 + worktree 生命周期）
  - `references/hook-recovery.md`（hook 失败处理流程）
- 触发方式：task 开始 hook（识别 feature → 开 worktree） + Stop hook（commit + push）

## v0 不做

- 非 Claude Code harness（Cursor / Codex / Windsurf）—— v1+ 考虑 MCP 化
- merge / rebase / cherry-pick 跨分支合并 —— 高风险操作必须用户手动确认（worktree 合回 main 例外，见待定）
- 自动解决 merge 冲突 —— 永远让用户决定
- GitHub Issue 自动操作 —— 是另一个 Skill 的范围
- 跟 IDE / 编辑器集成 —— 走 Claude Code harness 即可

## 待定决策

### 核心未决（**先聊清这一层，再写 SKILL.md**）

- [ ] **「加新 feature」识别精度**：上面的启发式（动词 + 名词 / 当前分支位置 / 改动范围）需要在真实 prompt 上 dry-run 校准。识别错的代价：(a) 该开 worktree 没开 → 污染 main；(b) 不该开却开了 → 用户觉得啰嗦多余
- [ ] **worktree 做完后怎么合**：
  - 选项 A：Agent 自动 merge 回 main + 清理 worktree（最丝滑，风险最高）
  - 选项 B：Agent 提 PR 等用户 review 后再合（标准做法）
  - 选项 C：Agent 只告知「这条线做完了」，由用户决定何时合（最保守）
- [ ] **是否纳入 PR 工作流**：跟上一条强相关。选 B 必做 PR；选 A / C 可以不做

### 待补全

- [ ] **翻译词表**：把 `references/translation.md` 写全（当前 PRD 里的表只是种子）
- [ ] **commit message 真实例库**：从用户已有仓库（life-os / drift-bottle / harness-book / prospector / easy-git）抽 20-30 条真实 commit 当作 few-shot 示例
- [ ] **worktree 生命周期细则**：默认目录命名模板（`<project>-<feature>` vs 别的）/ stale worktree 检测阈值（超过几天提醒）
- [ ] **测试 fixture**：搭一个 sandbox 仓库做 dry-run，验证 skill 行为

### 工程层

- [ ] **安装方式**：用户 clone + 软链 / 走 `npx skills install` / 出 `install.sh`
- [ ] **是否做成 MCP server**：让 Cursor / Codex / Windsurf 也能用（v1+）

### 分发层

- [ ] **README 怎么吸引人**：before-after 对话对比（演示「不用每次让 Agent commit + 不用懂 worktree」的体验差）

## 关联

- 参考依据：`agent-skills:git-workflow-and-versioning`（已分析覆盖范围与差异化，见上文）
- 上游经验：用户已沉淀的 git 实践（部分在 memory：commit+push 配对、禁 `git add -A`、按文件名 stage、co-author 标签、worktree+分支做 feature）
- 同生态：调研中提到的 AI commit writer 类工具（`aicommits`、`ai-commit`、softaworks/agent-toolkit 的 commit-work skill）—— easy-git 不止做 commit，覆盖 commit + push + worktree + 人话翻译 + 安全护栏
