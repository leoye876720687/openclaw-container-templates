# openclaw-container-templates

OpenClaw 容器智能体模板化生成技能。通过预定义模板快速创建专用容器智能体，支持数据分析、编码开发、通用任务等多种场景。

## 🚀 功能特性

- ✅ **模板化创建** - JSON 模板定义技能组合和工作空间
- ✅ **自动配置** - 自动分配端口、实例号、生成配置
- ✅ **技能预加载** - 根据模板自动复制所需技能
- ✅ **一键管理** - 自动生成启动/停止脚本
- ✅ **可扩展** - 轻松添加自定义模板

## 📋 内置模板

| 模板 | 用途 | 预加载技能 |
|------|------|-----------|
| `data-expert` | 数据分析专用 | data-model-designer, excel-xlsx, statistics, feishu-bitable 等 |
| `coding` | 代码开发专用 | coding-agent, gh-issues, github, skill-creator |
| `general` | 通用目的 | 无（按需使用） |

## 🔧 使用方法

### 查看可用模板

```bash
~/.openclaw/workspace/skills/openclaw-container-templates/generate-container.sh --list
```

### 创建容器

```bash
# 使用模板创建（自动分配实例号）
~/.openclaw/workspace/skills/openclaw-container-templates/generate-container.sh data-expert

# 指定实例号
~/.openclaw/workspace/skills/openclaw-container-templates/generate-container.sh data-expert 6

# 创建通用容器
~/.openclaw/workspace/skills/openclaw-container-templates/generate-container.sh general
```

### 查看模板内容

```bash
~/.openclaw/workspace/skills/openclaw-container-templates/generate-container.sh --show data-expert
```

### 管理容器

```bash
# 查看状态
docker ps --filter "name=openclaw-agent"

# 查看日志
docker logs openclaw-agent-5

# 进入容器
docker exec -it openclaw-agent-5 bash

# 重启容器
docker restart openclaw-agent-5
```

## 📁 目录结构

```
openclaw-container-templates/
├── SKILL.md                          # 技能说明
├── generate-container.sh             # 主生成器脚本
├── container-templates/              # 模板目录
│   ├── data-expert.json              # 数据分析模板
│   ├── coding.json                   # 编码开发模板
│   └── general.json                  # 通用模板
└── README.md                         # 详细文档
```

## 🛠️ 创建自定义模板

在 `container-templates/` 目录下创建 JSON 文件：

```json
{
  "template": {
    "id": "my-custom",
    "name": "My Custom Agent",
    "description": "自定义用途",
    "version": "1.0.0"
  },
  "container": {
    "namePrefix": "openclaw-agent",
    "image": "docker-openclaw-openclaw:latest",
    "internalPort": 18789,
    "healthCheck": {
      "cmd": "curl -f http://127.0.0.1:18789/ || exit 1",
      "interval": "30s",
      "timeout": "10s",
      "retries": 3
    },
    "restart": "unless-stopped"
  },
  "skills": ["skill-1", "skill-2"],
  "workspace": {
    "directories": ["input", "output", "memory"]
  },
  "config": {
    "bind": "loopback",
    "authMode": "token",
    "nativeSkills": "auto"
  }
}
```

## 📊 输出位置

生成的容器配置保存在：

```
~/.openclaw/containers/openclaw-agent-N/
├── openclaw.json          # 容器配置
├── start.sh               # 启动脚本
├── stop.sh                # 停止脚本
├── skills/                # 预加载技能
└── workspace/             # 工作空间
```

## 🔐 环境变量

- `ALIBABA_CLOUD_API_KEY` - 阿里云 API Key（可选，默认使用系统配置）
- `OPENCLAW_HOME` - OpenClaw 主目录（默认 `~/.openclaw`）

## 📝 示例

### 批量创建数据分析容器

```bash
for i in 1 2 3; do
  ~/.openclaw/workspace/skills/openclaw-container-templates/generate-container.sh data-expert $i
done
```

### 查看容器端口映射

```bash
docker ps --filter "name=openclaw-agent" --format "table {{.Names}}\t{{.Ports}}"
```

## 🐛 故障排查

### 容器启动失败

```bash
# 查看日志
docker logs openclaw-agent-X

# 检查配置
docker exec openclaw-agent-X cat ~/.openclaw/.openclaw/openclaw.json

# 手动测试 Gateway
docker exec openclaw-agent-X curl http://127.0.0.1:18789/
```

### 技能未加载

```bash
# 检查技能目录
docker exec openclaw-agent-X ls -la /app/skills/
```

## 📚 相关资源

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [Docker 部署技能](https://github.com/openclaw/openclaw/tree/main/skills/openclaw-docker-deploy)
- [ClawHub 技能市场](https://clawhub.com)

## 📄 许可证

MIT License

## 👥 作者

Created for OpenClaw community.
