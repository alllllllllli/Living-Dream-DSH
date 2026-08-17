# 配置文件说明

本目录包含 DSH Ultra Config 的所有配置模板。

## 文件列表

| 文件 | 说明 | 目标位置 |
|------|------|----------|
| `cordis.patch.yml.template` | MCP 服务器配置 | `~/.dsh/profiles/web/cordis.patch.yml` |
| `package.json.template` | 插件清单 | `~/.dsh/profiles/web/package.json` |
| `settings.yaml.template` | 全局设置 | `~/.dsh/settings.yaml` |
| `.credentials.yaml.template` | API Key | `~/.dsh/.credentials.yaml` |
| `AGENTS.md` | AI 指令文件 | `~/.dsh/AGENTS.md` |

## 安装步骤

### 1. 复制配置文件

```powershell
# 复制到 DSH 目录
Copy-Item configs\cordis.patch.yml.template $env:USERPROFILE\.dsh\profiles\web\cordis.patch.yml
Copy-Item configs\package.json.template $env:USERPROFILE\.dsh\profiles\web\package.json
Copy-Item configs\settings.yaml.template $env:USERPROFILE\.dsh\settings.yaml
Copy-Item configs\AGENTS.md $env:USERPROFILE\.dsh\AGENTS.md
```

### 2. 编辑配置文件

#### cordis.patch.yml

修改 MCP 服务器的路径：

```yaml
command: python  # 改为你的 Python 路径
args:
  - G:/path/to/server.py  # 改为你的 MCP 服务器路径
```

#### settings.yaml

修改模型提供商配置：

```yaml
llm-pi-ai:
  providers:
    my-provider:
      apiKeyEnv: MY_API_KEY  # 改为你的环境变量名
      baseURL: https://api.example.com/v1  # 改为你的 API 端点
```

#### .credentials.yaml

填入你的 API Key：

```yaml
MY_API_KEY: sk-xxxxxxxxxxxx  # 改为你的实际 API Key
```

### 3. 安装插件

```powershell
cd $env:USERPROFILE\.dsh\profiles\web
pnpm install
```

### 4. 重启 DSH 桌面版

## 配置详解

### MCP 服务器配置

每个 MCP 服务器配置包含以下字段：

```yaml
- insert:
    - id: mcp-dsh-example          # 唯一标识
      name: '@deepseek-ai/dsh-mcp-client'  # 插件名称
      config:
        transport: stdio            # 传输方式
        serverName: dsh-example     # 服务器名称
        command: python             # 命令（Python 或 Node.js）
        args:                       # 参数
          - path/to/server.py
        env: {}                     # 环境变量
        cwd: ''                     # 工作目录
        toolCallTimeoutMs: 120000   # 超时时间（毫秒）
        failOnStartupError: false   # 启动失败是否中断
```

### 模型提供商配置

```yaml
llm-pi-ai:
  providers:
    provider-name:
      apiKeyEnv: ENV_VAR_NAME      # API Key 环境变量
      api: openai-completions      # API 类型
      baseURL: https://api.example.com/v1  # 端点
      models:
        - id: model-id             # 模型 ID
          name: Model Name         # 显示名称
          contextWindow: 1000000   # 上下文窗口大小
          maxTokens: 384000        # 最大 token 数
```

### 权限配置

```yaml
permission:
  defaultPreset: danger-full-access  # 可选值：
                                     # - read-only: 只读
                                     # - standard: 标准权限
                                     # - danger-full-access: 完全访问
```

## 环境变量

在 `.credentials.yaml` 中配置以下环境变量：

| 变量名 | 说明 | 获取方式 |
|--------|------|----------|
| `DEEPSEEK_API_KEY` | DeepSeek 官方 API | platform.deepseek.com |
| `AMD_RADEON_API_KEY` | AMD Radeon Cloud | developer.amd.com.cn/radeon |
| `OPENCODE_GO_API_KEY` | OpenCode Go | opencode.ai |
| `VISION_API_KEY` | 智谱 AI | open.bigmodel.cn |

## 故障排查

### 配置文件不生效

1. 检查文件路径是否正确
2. 重启 DSH 桌面版
3. 检查 YAML 语法是否正确

### MCP 服务器启动失败

1. 检查 command 和 args 路径是否正确
2. 检查 Python/Node.js 是否安装
3. 检查依赖是否安装

### API Key 无效

1. 检查 `.credentials.yaml` 中的 Key 是否正确
2. 检查 Key 是否过期
3. 检查网络连接
