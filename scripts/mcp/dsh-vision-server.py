"""dsh-vision MCP server — image analysis via local Ollama vision models.

Tools:
  describe_image — analyze an image and return a text description

Requires: Ollama running locally with a vision model (e.g. qwen2.5vl).
Default endpoint: http://localhost:11434
"""

import base64
import json
import os
import sys
from pathlib import Path
from urllib.request import Request, urlopen
from urllib.error import URLError

from mcp.server.fastmcp import FastMCP

mcp = FastMCP("dsh-vision")

OLLAMA_URL = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
VISION_MODEL = os.environ.get("VISION_MODEL", "qwen2.5vl:latest")


def _call_ollama(image_b64: str, prompt: str) -> str:
    """Send image + prompt to Ollama /api/chat and return the response text."""
    payload = json.dumps({
        "model": VISION_MODEL,
        "messages": [{"role": "user", "content": prompt, "images": [image_b64]}],
        "stream": False,
    }).encode()
    req = Request(
        f"{OLLAMA_URL}/api/chat",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(req, timeout=120) as resp:
            data = json.loads(resp.read())
        return data.get("message", {}).get("content", "(empty response)")
    except URLError as e:
        return f"Error connecting to Ollama: {e}"
    except Exception as e:
        return f"Error: {e}"


@mcp.tool()
def describe_image(image_path: str, prompt: str = "请详细描述这张图片的内容，包括可见的文字、布局、主要对象等。") -> str:
    """Analyze a local image and return a text description.

    Args:
        image_path: Absolute path to the image file (PNG/JPEG/WebP/GIF).
        prompt: Custom instruction for the vision model (default: detailed Chinese description).

    Returns:
        Text description of the image.
    """
    path = Path(image_path)
    if not path.exists():
        return f"Error: file not found: {image_path}"
    if not path.is_file():
        return f"Error: not a file: {image_path}"

    # Read and base64-encode the image
    try:
        image_bytes = path.read_bytes()
        image_b64 = base64.b64encode(image_bytes).decode()
    except Exception as e:
        return f"Error reading file: {e}"

    return _call_ollama(image_b64, prompt)


if __name__ == "__main__":
    mcp.run(transport="stdio")
