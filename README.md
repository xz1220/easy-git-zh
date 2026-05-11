<a id="readme-top"></a>

<!-- PROJECT SHIELDS -->
[![Stars][stars-shield]][stars-url]
[![Forks][forks-shield]][forks-url]
[![Issues][issues-shield]][issues-url]
[![License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<div align="center">
  <h3 align="center">easy-git</h3>
  <p align="center">
    让 AI Agent 替你搞定 Git，你只管说人话。
    <br />
    <a href="docs/prd.md"><strong>查看完整 PRD »</strong></a>
    <br /><br />
    <a href="https://github.com/xz1220/easy-git/issues">报告 Bug</a>
    ·
    <a href="https://github.com/xz1220/easy-git/issues">提需求</a>
  </p>
</div>

> **Status**：立项中（2026-05）／ PRD 已稳定 ／ SKILL.md 与 references 实现中 ／ 还不能直接安装。

<!-- TABLE OF CONTENTS -->
<details>
  <summary>目录</summary>
  <ol>
    <li>
      <a href="#关于本项目">关于本项目</a>
      <ul>
        <li><a href="#你是不是也这样">你是不是也这样</a></li>
        <li><a href="#核心能力">核心能力</a></li>
        <li><a href="#基于">基于</a></li>
      </ul>
    </li>
    <li>
      <a href="#上手">上手</a>
      <ul>
        <li><a href="#前置条件">前置条件</a></li>
        <li><a href="#安装">安装</a></li>
      </ul>
    </li>
    <li><a href="#怎么用">怎么用</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#贡献">贡献</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#联系">联系</a></li>
    <li><a href="#致谢">致谢</a></li>
  </ol>
</details>

## 关于本项目

### 你是不是也这样

跟 AI Agent 一起干活的时候，两件最痛的事：

- **Agent 一通改下来动了 20 个文件，你越看越不对劲，想回到 10 分钟前 —— 回不去。** 没人替你存过节点，靠记忆一个一个手动撤是不现实的。AI 写得越快，没有版本管理的代价越大。
- **想用 Git 兜个底？** staging area / branch / merge / rebase / reset 软硬混合三种模式 …… 教程看到第三集还卡在第一个概念里：「我只是想存个进度啊。」绝大多数人卡这里：知道该用，用不起来。

easy-git 就是给这两个痛点设计的 —— AI Agent 在跟你对话的任何时机自己判断该不该保存进度、该不该开分支、该不该拦危险动作，**你只管干活，Git 这一层对你彻底透明**。

### 核心能力

- **自动 commit + push**：一段工作完成时自动保存进度、同步到远端，按语义拆成多个原子 commit，写标准 commit message（Follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)）
- **`.gitignore` 自动管理**：依赖目录（`node_modules/` / `.venv/` …）、构建产物（`dist/` …）、密钥（`.env` / `*.pem` …）、IDE 配置（`.vscode/` / `.DS_Store` …）默认拦掉，不让脏文件跟代码一起 commit
- **Worktree 管理**：跟 Agent 说「加个新功能 …」时自动开 worktree + 新分支；做完问你 (a) 直接合并清理 / (b) 提 PR review / (c) 暂时保留 三选一
- **人话翻译层**：用户面看不到 commit / push / rebase 这种术语，只有「保存了一段进度」「同步到 GitHub」「另起一条线做」之类的人话
- **安全护栏**：force push 到 main / reset --hard / commit 密钥 / 用 `-A` 一把梭 等危险动作永不主动做，全部拦下来问你

### 基于

* [Agent Skills 开放标准](https://agentskills.io/specification)
* [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)
* [Git](https://git-scm.com/)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 上手

### 前置条件

* 本地装好 Git（[git-scm.com](https://git-scm.com/downloads)）
* 一个支持 [Agent Skills 开放标准](https://agentskills.io/specification) 的 AI Agent（已知支持的有 32+ 个）：

  Claude Code · Codex CLI · Cursor · GitHub Copilot · Gemini CLI · Junie · Goose · Amp · TRAE · ……

  跟 MCP 没关系，是另一套更广的开放标准 —— **装一次，所有兼容 Agent 都能用**。

### 安装

**Claude Code**：

```bash
/plugin marketplace add xz1220/easy-git
/plugin install easy-git
```

**其他兼容 Agent**：按各自的 skill 安装机制，详见 [PRD 安装章节](docs/prd.md#安装)。

装完之后什么都不用做，AI Agent 会自己在合适时机调用。

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 怎么用

下面是两个典型场景，对比有没有 easy-git 时的体验差。

### 场景一：Agent 改坏了，你想回到上一个完好的版本

**没装 easy-git**：

```
你：帮我把搜索功能优化一下
Agent：好，改了 12 个文件……
你：等等，效果比之前还差，能恢复原来的代码吗？
Agent：抱歉我没存过保存点，需要你逐个文件回想之前的样子……
你：……
```

**装了 easy-git**：

```
（easy-git 在之前每段工作完成时都自动存了保存点）
你：帮我把搜索功能优化一下
Agent：改了 12 个文件，已经存了一笔并同步到 GitHub。
你：效果不对，回到上一个版本
Agent：好，已经回退到刚才那个保存点了。
```

### 场景二：加个新功能不敢动主分支，但又不会 worktree

**没装 easy-git**：

```
你：帮我加一个用户登录功能
Agent：（直接在当前分支改）改了 30 个文件
你：等等，你应该开个分支再做啊
Agent：抱歉我现在 reset 一下重来……
你：……
```

**装了 easy-git**：

```
你：帮我加一个用户登录功能
Agent：这个改动比较大，我另起一条线 feat-user-login 做，
       已经切到 ~/repos/my-app-feat-user-login 了。
       做完之后我会问你怎么合回去。
```

### 谁可以用

- 写代码的开发者
- 写文档 / PRD / 笔记 / 博客的产品 / 运营 / 研究者
- 用 Agent 做创作的（写作、设计稿）
- **任何一个用 Agent 干活、想要版本管理兜底但不想被 Git 绊住的人**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Roadmap

- [x] PRD v4 稳定（按 Agent Skills 开放标准定位）
- [x] User Story 风格 README
- [ ] 写 `SKILL.md`（按 Agent Skills 规范，含 frontmatter + 主体）
- [ ] `references/translation.md`（翻译词表，按 [`giteveryday`](https://git-scm.com/docs/giteveryday) 全量梳理）
- [ ] `references/commit-style.md`（Conventional Commits 规范 + 公开范例库）
- [ ] `references/worktree-flow.md`（worktree 生命周期 + 命名规则）
- [ ] `references/hook-recovery.md`（pre-commit hook 失败恢复流程）
- [ ] 测试 fixture（空 sandbox 仓库 + dry-run 命令集）
- [ ] 详细分析 [netresearch/git-workflow-skill](https://github.com/netresearch/git-workflow-skill) 等同类 skill，确认差异化
- [ ] v0 发布到 Agent Skills marketplace

详见 [PRD](docs/prd.md) 的「PRD 之后要做的事」章节。

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 贡献

欢迎 issue 和 PR。

1. Fork 本项目
2. 起 feature 分支（`git checkout -b feature/your-feature`）
3. 写改动 + commit
4. Push 到你的分支（`git push origin feature/your-feature`）
5. 提 PR

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 联系

xz1220 — [@xz1220 on GitHub](https://github.com/xz1220)

项目仓库：[https://github.com/xz1220/easy-git](https://github.com/xz1220/easy-git)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## 致谢

**标准与规范**：

* [Agent Skills 开放标准（agentskills.io）](https://agentskills.io/specification)
* [anthropics/skills（官方仓库）](https://github.com/anthropics/skills)
* [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/)

**Git 官方文档**：

* [Git Everyday](https://git-scm.com/docs/giteveryday) —— 常用命令参考（翻译词表来源）
* [Pro Git Book](https://git-scm.com/book/en/v2)
* [git-worktree(1)](https://git-scm.com/docs/git-worktree)

**同类 skill（参考实现）**：

* [netresearch/git-workflow-skill](https://github.com/netresearch/git-workflow-skill)
* [huggingface/upskill](https://github.com/huggingface/upskill)
* [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills)
* [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates)

**模板**：

* [Best-README-Template by othneildrew](https://github.com/othneildrew/Best-README-Template)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[stars-shield]: https://img.shields.io/github/stars/xz1220/easy-git.svg?style=for-the-badge
[stars-url]: https://github.com/xz1220/easy-git/stargazers
[forks-shield]: https://img.shields.io/github/forks/xz1220/easy-git.svg?style=for-the-badge
[forks-url]: https://github.com/xz1220/easy-git/network/members
[issues-shield]: https://img.shields.io/github/issues/xz1220/easy-git.svg?style=for-the-badge
[issues-url]: https://github.com/xz1220/easy-git/issues
[license-shield]: https://img.shields.io/github/license/xz1220/easy-git.svg?style=for-the-badge
[license-url]: https://github.com/xz1220/easy-git/blob/main/LICENSE
