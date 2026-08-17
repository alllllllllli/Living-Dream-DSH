"""
OS-Copilot MCP Server — minimal wrapper exposing code execution as MCP tools.
ponytail: Reuses OS-Copilot's SubprocessEnv for code execution, nothing else.
No LLM planning (DSH already has that), no heavy dependencies.
"""

import subprocess
import sys
import os

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("os-copilot", instructions="Execute Python code and shell commands via OS-Copilot's environment.")

# --- Minimal subprocess execution (inspired by SubprocessEnv but stripped down) ---

def _run_code(cmd: list[str], code: str, timeout: int = 30) -> dict:
    """Run code in a subprocess, return stdout/stderr/exit_code."""
    env = os.environ.copy()
    env["PYTHONIOENCODING"] = "utf-8"
    try:
        result = subprocess.run(
            cmd,
            input=code,
            capture_output=True,
            text=True,
            timeout=timeout,
            env=env,
            encoding="utf-8",
            errors="replace",
        )
        return {
            "stdout": result.stdout[-4000:] if result.stdout else "",
            "stderr": result.stderr[-2000:] if result.stderr else "",
            "exit_code": result.returncode,
        }
    except subprocess.TimeoutExpired:
        return {"stdout": "", "stderr": f"Timeout after {timeout}s", "exit_code": -1}
    except Exception as e:
        return {"stdout": "", "stderr": str(e), "exit_code": -1}


@mcp.tool()
def execute_python(code: str, timeout: int = 30) -> str:
    """Execute Python code in a subprocess and return output.
    
    Args:
        code: Python code to execute
        timeout: Max seconds to wait (default 30)
    
    Returns:
        Combined stdout/stderr and exit code
    """
    r = _run_code([sys.executable, "-u", "-c", code], "", timeout)
    parts = []
    if r["stdout"]:
        parts.append(f"stdout:\n{r['stdout']}")
    if r["stderr"]:
        parts.append(f"stderr:\n{r['stderr']}")
    parts.append(f"exit_code: {r['exit_code']}")
    return "\n\n".join(parts)


@mcp.tool()
def execute_command(command: str, timeout: int = 30) -> str:
    """Execute a shell command and return output.
    
    Args:
        command: Shell command to run
        timeout: Max seconds to wait (default 30)
    
    Returns:
        Combined stdout/stderr and exit code
    """
    shell = ["cmd", "/c"] if sys.platform == "win32" else ["sh", "-c"]
    r = _run_code(shell + [command], "", timeout)
    parts = []
    if r["stdout"]:
        parts.append(f"stdout:\n{r['stdout']}")
    if r["stderr"]:
        parts.append(f"stderr:\n{r['stderr']}")
    parts.append(f"exit_code: {r['exit_code']}")
    return "\n\n".join(parts)


@mcp.tool()
def execute_python_file(file_path: str, args: str = "", timeout: int = 60) -> str:
    """Execute a Python file and return output.
    
    Args:
        file_path: Path to the .py file
        args: Optional command-line arguments
        timeout: Max seconds to wait (default 60)
    
    Returns:
        Combined stdout/stderr and exit code
    """
    cmd = [sys.executable, "-u", file_path]
    if args:
        cmd.extend(args.split())
    r = _run_code(cmd, "", timeout)
    parts = []
    if r["stdout"]:
        parts.append(f"stdout:\n{r['stdout']}")
    if r["stderr"]:
        parts.append(f"stderr:\n{r['stderr']}")
    parts.append(f"exit_code: {r['exit_code']}")
    return "\n\n".join(parts)


@mcp.tool()
def read_file(file_path: str, max_lines: int = 200) -> str:
    """Read a text file and return its contents.
    
    Args:
        file_path: Path to the file
        max_lines: Maximum lines to read (default 200)
    
    Returns:
        File contents or error message
    """
    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            lines = []
            for i, line in enumerate(f):
                if i >= max_lines:
                    lines.append(f"\n... truncated at {max_lines} lines")
                    break
                lines.append(line)
            return "".join(lines)
    except Exception as e:
        return f"Error reading file: {e}"


@mcp.tool()
def list_directory(path: str = ".", show_hidden: bool = False) -> str:
    """List files and directories.
    
    Args:
        path: Directory path (default: current directory)
        show_hidden: Include hidden files (default: false)
    
    Returns:
        Directory listing
    """
    try:
        entries = []
        for entry in os.listdir(path):
            if not show_hidden and entry.startswith("."):
                continue
            full = os.path.join(path, entry)
            kind = "d" if os.path.isdir(full) else "f"
            size = os.path.getsize(full) if os.path.isfile(full) else 0
            entries.append(f"[{kind}] {entry} ({size} bytes)")
        return "\n".join(entries) if entries else "(empty directory)"
    except Exception as e:
        return f"Error: {e}"


if __name__ == "__main__":
    mcp.run(transport="stdio")
