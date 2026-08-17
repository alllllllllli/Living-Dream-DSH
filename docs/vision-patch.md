# 发图自动识别改造教程

让 DSH 桌面版发图时自动调用 GLM-4V-Flash 识别，生成文字描述。

## 原理

DSH 桌面版的 `dsh-host-apiproxy` 模块负责处理图片附件。通过修改 `describeImagesLocally` 函数，让它调用外部视觉 API 而不是默认的处理方式。

## 改造流程

### 1. 备份原文件

```powershell
$originalFile = "D:\ToolsDeepSeek-Harness-Desktop\resources\runtime\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js"
$backupFile = "G:\vision-files\dsh-host-apiproxy-index.js.bak"

Copy-Item $originalFile $backupFile
Write-Host "已备份到 $backupFile"
```

### 2. 准备视觉 API 配置

创建 `G:\vision-files\dsh_vision_config.json`：

```json
{
  "zhipu": {
    "apiKey": "your-zhipu-api-key",
    "model": "glm-4v-flash",
    "baseURL": "https://open.bigmodel.cn/api/paas/v4/chat/completions"
  }
}
```

### 3. 修改 index.js

在 `index.js` 的 911 行附近找到 `describeImagesLocally` 函数，替换为以下代码：

```javascript
async function describeImagesLocally(imagePaths) {
  const configPath = 'G:\\vision-files\\dsh_vision_config.json';
  const outputDir = '.dsh-image-desc';
  
  // 确保输出目录存在
  const fs = require('fs');
  const path = require('path');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }
  
  // 读取配置
  let config;
  try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
  } catch (e) {
    console.error('Failed to read vision config:', e.message);
    return imagePaths; // 回退到原始行为
  }
  
  const results = [];
  
  for (const imagePath of imagePaths) {
    try {
      // 读取图片并转 base64
      const imageBuffer = fs.readFileSync(imagePath);
      const base64 = imageBuffer.toString('base64');
      const ext = path.extname(imagePath).toLowerCase();
      const mimeType = ext === '.png' ? 'image/png' : 
                       ext === '.gif' ? 'image/gif' : 
                       ext === '.webp' ? 'image/webp' : 'image/jpeg';
      
      // 调用 GLM-4V-Flash
      const response = await fetch(config.zhipu.baseURL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${config.zhipu.apiKey}`
        },
        body: JSON.stringify({
          model: config.zhipu.model,
          messages: [{
            role: 'user',
            content: [
              { type: 'text', text: '请详细描述这张图片的内容，包括文字、布局、颜色等信息。' },
              { type: 'image_url', image_url: { url: `data:${mimeType};base64,${base64}` } }
            ]
          }]
        })
      });
      
      const data = await response.json();
      const description = data.choices?.[0]?.message?.content || '无法识别';
      
      // 保存描述到文件
      const descFile = path.join(outputDir, path.basename(imagePath, ext) + '.txt');
      fs.writeFileSync(descFile, description, 'utf-8');
      
      // 返回文件指针而不是图片
      results.push(descFile);
    } catch (e) {
      console.error(`Failed to describe ${imagePath}:`, e.message);
      results.push(imagePath); // 失败时保留原图
    }
  }
  
  return results;
}
```

### 4. 修改单图大小限制

在 `index.js` 中找到 `attachment-local` 相关代码，将 10MB 限制改为 50MB：

```javascript
// 找到类似代码
const MAX_IMAGE_SIZE = 50 * 1024 * 1024; // 50MB
```

### 5. 重启 DSH 桌面版

```powershell
# 关闭 DSH
Get-Process -Name "DeepSeek Harness*" | Stop-Process -Force

# 重新启动
Start-Process "D:\ToolsDeepSeek-Harness-Desktop\DeepSeek Harness 桌面版.exe"
```

## 使用效果

1. 在 DSH 中发送图片
2. 自动调用 GLM-4V-Flash 识别
3. 生成描述文件 `.dsh-image-desc/xxx.txt`
4. 消息中只保留文件指针，不传原图

## 注意事项

- ⚠️ DSH 升级会覆盖此补丁，需重打
- 仅桌面版生效，Dev 版（3080 端口）无此逻辑
- GLM-4V-Flash 免费额度有限，大量使用需付费
- 备份文件在 `G:\vision-files\dsh-host-apiproxy-index.js.bak`

## 回滚

```powershell
$backupFile = "G:\vision-files\dsh-host-apiproxy-index.js.bak"
$targetFile = "D:\ToolsDeepSeek-Harness-Desktop\resources\runtime\node_modules\@deepseek-ai\dsh-host-apiproxy\lib\index.js"

Copy-Item $backupFile $targetFile
Write-Host "已回滚到原版"
```
