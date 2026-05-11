# easy-git PRD

## 我们要做什么

一个 **Claude Code Skill**，让 Coding Agent 自己负责跟 git 相关的所有杂活。用户跟 Agent 说完任务，Agent 在任务结束时自动判断、自动执行 commit / push，跟用户交流时只用人话，不堆 git 术语。

## 动机

跟 Coding Agent 对话时，绝大多数 git 操作其实有明确的判断逻辑：

- 一段相对完整的工作做完了 → 该 commit
- 文档 / PRD 写完了 → 该 push 到 GitHub 给人 review
- 改动里只动了某几个文件 → stage 那几个文件，不要 `-A`
- pre-commit hook 失败 → 修问题、再 stage、起新 commit，不要 amend / `--no-verify`

这些事用户不应该每次都重复跟 Agent 说。但很多 Agent 默认不敢动 git，或者会用「commit / push / staged」这种术语把用户拉进技术细节里。easy-git 把这些判断和翻译沉淀成一个 Skill。

## 给谁用（ICP）

每天跟 Coding Agent（Claude Code 为主）协作写代码 / 写文档的人。

两类典型场景：

1. **开发者** ——「跟 Agent 一起写代码，希望 Agent 自己处理 git，不用我每次提醒」
2. **非纯粹开发者** ——「用 Agent 管个人项目（笔记、博客、life-os 这类），git 是手段不是目的，希望尽量看不到 git 术语」

## 触发与运行模式

**Agent 自动触发**，不依赖用户主动调用：

- 任务结束（Stop hook 或同等机制）→ skill 自动启动
- 先跑只读分析（`git status` / `git diff`）→ 判断有没有值得保存的改动
- 有改动 → 自动决策 commit / push 并执行
- 没改动 → 静默退出

用户面什么都不需要做，最多在 commit / push 之后看到 Agent 一句翻译过的状态描述。

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

### 4. 自动判断 push 时机

| 改动类型 | push 策略 |
|---|---|
| 全是文档（diff 仅命中 `*.md` / `docs/` / `README`） | **自动 push** |
| 全是代码 | **待定**（默认事后告知 vs 事前确认 vs 全自动） |
| 混合 | 按代码策略走（保守） |

文档场景自动 push 是既有习惯（用户在 GitHub 上 review）；代码场景是核心未决项，见「待定决策」。

不论哪种场景，永远不 `--force` push 到 `main` / `master`。

### 5. 人话沟通

Agent 跟用户讲的话里**完全不出现 git 术语**。翻译表（待补全到 `references/translation.md`）：

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
| `git status` | "看看现在有哪些没保存的修改" |
| `.gitignore` | "告诉它哪些文件不用管" |

执行后只汇报结果，不汇报过程：

- ✅ "我把 PRD 那段保存了，并同步到了 GitHub。"
- ❌ "我执行了 `git add docs/prd.md && git commit -m '...' && git push`。"

## 安全护栏（绝不越）

下面这些动作 skill 永远不主动做，触发时必须先问用户：

- **暂存**：`git add -A` / `git add .`（永远按文件名 stage）
- **强制推送**：`git push --force` / `--force-with-lease` 到 `main` / `master` / 受保护分支
- **跳过校验**：`git commit --no-verify` / `--no-gpg-sign`（hook 失败先修问题）
- **修改已发布的历史**：`git commit --amend`、`git rebase` 已 push 的 commit
- **销毁性操作**：`git reset --hard`、`git checkout -- .` / `git restore .`、`git clean -f`、`git branch -D`
- **secrets 入库**：检测到 `.env` / `*.pem` / 看起来像 API key / token 的字符串 → 拦下来问
- **大文件 / 二进制入库**：> 10MB 或非文本文件 → 提醒一下
- **不明本地状态**：陌生分支 / 没听说过的未追踪文件 → 先 inspect，不直接清理

hook 失败处理：修 → 重新 stage → **起新 commit**（不 amend，避免改到上一个 commit）。

## 与 `agent-skills:git-workflow-and-versioning` 的关系

那个 skill 是**参考资料**（passive reference）—— 告诉 Agent 什么是好的 git 实践（trunk-based development、atomic commits、commit message 格式、bisect 调试等），需要 Agent 自己读并决定何时应用。

easy-git 是**行动者**（active doer）：

| 维度 | git-workflow-and-versioning | easy-git |
|---|---|---|
| 角色 | 参考手册 | 自动执行者 |
| 触发 | Agent 在做 git 操作时主动查 | Agent 任务结束时自动启动 |
| 沟通对象 | Agent 自己（内化为行为） | 终端用户（翻译成人话） |
| 内化的偏好 | 行业通用最佳实践 | 用户个人偏好（禁 `-A`、co-author 标签、commit 风格等）+ 通用实践 |
| 决策范围 | 「应该这样」 | 「现在就这样做」 |

合规关系：easy-git 的行为应**全部满足** git-workflow-and-versioning 的规范（atomic、conventional commit、separate concerns、size 控制等）。可在 SKILL.md 里把它列为依据 reference。

## 调研依据（截至 2026-05）

**通用 git 工程实践**：

- [Atomic Commits（LeanIX Engineering）](https://engineering.leanix.net/blog/atomic-commit/) —— 一个 commit 对应一个语义单元，可被 revert / cherry-pick / bisect
- [Commit Often, Perfect Later, Publish Once（Seth Robertson）](https://sethrobertson.github.io/GitBestPractices/) —— 本地频繁 commit，发布前整理
- [Conventional Commits 规范](https://www.conventionalcommits.org/en/v1.0.0/) —— `<type>(<scope>): <subject>` 格式
- [Git Workflow Best Practices 2026（dev.to）](https://dev.to/_d7eb1c1703182e3ce1782/git-workflow-best-practices-the-developers-guide-for-2026-4gl0) —— PR ≤ 400 行；自动化 hook / CI 落地

**AI Agent + git**：

- [How to Use Git with Coding Agents（2026）](https://marketingagent.blog/2026/03/22/how-to-use-git-with-coding-agents-a-complete-2026-guide/) —— AI 倾向一次性生成大块代码，要主动拆 atomic；AI 参与信息走 trailer，不挤 subject；不用「AI fixes」这种模糊 message
- [Best Practices for Committing AI-Generated Code（DeployHQ）](https://www.deployhq.com/git/committing-ai-generated-code) —— 不掩盖 AI 介入痕迹，用 Git trailer（Co-Authored-By）做机器可读归属
- [Best Git Automation Skills for AI Coding Agents（Agensi）](https://www.agensi.io/learn/best-git-automation-skills-ai-agents-2026) —— git-commit-writer / pr-description-writer / changelog-generator 三类 skill 形态
- [Agentic Coding Guardrails（Blink）](https://blink.new/blog/agentic-coding-best-practices) —— 高自主 = 高风险；分级 autonomy（读 = 全自动，低风险写 = 条件自动，高风险写 = 必须 human approval）

**关键洞察**：

- AI 写代码时一次产出量大 → easy-git 在拆 commit 上需比一般人更主动
- AI 归属不应隐藏 → Co-Authored-By 走 trailer 是行业共识
- 自主分级思路可直接用：commit（本地可回滚）→ 全自动；push 文档（影响小）→ 全自动；push 代码（共享 / blast radius 大）→ 待决

## v0 形态

- **Claude Code Skill**：发布到 `~/.claude/skills/` 或通过 skill 安装器安装
- 结构：
  - `SKILL.md`（主入口：触发条件、核心逻辑、安全护栏）
  - `references/translation.md`（翻译词表完整版）
  - `references/commit-style.md`（commit message 模板 + 真实示例库）
  - `references/hook-recovery.md`（hook 失败处理流程）
- 触发方式 = Stop hook（任务结束时启动）

## v0 不做

- 非 Claude Code harness（Cursor / Codex / Windsurf）—— v1+ 考虑 MCP 化
- 多分支策略 —— 假设用户已经在他想要的分支上，不自动开 feature branch
- GitHub Issue / PR 操作 —— 是另一个 Skill 的范围
- merge / rebase / cherry-pick —— 高风险操作必须用户手动
- 跟 IDE / 编辑器集成 —— 走 Claude Code harness 即可

## 待定决策

### 核心未决（**先聊清这一层，再写 SKILL.md**）

- [ ] **代码场景的 push 策略**：（文档场景已定 = 自动 push）
  - 选项 A：永远自动 push（统一行为，但代码 push 到 main 风险更大）
  - 选项 B：满足某些信号才自动 push（如 task 结束 + tests 通过 + 当前分支不是 main）
  - 选项 C：默认事后告知（"我保存了并同步上去了"），不事前确认
  - 选项 D：默认事前问一句（"我准备同步上去，可以吗？"）

- [ ] **commit 是否需要事前确认**：默认完全自动 + 事后告知 vs 永远先讲一句再做

- [ ] **「逻辑提交单元」启发式如何编码**：上面写了一套优先级，但需要在真实多文件改动上做几次 dry-run，调出经验值

### 待补全

- [ ] **翻译词表**：把 `references/translation.md` 写全（当前 PRD 里的表只是种子）
- [ ] **commit message 真实例库**：从用户已有仓库（life-os / drift-bottle / harness-book / prospector）抽 20-30 条真实 commit 当作 few-shot 示例
- [ ] **测试 fixture**：搭一个 sandbox 仓库做 dry-run，验证 skill 行为

### 工程层

- [ ] **安装方式**：用户 clone + 软链 / 走 `npx skills install` / 出 `install.sh`
- [ ] **是否做成 MCP server**：让 Cursor / Codex / Windsurf 也能用（v1+）

### 分发层

- [ ] **README 怎么吸引人**：before-after 对话对比（演示「不用每次让 Agent commit」的体验差）

## 关联

- 参考依据：`agent-skills:git-workflow-and-versioning`（已分析覆盖范围与差异化，见上文）
- 上游经验：用户已沉淀的 git 实践（部分在 memory：禁 `git add -A`、文档写完即 push、按文件名 stage、co-author 标签）
- 同生态：调研中提到的 AI commit writer 类工具（`aicommits`、`ai-commit`、softaworks/agent-toolkit 的 commit-work skill）—— easy-git 不止做 commit，覆盖 commit + push + 人话翻译 + 安全护栏
