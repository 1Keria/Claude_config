# 独立 Skills 目录

将**不在 plugin 内**的第三方 skill 放在此目录，每个 skill 一个子文件夹：

```
skills/
└── author-skill-name/
    ├── SKILL.md          # 必需
    ├── reference.md      # 可选
    └── scripts/          # 可选
```

`bootstrap.sh` 会自动将此处的内容链接到 `~/.claude/skills/`。

## 添加新 skill

```bash
# 方式 1：使用辅助脚本（推荐）
~/claude-setup/scripts/add-skill.sh author-skill-name /path/to/source-dir

# 方式 2：手动复制
mkdir -p ~/claude-setup/skills/my-skill
cp /path/to/SKILL.md ~/claude-setup/skills/my-skill/
ln -sfn ~/claude-setup/skills/my-skill ~/.claude/skills/my-skill

# 然后提交到 Git
cd ~/claude-setup && git add skills/my-skill && git commit -m "add skill: my-skill"
```
