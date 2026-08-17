# OS-Copilot MCP Server

Minimal MCP wrapper exposing code execution as DSH tools.

## Tools

- `execute_python(code, timeout)` — Run Python code in a subprocess
- `execute_command(command, timeout)` — Run shell commands
- `execute_python_file(file_path, args, timeout)` — Run a .py file
- `read_file(file_path, max_lines)` — Read text files
- `list_directory(path, show_hidden)` — List directory contents

## DSH Config

Add to `~/.dsh/profiles/web/cordis.patch.yml`:

```yaml
- insert:
    - id: mcp-os-copilot
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        transport: stdio
        serverName: os-copilot
        command: python  # or full path to python.exe
        args:
          - D:/workspace/OS-Copilot/os-copilot-mcp/server.py
        env: {}
        cwd: ''
        toolCallTimeoutMs: 60000
        failOnStartupError: false
```

## Test

```bash
python test_tools.py
```
