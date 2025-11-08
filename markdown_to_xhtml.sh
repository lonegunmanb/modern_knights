#!/bin/bash

# 将中文 Markdown 文件转换回 XHTML 格式
# 用于重新生成 EPUB 电子书

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Markdown 转 XHTML 工具${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 检查 pandoc 是否已安装
if ! command -v pandoc &> /dev/null; then
    echo -e "${RED}错误: 未找到 pandoc${NC}"
    echo -e "${YELLOW}请先安装 pandoc${NC}"
    exit 1
fi

PANDOC_VERSION=$(pandoc --version | head -n 1)
echo -e "${GREEN}✓ 检测到 $PANDOC_VERSION${NC}"
echo ""

# 定义目录和文件
SOURCE_FILE="EPUB/markdown/ch001.md"
OUTPUT_DIR="EPUB/text-cn"
OUTPUT_FILE="$OUTPUT_DIR/ch001.xhtml"

# 检查源文件
if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "${RED}错误: 源文件不存在: $SOURCE_FILE${NC}"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

echo -e "源文件: ${CYAN}$SOURCE_FILE${NC}"
echo -e "输出文件: ${CYAN}$OUTPUT_FILE${NC}"
echo ""

# 获取源文件信息
source_size=$(stat -f%z "$SOURCE_FILE" 2>/dev/null || stat -c%s "$SOURCE_FILE" 2>/dev/null)
source_size_kb=$((source_size / 1024))
source_lines=$(wc -l < "$SOURCE_FILE")

echo -e "源文件大小: ${CYAN}${source_size_kb} KB${NC}"
echo -e "源文件行数: ${CYAN}${source_lines}${NC}"
echo ""

# 如果输出文件已存在，备份
if [ -f "$OUTPUT_FILE" ]; then
    backup_file="${OUTPUT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}输出文件已存在，备份到: $(basename $backup_file)${NC}"
    cp "$OUTPUT_FILE" "$backup_file"
    echo ""
fi

echo -e "${GREEN}开始转换...${NC}"
echo ""

# 使用 pandoc 进行转换
# 参数说明:
# -f markdown: 从 Markdown 格式读取
# -t html: 输出为 HTML 格式
# --standalone: 生成完整的 HTML 文档（包含头部）
# --metadata: 设置元数据
# --template: 可以使用模板（暂不使用）
# -o: 输出文件

# 先转换为基础 HTML
if pandoc -f markdown -t html \
    --standalone \
    --metadata title="现代骑士" \
    --metadata lang="zh-CN" \
    --css="../styles/stylesheet1.css" \
    "$SOURCE_FILE" -o "$OUTPUT_FILE.tmp"; then
    
    echo -e "${GREEN}✓ Pandoc 转换成功${NC}"
    
    # 修改生成的 HTML 以符合 EPUB 标准
    # 1. 添加 EPUB 命名空间
    # 2. 添加正确的 DOCTYPE
    # 3. 调整 body 属性
    
    sed -i.bak '1i\
<?xml version="1.0" encoding="UTF-8"?>\
<!DOCTYPE html>
' "$OUTPUT_FILE.tmp"
    
    # 替换 html 标签，添加 EPUB 命名空间
    sed -i.bak 's|<html lang="zh-CN">|<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="zh-CN" xml:lang="zh-CN">|' "$OUTPUT_FILE.tmp"
    
    # 添加 epub:type 到 body
    sed -i.bak 's|<body>|<body epub:type="bodymatter">|' "$OUTPUT_FILE.tmp"
    
    # 移动到最终位置
    mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
    rm -f "$OUTPUT_FILE.tmp.bak"
    
    echo -e "${GREEN}✓ EPUB 格式调整完成${NC}"
    echo ""
    
    # 获取输出文件信息
    output_size=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    output_size_kb=$((output_size / 1024))
    output_lines=$(wc -l < "$OUTPUT_FILE")
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}转换完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "输出文件: ${GREEN}$OUTPUT_FILE${NC}"
    echo -e "文件大小: ${CYAN}${output_size_kb} KB${NC} (${output_size} 字节)"
    echo -e "总行数: ${CYAN}${output_lines}${NC}"
    echo ""
    echo -e "${YELLOW}提示:${NC}"
    echo -e "1. XHTML 文件已生成，符合 EPUB 标准"
    echo -e "2. 文件引用了 ../styles/stylesheet1.css 样式表"
    echo -e "3. 图片路径指向 ../media/ 目录"
    echo -e "4. 可以用于重新打包 EPUB 电子书"
    echo ""
else
    echo -e "${RED}✗ 转换失败${NC}"
    rm -f "$OUTPUT_FILE.tmp"
    exit 1
fi
