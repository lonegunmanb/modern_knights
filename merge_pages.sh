#!/bin/bash

# 合并 EPUB/cn-pages 下所有翻译后的 Markdown 文件
# 按文件名排序后拼接成一个完整的文件

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Markdown 文件合并工具${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 定义目录和输出文件
SOURCE_DIR="EPUB/cn-pages"
OUTPUT_DIR="EPUB/markdown"
OUTPUT_FILE="$OUTPUT_DIR/ch001.md"

# 检查源目录
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}错误: 源目录不存在: $SOURCE_DIR${NC}"
    exit 1
fi

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR"

echo -e "源目录: ${CYAN}$SOURCE_DIR${NC}"
echo -e "输出文件: ${CYAN}$OUTPUT_FILE${NC}"
echo ""

# 统计文件数量
total_files=$(find "$SOURCE_DIR" -name "*.md" -type f | wc -l)
echo -e "找到 ${CYAN}$total_files${NC} 个 Markdown 文件"
echo ""

# 如果输出文件已存在，备份
if [ -f "$OUTPUT_FILE" ]; then
    backup_file="${OUTPUT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}输出文件已存在，备份到: $backup_file${NC}"
    cp "$OUTPUT_FILE" "$backup_file"
    echo ""
fi

# 清空或创建输出文件
> "$OUTPUT_FILE"

echo -e "${GREEN}开始合并文件...${NC}"
echo ""

# 计数器
processed=0

# 按文件名排序，然后合并
# 使用自然排序（-V）确保 page_1, page_2, ..., page_10 等顺序正确
for file in $(find "$SOURCE_DIR" -name "*.md" -type f | sort -V); do
    if [ -f "$file" ]; then
        processed=$((processed + 1))
        filename=$(basename "$file")
        
        # 显示进度（每10个文件显示一次）
        if [ $((processed % 10)) -eq 0 ] || [ $processed -eq 1 ] || [ $processed -eq $total_files ]; then
            echo -e "${BLUE}[$processed/$total_files]${NC} 添加: ${CYAN}$filename${NC}"
        fi
        
        # 追加文件内容到输出文件
        cat "$file" >> "$OUTPUT_FILE"
        
        # 在每个文件后添加分隔（两个空行）
        echo "" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
done

# 计算输出文件大小和行数
if [ -f "$OUTPUT_FILE" ]; then
    file_size=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    file_size_kb=$((file_size / 1024))
    line_count=$(wc -l < "$OUTPUT_FILE")
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}合并完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "处理文件数: ${CYAN}$processed${NC}"
    echo -e "输出文件: ${GREEN}$OUTPUT_FILE${NC}"
    echo -e "文件大小: ${CYAN}${file_size_kb} KB${NC} (${file_size} 字节)"
    echo -e "总行数: ${CYAN}${line_count}${NC}"
    echo ""
else
    echo -e "${RED}错误: 输出文件未生成${NC}"
    exit 1
fi
