#!/bin/bash
#
# OpenClaw 容器智能体模板化生成器
# 
# 用法：
#   ./generate-container.sh <template> [instance_number]
#   ./generate-container.sh data-expert 6
#   ./generate-container.sh coding
#   ./generate-container.sh --list
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/container-templates"
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# 显示帮助
show_help() {
    cat << EOF
🦞 OpenClaw 容器智能体生成器

用法:
  $0 <template> [instance_number]
  $0 --list
  $0 --show <template>

模板列表:
$(ls -1 "$TEMPLATES_DIR" 2>/dev/null | sed 's/\.json$//' | sed 's/^/  - /' || echo "  (无模板)")

示例:
  $0 data-expert 6    # 使用 data-expert 模板创建第 6 个实例
  $0 coding           # 使用 coding 模板创建下一个可用实例
  $0 --list           # 列出所有可用模板
  $0 --show general   # 显示 general 模板内容

EOF
}

# 列出模板
list_templates() {
    echo "📋 可用模板:"
    echo ""
    for template in "$TEMPLATES_DIR"/*.json; do
        if [ -f "$template" ]; then
            name=$(basename "$template" .json)
            desc=$(jq -r '.template.description // "无描述"' "$template" 2>/dev/null)
            printf "  %-15s %s\n" "$name" "$desc"
        fi
    done
    echo ""
}

# 显示模板内容
show_template() {
    local template_name="$1"
    local template_file="$TEMPLATES_DIR/${template_name}.json"
    
    if [ ! -f "$template_file" ]; then
        log_error "模板不存在：$template_name"
        exit 1
    fi
    
    echo "📄 模板内容：$template_name"
    echo ""
    cat "$template_file"
}

# 获取下一个可用实例号
get_next_instance_number() {
    local prefix="$1"
    local max=0
    
    for container in $(docker ps -a --format '{{.Names}}' | grep "^${prefix}-"); do
        num=$(echo "$container" | grep -oE '[0-9]+$' || echo "0")
        if [ "$num" -gt "$max" ]; then
            max=$num
        fi
    done
    
    echo $((max + 1))
}

# 获取下一个可用端口
get_next_port() {
    local start_port="$1"
    local port=$start_port
    
    while netstat -tlnp 2>/dev/null | grep -q ":$port " || ss -tlnp 2>/dev/null | grep -q ":$port "; do
        port=$((port + 1))
    done
    
    echo $port
}

# 生成随机 token
generate_token() {
    openssl rand -hex 20
}

# 主函数：创建容器
create_container() {
    local template_name="$1"
    local instance_num="$2"
    
    local template_file="$TEMPLATES_DIR/${template_name}.json"
    
    # 检查模板
    if [ ! -f "$template_file" ]; then
        log_error "模板不存在：$template_file"
        exit 1
    fi
    
    # 读取模板配置
    local container_name_prefix=$(jq -r '.container.namePrefix' "$template_file")
    local image=$(jq -r '.container.image' "$template_file")
    local internal_port=$(jq -r '.container.internalPort' "$template_file")
    local skills=$(jq -r '.skills[]' "$template_file" 2>/dev/null)
    local workspace_dirs=$(jq -r '.workspace.directories[]' "$template_file" 2>/dev/null)
    
    # 确定实例号
    if [ -z "$instance_num" ]; then
        instance_num=$(get_next_instance_number "$container_name_prefix")
    fi
    
    local container_name="${container_name_prefix}-${instance_num}"
    local external_port=$(get_next_port 18890)
    
    log_info "创建容器：$container_name"
    log_info "使用模板：$template_name"
    log_info "外部端口：$external_port -> $internal_port"
    
    # 创建目录结构
    local config_dir="$SCRIPT_DIR/${container_name}"
    local skills_dir="$config_dir/skills"
    local workspace_dir="$config_dir/workspace"
    
    log_info "创建目录：$config_dir"
    mkdir -p "$config_dir"
    mkdir -p "$skills_dir"
    mkdir -p "$workspace_dir"
    
    # 创建工作空间子目录
    for dir in $workspace_dirs; do
        mkdir -p "$workspace_dir/$dir"
    done
    
    # 复制技能
    if [ -n "$skills" ]; then
        log_info "复制技能..."
        local workspace_skills_dir="$OPENCLAW_HOME/workspace/skills"
        local feishu_skills_dir="$OPENCLAW_HOME/extensions/feishu-openclaw-plugin/skills"
        
        for skill in $skills; do
            if [ -d "$workspace_skills_dir/$skill" ]; then
                log_info "  复制：$skill"
                cp -r "$workspace_skills_dir/$skill" "$skills_dir/"
            elif [ -d "$feishu_skills_dir/$skill" ]; then
                log_info "  复制：$skill (feishu)"
                cp -r "$feishu_skills_dir/$skill" "$skills_dir/"
            else
                log_warn "  跳过：$skill (不存在)"
            fi
        done
    fi
    
    # 生成配置文件
    local gateway_token=$(generate_token)
    local aliyun_api_key="${ALIBABA_CLOUD_API_KEY:-sk-3b4d0ebb9dfc42839b18af33321921a2}"
    
    log_info "生成配置文件..."
    cat > "$config_dir/openclaw.json" << EOF
{
  "agents": {
    "defaults": {
      "compaction": { "mode": "safeguard" },
      "maxConcurrent": 4,
      "subagents": { "maxConcurrent": 8 },
      "models": { "aliyun-qwen/qwen3.5-plus": {} }
    }
  },
  "commands": {
    "native": "auto",
    "nativeSkills": "auto",
    "restart": true
  },
  "gateway": {
    "auth": {
      "mode": "token",
      "token": "${gateway_token}"
    },
    "bind": "loopback"
  },
  "meta": {
    "lastTouchedVersion": "2026.3.24",
    "lastTouchedAt": "$(date -u +%Y-%m-%dT%H:%M:%S.000Z)"
  },
  "models": {
    "providers": {
      "aliyun-qwen": {
        "baseUrl": "https://dashscope.aliyuncs.com/compatible-mode/v1",
        "apiKey": "${aliyun_api_key}",
        "api": "openai-completions",
        "models": [{
          "id": "qwen3.5-plus",
          "name": "qwen3.5-plus",
          "contextWindow": 131072,
          "maxTokens": 8192
        }]
      }
    }
  }
}
EOF
    
    # 创建技能索引
    cat > "$skills_dir/README.md" << EOF
# ${container_name} Skills

预加载技能列表：
$(ls -1 "$skills_dir" 2>/dev/null | grep -v README | sed 's/^/- /')

位置：/app/skills/
EOF
    
    # 创建管理脚本
    cat > "$config_dir/start.sh" << 'STARTSCRIPT'
#!/bin/bash
CONTAINER_NAME="{{CONTAINER_NAME}}"
EXTERNAL_PORT="{{EXTERNAL_PORT}}"
INTERNAL_PORT="{{INTERNAL_PORT}}"
IMAGE="{{IMAGE}}"
SKILLS_DIR="{{SKILLS_DIR}}"
WORKSPACE_DIR="{{WORKSPACE_DIR}}"
CONFIG_FILE="{{CONFIG_FILE}}"

if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "启动现有容器..."
    docker start $CONTAINER_NAME
else
    echo "创建新容器..."
    docker run -d \
      --name $CONTAINER_NAME \
      -p ${EXTERNAL_PORT}:${INTERNAL_PORT} \
      -v $SKILLS_DIR:/app/skills:ro \
      -v $WORKSPACE_DIR:/app/workspace \
      -v $CONFIG_FILE:/home/openclaw/.openclaw/.openclaw/openclaw.json:ro \
      --restart unless-stopped \
      --health-cmd="curl -f http://127.0.0.1:${INTERNAL_PORT}/ || exit 1" \
      --health-interval=30s \
      --health-timeout=10s \
      --health-retries=3 \
      $IMAGE
fi

echo ""
echo "✅ 容器已启动!"
echo "Dashboard: http://127.0.0.1:${EXTERNAL_PORT}/"
STARTSCRIPT

    cat > "$config_dir/stop.sh" << 'STOPSCRIPT'
#!/bin/bash
CONTAINER_NAME="{{CONTAINER_NAME}}"
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME
echo "✅ 容器已停止并删除"
STOPSCRIPT

    # 替换变量
    sed -i "s/{{CONTAINER_NAME}}/$container_name/g" "$config_dir/start.sh" "$config_dir/stop.sh"
    sed -i "s/{{EXTERNAL_PORT}}/$external_port/g" "$config_dir/start.sh"
    sed -i "s/{{INTERNAL_PORT}}/$internal_port/g" "$config_dir/start.sh"
    sed -i "s|{{IMAGE}}|$image|g" "$config_dir/start.sh"
    sed -i "s|{{SKILLS_DIR}}|$skills_dir|g" "$config_dir/start.sh"
    sed -i "s|{{WORKSPACE_DIR}}|$workspace_dir|g" "$config_dir/start.sh"
    sed -i "s|{{CONFIG_FILE}}|$config_dir/openclaw.json|g" "$config_dir/start.sh"
    
    chmod +x "$config_dir/start.sh" "$config_dir/stop.sh"
    
    # 创建容器
    log_info "创建 Docker 容器..."
    # 注意：不直接挂载 openclaw.json，避免权限问题
    # 容器启动后会自动生成默认配置，可通过 WebSocket API 修改
    docker run -d \
      --name "$container_name" \
      -p "${external_port}:${internal_port}" \
      -v "$skills_dir:/app/skills:ro" \
      -v "$workspace_dir:/app/workspace" \
      --restart unless-stopped \
      --health-cmd="curl -f http://127.0.0.1:${internal_port}/ || exit 1" \
      --health-interval=30s \
      --health-timeout=10s \
      --health-retries=3 \
      "$image"
    
    # 等待并验证
    log_info "等待容器启动..."
    sleep 10
    
    local status=$(docker inspect -f '{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")
    
    echo ""
    log_success "容器创建完成！"
    echo ""
    echo "┌─────────────────────────────────────────┐"
    echo "│ 📊 访问信息                              │"
    echo "├─────────────────────────────────────────┤"
    printf "│ Dashboard:  http://127.0.0.1:%-10s │\n" "$external_port"
    printf "│ WebSocket:  ws://127.0.0.1:%-11s │\n" "$external_port"
    echo "├─────────────────────────────────────────┤"
    printf "│ 容器名：%-28s │\n" "$container_name"
    printf "│ 状态：%-31s │\n" "$status"
    echo "├─────────────────────────────────────────┤"
    echo "│ 🔧 管理命令                              │"
    echo "├─────────────────────────────────────────┤"
    printf "│ 启动：%-38s │\n" "$config_dir/start.sh"
    printf "│ 停止：%-38s │\n" "$config_dir/stop.sh"
    printf "│ 日志：docker logs %-24s │\n" "$container_name"
    printf "│ 进入：docker exec -it %-20s bash │\n" "$container_name"
    echo "├─────────────────────────────────────────┤"
    printf "│ 📁 配置：%-36s │\n" "$config_dir"
    echo "└─────────────────────────────────────────┘"
    echo ""
}

# 主入口
case "${1:-}" in
    --list|-l)
        list_templates
        ;;
    --show|-s)
        if [ -z "${2:-}" ]; then
            log_error "请指定模板名"
            exit 1
        fi
        show_template "$2"
        ;;
    --help|-h)
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        create_container "$1" "${2:-}"
        ;;
esac
