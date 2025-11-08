#!/bin/bash

# 使用 GitHub Copilot 翻译 EPUB 页面的脚本
# 将 EPUB/pages 下的文件翻译成中文，保存到 EPUB/cn-pages 目录

set +e  # 不要在错误时立即退出，我们需要处理错误

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}EPUB 页面翻译工具 (使用 GitHub Copilot)${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 检查 copilot 命令是否可用
if ! command -v copilot &> /dev/null; then
    echo -e "${RED}错误: 未找到 copilot 命令${NC}"
    echo -e "${YELLOW}请确保 GitHub Copilot CLI 已正确安装并在 PATH 中${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 检测到 copilot 命令${NC}"
echo ""

# 定义目录
SOURCE_DIR="EPUB/pages"
TARGET_DIR="EPUB/cn-pages"
TEMP_DIR="$TARGET_DIR/.temp"
PROGRESS_FILE="$TARGET_DIR/.translation_progress"

# 检查源目录
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}错误: 源目录不存在: $SOURCE_DIR${NC}"
    exit 1
fi

# 创建目标目录和临时目录
mkdir -p "$TARGET_DIR"
mkdir -p "$TEMP_DIR"

# 加载进度文件
if [ -f "$PROGRESS_FILE" ]; then
    echo -e "${CYAN}✓ 找到进度文件，将继续上次的翻译${NC}"
    source "$PROGRESS_FILE"
else
    echo -e "${YELLOW}未找到进度文件，从头开始翻译${NC}"
    echo "# Translation Progress" > "$PROGRESS_FILE"
fi

echo ""
echo -e "${GREEN}开始翻译页面...${NC}"
echo -e "${YELLOW}提示: 这可能需要较长时间，请耐心等待${NC}"
echo -e "${YELLOW}提示: 可以随时中断（Ctrl+C），下次运行将自动继续${NC}"
echo ""

# 计数器
total_files=$(find "$SOURCE_DIR" -name "*.md" | wc -l)
current=0
success_count=0
skip_count=0
error_count=0

# 捕获中断信号
trap 'echo -e "\n${YELLOW}收到中断信号，正在保存进度...${NC}"; exit 130' INT TERM

# 遍历所有 .md 文件，按文件名排序
for source_file in $(find "$SOURCE_DIR" -name "*.md" | sort); do
    if [ -f "$source_file" ]; then
        current=$((current + 1))
        
        # 获取文件名
        filename=$(basename "$source_file")
        target_file="$TARGET_DIR/$filename"
        temp_file="$TEMP_DIR/$filename"
        
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}[$current/$total_files]${NC} 处理: ${CYAN}$filename${NC}"
        
        # 检查是否已经翻译完成
        if [ -f "$target_file" ]; then
            file_size=$(stat -f%z "$target_file" 2>/dev/null || stat -c%s "$target_file" 2>/dev/null)
            if [ "$file_size" -gt 10 ]; then
                echo -e "  ${GREEN}✓ 已完成翻译，跳过${NC}"
                success_count=$((success_count + 1))
                skip_count=$((skip_count + 1))
                continue
            else
                echo -e "  ${YELLOW}⚠ 文件存在但内容异常（小于10字节），重新翻译${NC}"
                rm -f "$target_file"
            fi
        fi
        
        # 检查是否有临时文件（上次翻译失败）
        if [ -f "$temp_file" ]; then
            echo -e "  ${YELLOW}⚠ 发现未完成的临时文件，删除后重新翻译${NC}"
            rm -f "$temp_file"
        fi
        
        # 构建 copilot 命令
        prompt="请将文件 '$source_file' 的内容翻译成简体中文，并保存到 '$target_file'。

翻译要求：
1. 保持原有的 Markdown 格式不变
2. 保持图片链接路径不变（如 ../media/xxx.jpg）
3. 保持特殊格式标记不变（如 ::: {.xxx}）
4. 只翻译文本内容，不要翻译 URL、代码、文件路径等
5. 翻译要准确流畅，符合简体中文表达习惯
6. 专有名词保持原文或添加中文注释
7. 完成翻译后，确认文件已成功保存到目标路径
8. 不要添加任何额外的说明或注释
9. 不要擅自添加行号或标记

请立即开始翻译。"
        
        echo -e "  ${CYAN}→ 正在调用 Copilot 翻译...${NC}"
        
        # 记录开始时间
        start_time=$(date +%s)
        
        # 先翻译到临时文件，确保翻译完成后再移动
        temp_prompt="请将文件 '$source_file' 的内容翻译成简体中文，并保存到 '$temp_file'。

翻译要求：
1. 保持原有的 Markdown 格式不变
2. 保持图片链接路径不变（如 ../media/xxx.jpg）
3. 保持特殊格式标记不变（如 ::: {.xxx}）
4. 只翻译文本内容，不要翻译 URL、代码、文件路径等
5. 翻译要准确流畅，符合简体中文表达习惯
6. 专有名词保持原文或添加中文注释
7. 不要擅自添加行号或标记

请立即开始翻译。"
        
        # 执行 copilot 翻译
        log_file="$TEMP_DIR/${filename%.md}.log"
        if copilot -p "$temp_prompt" --allow-all-tools --no-color --model gpt-5 > "$log_file" 2>&1; then
            # 记录结束时间
            end_time=$(date +%s)
            duration=$((end_time - start_time))
            
            # 验证临时文件是否已创建且不为空
            if [ -f "$temp_file" ]; then
                file_size=$(stat -f%z "$temp_file" 2>/dev/null || stat -c%s "$temp_file" 2>/dev/null)
                if [ "$file_size" -gt 10 ]; then
                    # 翻译成功，移动到目标位置
                    mv "$temp_file" "$target_file"
                    success_count=$((success_count + 1))
                    echo -e "  ${GREEN}✓ 翻译完成${NC} (耗时: ${duration}秒, 大小: ${file_size}字节)"
                    
                    # 更新进度文件
                    echo "TRANSLATED_$current=\"$filename\"" >> "$PROGRESS_FILE"
                    
                    # 删除日志文件
                    rm -f "$log_file"
                else
                    error_count=$((error_count + 1))
                    echo -e "  ${RED}✗ 翻译失败: 生成的文件太小 (${file_size}字节)${NC}"
                    echo -e "  ${YELLOW}日志已保存: $log_file${NC}"
                    rm -f "$temp_file"
                fi
            else
                error_count=$((error_count + 1))
                echo -e "  ${RED}✗ 翻译失败: 未生成目标文件${NC}"
                echo -e "  ${YELLOW}日志已保存: $log_file${NC}"
            fi
        else
            error_count=$((error_count + 1))
            echo -e "  ${RED}✗ 翻译失败: copilot 命令执行出错${NC}"
            echo -e "  ${YELLOW}日志已保存: $log_file${NC}"
            rm -f "$temp_file"
        fi
        
        echo ""
        
        # 添加短暂延迟，避免 API 限流
        sleep 2
    fi
done

# 清理临时目录（如果为空）
rmdir "$TEMP_DIR" 2>/dev/null || true

# 输出统计信息
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}翻译任务完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "总文件数: ${CYAN}$total_files${NC}"
echo -e "${GREEN}成功翻译: $success_count${NC} (其中 ${YELLOW}跳过已完成: $skip_count${NC})"

if [ $error_count -gt 0 ]; then
    echo -e "${RED}失败: $error_count${NC}"
    echo -e "${YELLOW}失败的日志已保存到: $TEMP_DIR/*.log${NC}"
    echo -e "${YELLOW}请检查日志文件，修复问题后重新运行此脚本${NC}"
else
    echo -e "${GREEN}✓ 所有文件翻译成功！${NC}"
fi

echo ""
echo -e "翻译后的文件保存位置: ${GREEN}$TARGET_DIR${NC}"
echo -e "进度文件位置: ${CYAN}$PROGRESS_FILE${NC}"
echo ""

# 如果有错误，返回非零退出码
if [ $error_count -gt 0 ]; then
    exit 1
else
    exit 0
fi