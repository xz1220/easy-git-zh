# easy-git

> 让 AI Agent 替你搞定 Git，你只管说人话。

> **Status**：立项中（2026-05）／ PRD 已稳定 ／ SKILL.md 与 references 实现中 ／ 还不能直接安装。进展见 [`docs/prd.md`](docs/prd.md)。

## 你是不是也这样

跟 Claude Code / Cursor / Codex 这些 AI Agent 一起干活的时候 ——

- 每次写完一段代码 / 文档，都要专门跟 Agent 说一句「commit 一下」「push 一下」，又啰嗦又烦
- 想加个新功能，又不敢直接动主分支，可是 worktree 是啥都不知道，只能凑合
- 一不小心把 `.env` / API key 跟代码一起 commit 了，等发现的时候已经 push 到公开仓上
- 想给自己的工作上点版本管理兜底，但被 staging area / rebase / reset --hard 这些概念劝退，干脆放弃
- 你压根不是开发者，只是用 Agent 写文档 / 做创作 / 管个人项目，但你也想要版本管理，不想哪天电脑坏了或者改错了找不回来

easy-git 就是给这些场景设计的。

## 它做什么

装好 easy-git 之后，AI Agent 在跟你对话的任何时机自己判断要不要调用 Git，把版本管理这一层对你**彻底透明**。

对比一下 ——

### 没装 easy-git

```
你：帮我把 README 里的链接更新一下
Agent：好的，我改完了
你：commit 加 push 一下
Agent：好，commit 完成，push 也成功了
你（下次还要再说一遍）：commit 加 push 一下
```

### 装了 easy-git

```
你：帮我把 README 里的链接更新一下
Agent：改完了，已经把这段保存了并同步到 GitHub。
```

完。

再来一个 ——

### 没装 easy-git

```
你：帮我加一个用户登录的功能
Agent：我直接在你当前分支改了，已经动了 30 个文件
你：等等，你应该开个分支再做啊
Agent：抱歉，我现在 reset 一下重来 ……
你：……
```

### 装了 easy-git

```
你：帮我加一个用户登录的功能
Agent：这个改动比较大，我另起一条线 `feat-user-login`
       做这件事，已经切到 ~/repos/my-app-feat-user-login 了。
       做完之后我会问你怎么合回去。
```

## 核心能力

- **自动 commit + push**：一段工作完成时自动保存进度、同步到远端，按语义拆成多个原子 commit，写标准 commit message（Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)）
- **`.gitignore` 自动管理**：依赖目录（`node_modules/` / `.venv/` …）、构建产物（`dist/` …）、密钥（`.env` / `*.pem` …）、IDE 配置（`.vscode/` / `.DS_Store` …）默认拦掉，不让脏文件跟代码一起 commit
- **Worktree 管理**：跟 Agent 说「加个新功能 …」时自动开 worktree + 新分支；做完问你 (a) 直接合并清理 / (b) 提 PR review / (c) 暂时保留 三选一
- **人话翻译层**：用户面看不到 commit / push / rebase 这种术语，只有「保存了一段进度」「同步到 GitHub」「另起一条线做」之类的人话
- **安全护栏**：force push 到 main / reset --hard / commit 密钥 / 用 `-A` 一把梭 等危险动作永不主动做，全部拦下来问你

## 谁可以用

- 写代码的开发者
- 写文档 / PRD / 笔记 / 博客的产品 / 运营 / 研究者
- 用 Agent 做创作的（写作、设计稿）
- **任何一个用 Agent 干活、想要版本管理兜底但不想被 Git 绊住的人**

## 在哪能用

easy-git 符合 [Agent Skills 开放标准](https://agentskills.io/specification)，**装一次，32+ 个 AI Agent 工具都能用**：

Claude Code · Codex CLI · Cursor · GitHub Copilot · Gemini CLI · Junie · Goose · Amp · TRAE · …

跟 MCP 没关系，是另一套更广的开放标准。

## 安装（实现完成后）

**Claude Code**：

```bash
/plugin marketplace add xz1220/easy-git
/plugin install easy-git
```

**其他 Agent**：按各自的 skill 安装机制，详见 [PRD 安装章节](docs/prd.md#安装)。

装完之后什么都不用做。下次让 Agent 干活的时候，Git 这一层会自动处理。

## 想多了解

- [完整 PRD（需求与设计）](docs/prd.md)
- [Agent Skills 开放标准](https://agentskills.io/specification)
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/) —— easy-git 默认的 commit message 风格
- 同类参考：[netresearch/git-workflow-skill](https://github.com/netresearch/git-workflow-skill) · [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)

## License

MIT
