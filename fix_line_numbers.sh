#!/bin/bash

# 修复 Markdown 文件中的行号前缀
# 先检测文件是否每行都以"数字."为前缀，然后去除行号

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}行号前缀修复工具${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 检查是否提供了文件参数
if [ $# -eq 0 ]; then
    echo -e "${RED}错误: 请提供要修复的文件或目录${NC}"
    echo "用法: $0 <文件> 或 $0 <目录>"
    exit 1
fi

TARGET="$1"

# 函数：检查单个文件是否需要修复
needs_fix() {
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
        
        # 检查是否以"数字."开头
        if [[ "$line" =~ ^[0-9]+\. ]]; then
            numbered_lines=$((numbered_lines + 1))
        fi
    done < "$file"
    
    # 计算非空行数
    local non_empty_lines=$((total_lines - empty_lines))
    
    # 如果非空行数大于0，且超过80%的非空行都以数字.开头，返回0（需要修复）
    if [ $non_empty_lines -gt 0 ]; then
        local percentage=$((numbered_lines * 100 / non_empty_lines))
        
        if [ $percentage -ge 80 ]; then
            return 0
        fi
    fi
    
    return 1
}

# 函数：修复单个文件
fix_file() {
    local file="$1"
    local temp_file="/tmp/fix_line_numbers_$$.tmp"
    
    # 使用 sed 去除行号前缀（数字.后面可能有空格）
    if sed -E 's/^[0-9]+\.\s*//' "$file" > "$temp_file"; then
        # 验证临时文件不为空
        if [ -s "$temp_file" ]; then
            mv "$temp_file" "$file"
            return 0
        else
            echo -e "  ${RED}错误: 生成的文件为空${NC}"
            rm -f "$temp_file"
            return 1
        fi
    else
        echo -e "  ${RED}错误: sed 命令执行失败${NC}"
        rm -f "$temp_file"
        return 1
    fi
}

# 统计
total_checked=0
fixed_count=0
skipped_count=0
error_count=0

# 如果是文件，直接处理
if [ -f "$TARGET" ]; then
    echo -e "检查文件: ${CYAN}$TARGET${NC}"
    echo ""
    
    if needs_fix "$TARGET"; then
        echo -e "  ${YELLOW}→ 需要修复，正在处理...${NC}"
        if fix_file "$TARGET"; then
            echo -e "  ${GREEN}✓ 修复成功${NC}"
            fixed_count=1
        else
            echo -e "  ${RED}✗ 修复失败${NC}"
            error_count=1
        fi
    else
        echo -e "  ${GREEN}✓ 文件正常，无需修复${NC}"
        skipped_count=1
    fi
    total_checked=1
    
# 如果是目录，遍历所有.md文件
elif [ -d "$TARGET" ]; then
    echo -e "扫描目录: ${CYAN}$TARGET${NC}"
    echo ""
    
    # 先收集需要修复的文件列表
    files_to_fix=()
    
    for file in "$TARGET"/*.md; do
        if [ -f "$file" ]; then
            total_checked=$((total_checked + 1))
            
            if needs_fix "$file"; then
                files_to_fix+=("$file")
            else
                skipped_count=$((skipped_count + 1))
            fi
        fi
    done
    
    # 显示将要修复的文件数量
    if [ ${#files_to_fix[@]} -gt 0 ]; then
        echo -e "${YELLOW}发现 ${#files_to_fix[@]} 个需要修复的文件${NC}"
        echo ""
        
        # 逐个修复
        for file in "${files_to_fix[@]}"; do
            filename=$(basename "$file")
            echo -e "${BLUE}[$((fixed_count + error_count + 1))/${#files_to_fix[@]}]${NC} 修复: ${CYAN}$filename${NC}"
            
            if fix_file "$file"; then
                echo -e "  ${GREEN}✓ 修复成功${NC}"
                fixed_count=$((fixed_count + 1))
            else
                echo -e "  ${RED}✗ 修复失败${NC}"
                error_count=$((error_count + 1))
            fi
            echo ""
        done
    else
        echo -e "${GREEN}✓ 所有文件都正常，无需修复${NC}"
        echo ""
    fi
    
else
    echo -e "${RED}错误: $TARGET 不是有效的文件或目录${NC}"
    exit 1
fi

# 输出统计
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}修复完成${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "检查文件数: ${CYAN}$total_checked${NC}"
echo -e "${GREEN}成功修复: $fixed_count${NC}"
echo -e "${BLUE}跳过(正常): $skipped_count${NC}"

if [ $error_count -gt 0 ]; then
    echo -e "${RED}失败: $error_count${NC}"
fi

echo ""

# 如果有错误，返回非零退出码
if [ $error_count -gt 0 ]; then
    exit 1
else
    exit 0
fi
