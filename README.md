# OpenClaw 容器智能体模板化系统

## 📖 概述

通过模板化配置快速创建专用容器智能体，支持：
- ✅ 预定义技能组合
- ✅ 自动端口分配
- ✅ 一键创建/管理
- ✅ 配置版本控制

---

## 🚀 快速开始

### 查看可用模板

```bash
~/.openclaw/containers/generate-container.sh --list
```

### 创建容器

```bash
# 使用模板创建（自动分配实例号）
~/.openclaw/containers/generate-container.sh data-expert

# 指定实例号
~/.openclaw/containers/generate-container.sh data-expert 6

# 创建通用容器
~/.openclaw/containers/generate-container.sh general
```

### 查看模板内容

```bash
~/.openclaw/containers/generate-container.sh --show data-expert
```

---

## 📋 内置模板

### 1. data-expert - 数据专家

**用途**: 数据分析与处理

**预加载技能**:
- `data-model-designer` - 数据模型设计
- `data-reconciliation-exceptions` - 数据对账异常
- `excel-xlsx` - Excel 文件处理
- `statistics` - 统计分析
- `feishu-bitable` - 飞书多维表格
- `prompt-optimizer` - 提示词优化

**工作空间目录**: `input/`, `output/`, `scripts/`, `memory/`, `temp/`

---

### 2. coding - 编码专家

**用途**: 代码开发与审查

**预加载技能**:
- `coding-agent` - 编码代理
- `gh-issues` - GitHub Issues
- `github` - GitHub 操作
- `skill-creator` - 技能创建

**工作空间目录**: `src/`, `tests/`, `output/`, `memory/`

---

### 3. general - 通用容器

**用途**: 通用任务处理

**预加载技能**: 无（按需添加）

**工作空间目录**: `input/`, `output/`, `memory/`

---

## 🛠️ 创建自定义模板

在 `~/.openclaw/containers/container-templates/` 下创建 JSON 文件：

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
  "skills": [
    "skill-1",
    "skill-2"
  ],
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

---

## 📁 目录结构

```
~/.openclaw/containers/
├── generate-container.sh          # 主生成器脚本
├── container-templates/           # 模板目录
│   ├── data-expert.json
│   ├── coding.json
│   └── general.json
├── openclaw-agent-1/              # 实例配置目录
│   ├── openclaw.json              # 容器配置
│   ├── start.sh                   # 启动脚本
│   ├── stop.sh                    # 停止脚本
│   ├── skills/                    # 预加载技能
│   └── workspace/                 # 工作空间
└── openclaw-agent-2/
    └── ...
```

---

## 🔧 管理命令

### 查看容器状态

```bash
docker ps --filter "name=openclaw-agent"
```

### 进入容器

```bash
docker exec -it openclaw-agent-5 bash
```

### 查看日志

```bash
docker logs openclaw-agent-5
docker logs -f openclaw-agent-5  # 实时跟踪
```

### 重启容器

```bash
docker restart openclaw-agent-5
```

### 停止并删除

```bash
~/.openclaw/containers/openclaw-agent-5/stop.sh
```

---

## 🎯 高级用法

### 批量创建

```bash
# 创建 3 个数据分析容器
for i in 1 2 3; do
  ~/.openclaw/containers/generate-container.sh data-expert $i
done
```

### 自定义 API Key

```bash
# 使用不同的模型提供商
export ALIBABA_CLOUD_API_KEY="sk-your-key"
~/.openclaw/containers/generate-container.sh data-expert
```

### 查看配置

```bash
# 查看容器配置
cat ~/.openclaw/containers/openclaw-agent-5/openclaw.json

# 查看预加载技能
ls ~/.openclaw/containers/openclaw-agent-5/skills/
```

---

## 📊 端口分配规则

- 起始端口：`18890`
- 自动检测已占用端口
- 依次分配下一个可用端口

当前容器端口映射：
| 容器 | 外部端口 | 内部端口 |
|------|---------|---------|
| agent-1 | 18891 | 18789 |
| agent-2 | 18892 | 18789 |
| agent-3 | 18893 | 18789 |
| agent-4 | 18894 | 18789 |
| agent-5 | 18895 | 18789 |

---

## 🔐 安全说明

- 每个容器生成独立的 Gateway Token
- 配置文件只读挂载到容器
- 技能目录只读挂载（防止容器内修改）
- 工作空间可写（保存处理结果）

---

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

# 检查权限
ls -la ~/.openclaw/containers/openclaw-agent-X/skills/
```

---

## 📝 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| 1.0.0 | 2026-03-30 | 初始版本，支持 data-expert/coding/general 模板 |

---

## 📚 相关文档

- [OpenClaw 官方文档](https://docs.openclaw.ai)
- [Docker 部署指南](~/.openclaw/workspace/skills/openclaw-docker-deploy/SKILL.md)
- [技能开发指南](~/.nvm/versions/node/v22.22.0/lib/node_modules/openclaw/skills/skill-creator/SKILL.md)
