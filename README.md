# Claude Code 个人配置仓库

用 Git 管理 Claude Code 的**个人全局配置**，方便在多台机器之间迁移。

远程仓库：[github.com/1Keria/Claude_config](https://github.com/1Keria/Claude_config)

---

## 本仓库管理什么

| 类型 | 仓库中的位置 | 机器上的位置 |
|------|-------------|-------------|
| **第三方 API** | `settings.json`（端点/模型）+ `.env`（密钥） | `~/.claude/settings.json` |
| **Plugin** | `plugins.lock` + `marketplaces.lock` | `~/.claude/plugins/cache/`（自动下载） |
| **独立 Skill** | `skills/<名字>/` | `~/.claude/skills/<名字>/`（符号链接） |
| **独立 MCP** | `mcp/user-servers.json` | `~/.claude.json` → `mcpServers` |
| **个人偏好** | `CLAUDE.md` | `~/.claude/CLAUDE.md` |

---

## 目录结构

```
claude-setup/
├── bootstrap.sh              # 新机器一键恢复（核心脚本）
├── README.md
├── .env                      # 本地密钥（不进 Git）
├── .env.example              # 密钥模板
├── .gitignore
│
├── settings.json             # API 端点、模型、权限、hooks
├── CLAUDE.md                 # 全局个人偏好
│
├── plugins.lock              # 已安装的 plugin 清单
├── marketplaces.lock         # 已添加的 marketplace 清单
│
├── skills/                   # 独立 skill（不在 plugin 内）
│   └── <skill-name>/
│       └── SKILL.md
│
├── mcp/
│   ├── user-servers.json     # 独立 MCP 配置
│   └── user-servers.example.json
│
└── scripts/
    ├── add-plugin.sh
    ├── add-skill.sh
    └── add-mcp.sh
```

---

## 第三方 API 登录（Right Code）

本仓库已配置 [Right Code](https://docs.right.codes/docs/rc_cli_config/claudecode) 作为 Claude Code 的 API 来源，**无需运行 `claude login`**。

### 配置说明

| 配置项 | 存放位置 | 说明 |
|--------|----------|------|
| API 地址 | `settings.json` → `ANTHROPIC_BASE_URL` | 当前：`https://right.codes/claude-aws` |
| 默认模型 | `settings.json` | Sonnet / Opus / Haiku 模型 ID |
| API Key | `.env` → `ANTHROPIC_AUTH_TOKEN` | **不进 Git**，bootstrap 时注入 |

Right Code 提供两个渠道（如需切换，改 `settings.json` 中的 `ANTHROPIC_BASE_URL`）：

| 渠道 | 地址 |
|------|------|
| CC 官渠 | `https://right.codes/claude` |
| AWS 渠道 | `https://right.codes/claude-aws`（当前使用） |

当前可用模型（以网关实际返回为准）：

- `claude-sonnet-4-6`
- `claude-opus-4-6` / `claude-opus-4-7` / `claude-opus-4-8`
- `claude-haiku-4-5-20251001`

### 首次配置 API Key

```bash
cd ~/claude-setup
cp .env.example .env
# 编辑 .env，填入 Right Code 后台生成的 API Key：
# ANTHROPIC_AUTH_TOKEN=sk-xxxxxxxx

~/claude-setup/bootstrap.sh
```

### 验证是否可用

```bash
claude -p "你好" --model claude-sonnet-4-6
# 正常返回内容即表示配置成功

claude    # 启动交互式会话
```

### 密钥安全

- `.env` 已在 `.gitignore` 中，**切勿提交到 Git**
- API Key 只写在 `.env`，`settings.json` 里不含密钥
- 若密钥泄露，请到 Right Code 后台轮换

---

## 快速开始（当前机器）

```bash
# 1. 克隆仓库（若尚未克隆）
git clone git@github.com:1Keria/Claude_config.git ~/claude-setup

# 2. 配置 API Key
cp ~/claude-setup/.env.example ~/claude-setup/.env
# 编辑 .env 填入 ANTHROPIC_AUTH_TOKEN

# 3. 一键恢复
~/claude-setup/bootstrap.sh

# 4. 启动
claude
```

---

## 换机器恢复（完整流程）

```bash
# 1. 安装 Claude Code
npm install -g @anthropic-ai/claude-code@latest
export PATH="$HOME/.local/node/bin:$HOME/.npm-global/bin:$PATH"

# 2. 配置 GitHub SSH（用于 clone 本仓库）
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub   # 添加到 GitHub → Settings → SSH keys

# 3. 克隆配置仓库
git clone git@github.com:1Keria/Claude_config.git ~/claude-setup

# 4. 配置密钥
cp ~/claude-setup/.env.example ~/claude-setup/.env
# 编辑 .env：
#   - ANTHROPIC_AUTH_TOKEN（Right Code API Key，必需）
#   - 其他 MCP 密钥（按需）

# 5. 一键恢复
~/claude-setup/bootstrap.sh

# 6. 验证
claude -p "测试" --model claude-sonnet-4-6
claude plugin list
ls ~/.claude/skills/
claude
```

### bootstrap.sh 会自动完成

1. 加载 `.env` 环境变量
2. 添加 `marketplaces.lock` 中的 marketplace
3. 安装 `plugins.lock` 中的 plugin
4. 将 `skills/` 链接到 `~/.claude/skills/`
5. 将 `mcp/user-servers.json` 合并到 `~/.claude.json`（保留其它字段）
6. 将 `settings.json` 同步到 `~/.claude/settings.json`，并从 `.env` 注入 `ANTHROPIC_AUTH_TOKEN`

---

## 日常：安装新东西

### 安装 Plugin（来自 marketplace）

```bash
# 推荐：辅助脚本（自动写入 plugins.lock）
~/claude-setup/scripts/add-plugin.sh github@claude-plugins-official

# 或手动安装后记录
claude plugin install linear@claude-plugins-official
echo "linear@claude-plugins-official" >> ~/claude-setup/plugins.lock
```

添加第三方 marketplace：

```bash
claude plugin marketplace add anthropics/claude-plugins-community
echo "anthropics/claude-plugins-community" >> ~/claude-setup/marketplaces.lock
```

提交变更：

```bash
cd ~/claude-setup
git add plugins.lock marketplaces.lock
git commit -m "add plugins"
git push
```

### 安装独立 Skill（不在 plugin 内）

```bash
~/claude-setup/scripts/add-skill.sh my-skill /path/to/skill-source

cd ~/claude-setup
git add skills/my-skill
git commit -m "add skill: my-skill"
git push
```

### 安装独立 MCP（不在 plugin 内）

编辑 `mcp/user-servers.json`（参考 `mcp/user-servers.example.json`），在 `.env` 中配置对应密钥，然后：

```bash
~/claude-setup/bootstrap.sh
```

或使用辅助脚本：

```bash
~/claude-setup/scripts/add-mcp.sh github \
  '{"type":"stdio","command":"npx","args":["-y","@modelcontextprotocol/server-github"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"${GITHUB_PERSONAL_ACCESS_TOKEN}"}}'

~/claude-setup/bootstrap.sh
```

> 独立 MCP 使用 `--scope user` 或在 `mcp/user-servers.json` 中配置，可在所有项目全局生效。

---

## 什么进 Git、什么不进

| 进 Git | 不进 Git |
|--------|----------|
| `settings.json`（端点、模型，**无密钥**） | `.env`（API Key、MCP 密钥） |
| `plugins.lock`、`marketplaces.lock` | `~/.claude/plugins/cache/` |
| `skills/` | `~/.claude.json` 整文件 |
| `mcp/user-servers.json` | 会话记录、缓存、telemetry |
| `CLAUDE.md`、`.env.example` | |

---

## 常见问题

### API 连接失败 / 模型不可用？

- 确认 `.env` 中 `ANTHROPIC_AUTH_TOKEN` 已填写
- 确认已运行 `bootstrap.sh`
- 检查 `settings.json` 中 `ANTHROPIC_BASE_URL` 是否正确
- 使用网关支持的模型名，例如 `claude-sonnet-4-6`（不要用 `sonnet` 别名）
- 测试：`claude -p "hi" --model claude-sonnet-4-6`

### 还需要 `claude login` 吗？

使用 Right Code 第三方 API 时**不需要**。若改回 Anthropic 官方订阅，删除或注释 `settings.json` 中的 `ANTHROPIC_BASE_URL`，然后运行 `claude login`。

### Plugin 安装失败？

- 检查 `marketplaces.lock` 是否已添加对应商店
- 更新：`claude plugin marketplace update <name>`
- 官方商店 `claude-plugins-official` 默认内置

### Skill 不生效？

- 确认 `skills/<name>/SKILL.md` 存在
- 检查链接：`ls -la ~/.claude/skills/`
- 重新运行 `bootstrap.sh`，新开 Claude Code 会话

### MCP 不生效？

- 确认 `mcp/user-servers.json` 非空
- 确认 `.env` 中对应密钥已配置
- 运行 `claude mcp get <name>` 检查状态
- 重新运行 `bootstrap.sh`

### 为什么不把 plugin 缓存 / ~/.claude.json 放进 Git？

- **Plugin 缓存**：可重新下载的安装产物，体积大且会变
- **~/.claude.json**：混合 OAuth 与 MCP 运行时状态，整文件入库有泄露风险；本仓库用 `mcp/user-servers.json` 模板 + bootstrap 合并

---

## 参考链接

- [Right Code - Claude Code 配置文档](https://docs.right.codes/docs/rc_cli_config/claudecode)
- [Claude Code 环境变量](https://code.claude.com/docs/en/env-vars)
- [Claude Code Plugin 文档](https://code.claude.com/docs/en/discover-plugins)
