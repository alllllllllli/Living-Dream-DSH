"""dsh-markitdown MCP server — convert documents to Markdown.

Tools:
  convert_to_markdown — convert a file (PDF/Word/Excel/PPT/EPUB/HTML/etc.) to Markdown

Requires: pip install markitdown
"""

import json
import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("dsh-markitdown")


def _convert(file_path: str) -> str:
    """Convert a file to markdown using markitdown."""
    try:
        from markitdown import MarkItDown
    except ImportError:
        return "Error: markitdown not installed. Run: pip install markitdown"

    path = Path(file_path)
    if not path.exists():
        return f"Error: file not found: {file_path}"
    if not path.is_file():
        return f"Error: not a file: {file_path}"

    try:
        md = MarkItDown()
        result = md.convert(str(path))
        return result.text_content if hasattr(result, "text_content") else str(result)
    except Exception as e:
        return f"Error converting file: {e}"


@mcp.tool()
def convert_to_markdown(file_path: str) -> str:
    """Convert a local file to Markdown text.

    Supports: PDF, Word (.docx/.doc), Excel (.xlsx/.xls/.csv), PowerPoint (.pptx),
    EPUB, HTML, plain text, JSON, XML, ZIP, and more.

    Args:
        file_path: Absolute path to the file.

    Returns:
        Markdown text content.
    """
    result = _convert(file_path)
    # Truncate very large outputs to avoid MCP message size limits
    if len(result) > 100_000:
        result = result[:100_000] + "\n\n[truncated — output exceeded 100KB]"
    return result


if __name__ == "__main__":
    mcp.run(transport="stdio")
