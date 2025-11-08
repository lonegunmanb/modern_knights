#!/bin/bash

# 检测 Markdown 文件是否每行都以"数字."为前缀
# 如果检测到这种模式，输出文件名

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}行号前缀检测工具${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 检查是否提供了文件参数
if [ $# -eq 0 ]; then
    echo -e "${RED}错误: 请提供要检查的文件或目录${NC}"
    echo "用法: $0 <文件> 或 $0 <目录>"
    exit 1
fi

TARGET="$1"

# 函数：检查单个文件是否每行都以数字.开头
check_file() {
    local file="$1"
    
    # 跳过空文件
    if [ ! -s "$file" ]; then
        return 1
    fi
    
    # 读取文件，统计总行数和以"数字."开头的行数
    local total_lines=0
    local numbered_lines=0
    local empty_lines=0
    
    while IFS= read -r line; do
        total_lines=$((total_lines + 1))
        
        # 跳过空行
        if [ -z "$line" ]; then
            empty_lines=$((empty_lines + 1))
            continue
        fi
        
        # 检查是否以"数字."开头（数字后面跟一个点，可能有空格）
        if [[ "$line" =~ ^[0-9]+\. ]]; then
            numbered_lines=$((numbered_lines + 1))
        fi
    done < "$file"
    
    # 计算非空行数
    local non_empty_lines=$((total_lines - empty_lines))
    
    # 如果非空行数大于0，且超过80%的非空行都以数字.开头，认为该文件有问题
    if [ $non_empty_lines -gt 0 ]; then
        local percentage=$((numbered_lines * 100 / non_empty_lines))
        
        if [ $percentage -ge 80 ]; then
            echo -e "${RED}✗ 发现问题文件: ${CYAN}$file${NC}"
            echo -e "  总行数: $total_lines, 非空行: $non_empty_lines, 带行号行: $numbered_lines (${percentage}%)"
            return 0
        fi
    fi
    
    return 1
}

# 统计
total_checked=0
problem_files=0

# 如果是文件，直接检查
if [ -f "$TARGET" ]; then
    echo -e "检查文件: ${CYAN}$TARGET${NC}"
    echo ""
    
    if check_file "$TARGET"; then
        problem_files=1
    else
        echo -e "${GREEN}✓ 文件正常${NC}"
    fi
    total_checked=1
    
# 如果是目录，遍历所有.md文件
elif [ -d "$TARGET" ]; then
    echo -e "扫描目录: ${CYAN}$TARGET${NC}"
    echo ""
    
    for file in "$TARGET"/*.md; do
        if [ -f "$file" ]; then
            total_checked=$((total_checked + 1))
            filename=$(basename "$file")
            
            if check_file "$file"; then
                problem_files=$((problem_files + 1))
            fi
        fi
    done
else
    echo -e "${RED}错误: $TARGET 不是有效的文件或目录${NC}"
    exit 1
fi

# 输出统计
echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}检查完成${NC}"
echo -e "${GREEN}=====================================${NC}"
echo -e "检查文件数: ${CYAN}$total_checked${NC}"
echo -e "${RED}问题文件数: $problem_files${NC}"

if [ $problem_files -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}提示: 使用以下命令修复这些文件：${NC}"
    echo -e "${CYAN}./fix_line_numbers.sh $TARGET${NC}"
fi

echo ""
