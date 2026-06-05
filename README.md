# Claude Code 个人配置仓库

用 Git 管理 Claude Code 的**个人全局配置**，方便在多台机器之间迁移。

本仓库管理三类内容：

| 类型 | 仓库中的位置 | 机器上的位置 |
|------|-------------|-------------|
| **Plugin** | `plugins.lock` + `marketplaces.lock` | `~/.claude/plugins/cache/`（自动下载） |
| **独立 Skill** | `skills/<名字>/` | `~/.claude/skills/<名字>/`（符号链接） |
| **独立 MCP** | `mcp/user-servers.json` | `~/.claude.json` → `mcpServers` |
| **个人偏好** | `settings.json`、`CLAUDE.md` | `~/.claude/` |

---

## 目录结构

```
claude-setup/
├── bootstrap.sh              # 新机器一键恢复（核心脚本）
├── README.md                 # 本文件
├── .env.example              # 密钥模板
├── .gitignore
│
├── plugins.lock              # 已安装的 plugin 清单
├── marketplaces.lock         # 已添加的 marketplace 清单
│
├── skills/                   # 独立 skill（不在 plugin 内）
│   └── <skill-name>/
│       └── SKILL.md
│
├── mcp/
│   ├── user-servers.json     # 独立 MCP 配置（进 Git）
│   └── user-servers.example.json
│
├── settings.json             # 权限、hooks、环境变量
├── CLAUDE.md                 # 全局个人偏好
│
└── scripts/
    ├── add-plugin.sh         # 安装 plugin 并记录
    ├── add-skill.sh          # 添加独立 skill
    └── add-mcp.sh            # 添加 MCP 配置
```

---

## 首次使用（当前机器）

### 1. 初始化 Git 仓库

```bash
cd ~/claude-setup
git init
git add .
git commit -m "init claude personal setup"
git remote add origin <你的私有仓库地址>
git push -u origin main
```

### 2. 配置密钥（如有 MCP 需要）

```bash
cp .env.example .env
# 编辑 .env，填入 API Key
```

### 3. 运行恢复脚本

```bash
~/claude-setup/bootstrap.sh
claude login    # 首次需要登录
```

---

## 日常：安装新东西

### 安装 Plugin（来自 marketplace）

```bash
# 方式 1：使用辅助脚本（推荐，自动写入 plugins.lock）
~/claude-setup/scripts/add-plugin.sh github@claude-plugins-official

# 方式 2：手动安装后记录
claude plugin install linear@claude-plugins-official
echo "linear@claude-plugins-official" >> ~/claude-setup/plugins.lock
```

如需添加第三方 marketplace：

```bash
claude plugin marketplace add anthropics/claude-plugins-community
echo "anthropics/claude-plugins-community" >> ~/claude-setup/marketplaces.lock
```

安装后提交：

```bash
cd ~/claude-setup
git add plugins.lock marketplaces.lock
git commit -m "add plugins"
git push
```

### 安装独立 Skill（不在 plugin 内）

```bash
# 从别人分享的目录或 SKILL.md 文件添加
~/claude-setup/scripts/add-skill.sh my-skill /path/to/skill-source

# 提交
cd ~/claude-setup
git add skills/my-skill
git commit -m "add skill: my-skill"
git push
```

Skill 会链接到 `~/.claude/skills/my-skill/`，重启 Claude Code 或新开会话后生效。

### 安装独立 MCP（不在 plugin 内）

**方式 1：编辑 JSON 配置（推荐，便于 Git 管理）**

参考 `mcp/user-servers.example.json`，编辑 `mcp/user-servers.json`：

```json
{
  "mcpServers": {
    "github": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PERSONAL_ACCESS_TOKEN}"
      }
    }
  }
}
```

在 `.env` 中配置对应密钥，然后：

```bash
~/claude-setup/bootstrap.sh
```

**方式 2：使用 claude mcp add 后手动同步**

```bash
claude mcp add --scope user github \
  -e GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx \
  -- npx -y @modelcontextprotocol/server-github

# 查看配置，抄到 mcp/user-servers.json（密钥改用 ${VAR}）
claude mcp get github
```

**方式 3：使用辅助脚本**

```bash
~/claude-setup/scripts/add-mcp.sh github \
  '{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-github"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"${GITHUB_PERSONAL_ACCESS_TOKEN}"}}'

~/claude-setup/bootstrap.sh
```

提交：

```bash
cd ~/claude-setup
git add mcp/user-servers.json
git commit -m "add mcp: github"
git push
```

> **注意**：独立 MCP 必须使用 `--scope user`（或在 JSON 中由 bootstrap 写入顶层 `mcpServers`），才能在所有项目中全局生效。

---

## 换机器恢复（完整流程）

```bash
# 1. 安装 Claude Code（若尚未安装）
npm install -g @anthropic-ai/claude-code@latest

# 确保 claude 在 PATH 中（根据你的环境调整）
export PATH="$HOME/.local/node/bin:$HOME/.npm-global/bin:$PATH"

# 2. 克隆配置仓库
git clone <你的私有仓库地址> ~/claude-setup

# 3. 配置密钥
cp ~/claude-setup/.env.example ~/claude-setup/.env
# 编辑 .env 填入 API Key

# 4. 一键恢复所有配置
~/claude-setup/bootstrap.sh

# 5. 登录（每台机器单独做一次，无法 Git 同步）
claude login

# 6. 验证
claude plugin list
claude mcp get <mcp-name>    # 如有配置 MCP
ls ~/.claude/skills/
claude
```

`bootstrap.sh` 会自动完成：

1. 添加 `marketplaces.lock` 中的 marketplace
2. 安装 `plugins.lock` 中的 plugin
3. 将 `skills/` 链接到 `~/.claude/skills/`
4. 将 `mcp/user-servers.json` 合并到 `~/.claude.json`（保留 OAuth）
5. 同步 `settings.json` 和 `CLAUDE.md`

---

## 什么进 Git、什么不进

| 进 Git | 不进 Git |
|--------|----------|
| `plugins.lock`、`marketplaces.lock` | `~/.claude/plugins/cache/` |
| `skills/` | `~/.claude.json` 整文件（含 OAuth） |
| `mcp/user-servers.json` | `.env`（API Key） |
| `settings.json`、`CLAUDE.md` | 会话记录、缓存、telemetry |

---

## 常见问题

### Plugin 安装失败？

- 确认 marketplace 已添加：检查 `marketplaces.lock`
- 更新 marketplace：`claude plugin marketplace update <name>`
- 官方商店 `claude-plugins-official` 默认内置，无需手动添加

### Skill 不生效？

- 确认 `skills/<name>/SKILL.md` 存在
- 重新运行 `bootstrap.sh` 或检查链接：`ls -la ~/.claude/skills/`
- 新开 Claude Code 会话

### MCP 不生效？

- 确认 `mcp/user-servers.json` 非空
- 确认 `.env` 中密钥已配置
- 运行 `claude mcp get <name>` 检查状态
- 重新运行 `bootstrap.sh`

### 为什么不把 plugin 缓存放进 Git？

Plugin 是 marketplace 下载的安装产物，体积大且会自动更新。Git 只记录「装了什么」（`plugins.lock`），换机器重新安装即可。

### 为什么不把 ~/.claude.json 整文件放进 Git？

该文件混合了 OAuth 认证和 MCP 配置。整文件入库有泄露风险。本仓库只管理 `mcp/user-servers.json` 模板，bootstrap 时合并 MCP 部分。
