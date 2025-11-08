#!/bin/bash

# 将 EPUB XHTML 文件转换为 Markdown 格式的脚本
# 作者: 自动生成
# 用途: 为翻译工作准备 Markdown 格式的文本

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}EPUB XHTML 到 Markdown 转换工具${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 检查 pandoc 是否已安装
if ! command -v pandoc &> /dev/null; then
    echo -e "${YELLOW}未检测到 pandoc，正在安装...${NC}"
    sudo apt-get update
    sudo apt-get install -y pandoc
    echo -e "${GREEN}✓ pandoc 安装完成${NC}"
else
    PANDOC_VERSION=$(pandoc --version | head -n 1)
    echo -e "${GREEN}✓ 检测到 $PANDOC_VERSION${NC}"
fi

echo ""

# 定义目录
XHTML_DIR="EPUB/text"
MARKDOWN_DIR="EPUB/markdown"
MEDIA_DIR="EPUB/media"

# 创建 markdown 目录（如果不存在）
if [ ! -d "$MARKDOWN_DIR" ]; then
    mkdir -p "$MARKDOWN_DIR"
    echo -e "${GREEN}✓ 创建目录: $MARKDOWN_DIR${NC}"
else
    echo -e "${YELLOW}目录已存在: $MARKDOWN_DIR${NC}"
fi

echo ""
echo -e "${GREEN}开始转换 XHTML 文件...${NC}"
echo ""

# 计数器
total_files=0
success_count=0
error_count=0

# 遍历所有 .xhtml 文件
for xhtml_file in "$XHTML_DIR"/*.xhtml; do
    if [ -f "$xhtml_file" ]; then
        total_files=$((total_files + 1))
        
        # 获取文件名（不含路径和扩展名）
        filename=$(basename "$xhtml_file" .xhtml)
        
        # 输出 markdown 文件路径
        markdown_file="$MARKDOWN_DIR/${filename}.md"
        
        echo -e "转换: ${YELLOW}$filename.xhtml${NC} → ${GREEN}$filename.md${NC}"
        
        # 使用 pandoc 进行转换
        # 参数说明:
        # -f html: 从 HTML/XHTML 格式读取
        # -t markdown: 输出为 Markdown 格式
        # --wrap=none: 不自动换行，保持原始段落格式
        # --extract-media=.: 提取媒体文件（图片等）
        # -o: 输出文件
        
        if pandoc -f html -t markdown \
            --wrap=none \
            --markdown-headings=atx \
            "$xhtml_file" -o "$markdown_file"; then
            
            success_count=$((success_count + 1))
            echo -e "${GREEN}  ✓ 转换成功${NC}"
        else
            error_count=$((error_count + 1))
            echo -e "${RED}  ✗ 转换失败${NC}"
        fi
        echo ""
    fi
done

# 输出统计信息
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}转换完成！${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "总文件数: $total_files"
echo -e "${GREEN}成功: $success_count${NC}"
if [ $error_count -gt 0 ]; then
    echo -e "${RED}失败: $error_count${NC}"
fi
echo ""
echo -e "Markdown 文件已保存到: ${GREEN}$MARKDOWN_DIR${NC}"
echo -e "图片引用路径已自动调整为相对路径: ${GREEN}../media/${NC}"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo -e "1. 接下来可以对 Markdown 文件进行翻译"
echo -e "2. 翻译完成后，可以使用 pandoc 将 Markdown 转换回 XHTML"
echo -e "3. 图片路径已保留，指向 ../media/ 目录"
echo ""
