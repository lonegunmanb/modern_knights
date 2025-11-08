#!/bin/bash

# 将大的 ch001.md 文件按页码拆分成多个页面文件
# 作者: 自动生成
# 用途: 方便翻译和管理

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}Markdown 页面拆分工具${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 定义目录和文件
INPUT_FILE="EPUB/markdown/ch001.md"
OUTPUT_DIR="EPUB/pages"

# 检查输入文件是否存在
if [ ! -f "$INPUT_FILE" ]; then
    echo -e "${RED}✗ 错误: 找不到文件 $INPUT_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}输入文件: ${NC}$INPUT_FILE"
echo -e "${BLUE}输出目录: ${NC}$OUTPUT_DIR"
echo ""

# 创建输出目录
if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    echo -e "${GREEN}✓ 创建目录: $OUTPUT_DIR${NC}"
else
    echo -e "${YELLOW}目录已存在: $OUTPUT_DIR${NC}"
    echo -e "${YELLOW}清理旧文件...${NC}"
    rm -f "$OUTPUT_DIR"/page_*.md
fi

echo ""
echo -e "${GREEN}开始拆分文件...${NC}"
echo ""

# 使用 awk 脚本进行拆分
awk '
BEGIN {
    page_num = 0
    output_dir = "EPUB/pages"
    output_file = ""
    line_count = 0
    in_content = 0
}

# 检测是否是独立的页码行（仅包含一个或多个数字）
/^[0-9]+$/ {
    # 如果当前有打开的文件，先关闭它
    if (output_file != "" && line_count > 0) {
        close(output_file)
        printf "  ✓ 页面 %03d: %d 行\n", page_num, line_count
    }
    
    # 开始新的页面
    page_num = $1
    output_file = sprintf("%s/page_%03d.md", output_dir, page_num)
    line_count = 0
    in_content = 1
    
    # 不写入页码本身到输出文件
    next
}

# 写入内容到当前页面文件
{
    if (in_content && output_file != "") {
        print $0 >> output_file
        line_count++
    } else if (!in_content) {
        # 第一页之前的内容（前言等）
        if (output_file == "") {
            output_file = sprintf("%s/page_%03d.md", output_dir, 0)
            in_content = 1
        }
        print $0 >> output_file
        line_count++
    }
}

END {
    # 关闭最后一个文件
    if (output_file != "" && line_count > 0) {
        close(output_file)
        printf "  ✓ 页面 %03d: %d 行\n", page_num, line_count
    }
    
    printf "\n"
    printf "拆分完成！总共生成 %d 个页面文件\n", page_num + 1
}
' "$INPUT_FILE"

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}拆分完成！${NC}"
echo -e "${GREEN}=====================================${NC}"

# 统计生成的文件数量
file_count=$(ls -1 "$OUTPUT_DIR"/page_*.md 2>/dev/null | wc -l)
echo -e "总页面数: ${GREEN}$file_count${NC}"
echo -e "文件位置: ${GREEN}$OUTPUT_DIR/${NC}"
echo ""

# 显示文件列表示例
echo -e "${YELLOW}生成的文件示例:${NC}"
ls -lh "$OUTPUT_DIR"/page_*.md | head -10

echo ""
echo -e "${YELLOW}提示:${NC}"
echo -e "1. 页面文件按照原书的页码命名 (page_000.md, page_013.md, page_014.md...)"
echo -e "2. page_000.md 包含第一个页码标记之前的所有内容（目录、前言等）"
echo -e "3. 每个文件包含一页的内容，方便逐页翻译"
echo -e "4. 翻译完成后可以使用其他脚本将所有页面合并回完整的文档"
echo ""
