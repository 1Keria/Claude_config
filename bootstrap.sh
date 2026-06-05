#!/usr/bin/env bash
# 新机器一键恢复 Claude Code 个人配置
# 用法: ~/claude-setup/bootstrap.sh

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
CLAUDE_JSON="${HOME}/.claude.json"

log()  { echo "[claude-setup] $*"; }
warn() { echo "[claude-setup] WARNING: $*" >&2; }
die()  { echo "[claude-setup] ERROR: $*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "缺少命令: $1"
}

read_lock_file() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  grep -v '^\s*#' "$file" | grep -v '^\s*$' || true
}

# --- 前置检查 ---

require_cmd claude
require_cmd jq

if ! command -v envsubst >/dev/null 2>&1; then
  warn "未找到 envsubst，MCP 配置中的 \${VAR} 将不会被展开（可安装 gettext 包）"
fi

mkdir -p "${CLAUDE_DIR}/skills"

# 加载环境变量（MCP 密钥）
if [[ -f "${REPO}/.env" ]]; then
  log "加载 ${REPO}/.env"
  set -a
  # shellcheck disable=SC1091
  source "${REPO}/.env"
  set +a
elif [[ -f "${HOME}/.env" ]]; then
  log "加载 ${HOME}/.env"
  set -a
  # shellcheck disable=SC1091
  source "${HOME}/.env"
  set +a
else
  warn "未找到 .env 文件。如有 MCP 需要密钥，请: cp ${REPO}/.env.example ${REPO}/.env"
fi

# --- 1. 添加 Marketplace ---

log "添加 Marketplace..."
while IFS= read -r source; do
  [[ -z "$source" ]] && continue
  log "  marketplace add: $source"
  if ! claude plugin marketplace add "$source" 2>/dev/null; then
    warn "  跳过或已存在: $source"
  fi
done < <(read_lock_file "${REPO}/marketplaces.lock")

# --- 2. 安装 Plugin ---

log "安装 Plugin..."
while IFS= read -r plugin; do
  [[ -z "$plugin" ]] && continue
  log "  plugin install: $plugin"
  if ! claude plugin install "$plugin" 2>/dev/null; then
    warn "  安装失败或已安装: $plugin"
  fi
done < <(read_lock_file "${REPO}/plugins.lock")

# --- 3. 链接独立 Skills ---

log "链接独立 Skills..."
skill_count=0
for skill_dir in "${REPO}"/skills/*/; do
  [[ -d "$skill_dir" ]] || continue
  name="$(basename "$skill_dir")"
  [[ "$name" == "README.md" ]] && continue
  if [[ ! -f "${skill_dir}/SKILL.md" ]]; then
    warn "  跳过 ${name}：缺少 SKILL.md"
    continue
  fi
  ln -sfn "$skill_dir" "${CLAUDE_DIR}/skills/${name}"
  log "  skill linked: ${name}"
  skill_count=$((skill_count + 1))
done
log "  共链接 ${skill_count} 个 skill"

# --- 4. 合并独立 MCP 配置 ---

MCP_FILE="${REPO}/mcp/user-servers.json"
if [[ -f "$MCP_FILE" ]]; then
  server_count="$(jq '.mcpServers | length' "$MCP_FILE" 2>/dev/null || echo 0)"
  if [[ "$server_count" -gt 0 ]]; then
    log "合并 MCP 配置（${server_count} 个服务器）..."

    # 确保 ~/.claude.json 存在
    if [[ ! -f "$CLAUDE_JSON" ]]; then
      echo '{}' > "$CLAUDE_JSON"
    fi

    # 展开环境变量
    resolved_mcp="$(mktemp)"
    if command -v envsubst >/dev/null 2>&1; then
      envsubst < "$MCP_FILE" > "$resolved_mcp"
    else
      cp "$MCP_FILE" "$resolved_mcp"
    fi

    # 只合并 mcpServers，保留 OAuth 等其它字段
    tmp_json="$(mktemp)"
    jq --slurpfile mcp "$resolved_mcp" \
      '.mcpServers = ((.mcpServers // {}) * ($mcp[0].mcpServers // {}))' \
      "$CLAUDE_JSON" > "$tmp_json"
    mv "$tmp_json" "$CLAUDE_JSON"
    rm -f "$resolved_mcp"
    log "  MCP 已写入 ${CLAUDE_JSON}"
  else
    log "MCP 配置为空，跳过（参考 mcp/user-servers.example.json）"
  fi
fi

# --- 5. 同步个人设置 ---

if [[ -f "${REPO}/settings.json" ]]; then
  log "同步 settings.json -> ${CLAUDE_DIR}/settings.json"
  cp "${REPO}/settings.json" "${CLAUDE_DIR}/settings.json"
fi

if [[ -f "${REPO}/CLAUDE.md" ]]; then
  log "同步 CLAUDE.md -> ${CLAUDE_DIR}/CLAUDE.md"
  cp "${REPO}/CLAUDE.md" "${CLAUDE_DIR}/CLAUDE.md"
fi

# --- 完成 ---

echo ""
log "恢复完成！"
echo ""
echo "  下一步："
echo "    1. 若尚未登录:  claude login"
echo "    2. 验证插件:     claude plugin list"
echo "    3. 验证 MCP:     claude mcp get <name>"
echo "    4. 启动 Claude:  claude"
echo ""
