#!/bin/bash

# 将中文翻译版本重新打包成 EPUB 电子书
# 基于 EPUB/text-cn 目录创建 modern-knights-cn.epub

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}EPUB 中文版打包工具${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# 定义变量
OUTPUT_FILE="modern-knights-cn.epub"
TEMP_DIR="/tmp/epub-cn-build-$$"

echo -e "输出文件: ${CYAN}$OUTPUT_FILE${NC}"
echo ""

# 检查必要的文件和目录
echo -e "${BLUE}检查必要的文件...${NC}"

required_dirs=("EPUB/text-cn" "EPUB/styles" "EPUB/media" "META-INF")
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo -e "${RED}✗ 缺少目录: $dir${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} $dir"
done

required_files=("mimetype" "EPUB/text-cn/title_page.xhtml" "EPUB/text-cn/ch001.xhtml")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ 缺少文件: $file${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓${NC} $file"
done

echo ""

# 如果输出文件已存在，删除或备份
if [ -f "$OUTPUT_FILE" ]; then
    backup_file="${OUTPUT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
    echo -e "${YELLOW}输出文件已存在，备份到: $backup_file${NC}"
    mv "$OUTPUT_FILE" "$backup_file"
    echo ""
fi

# 创建临时构建目录
echo -e "${BLUE}准备构建目录...${NC}"
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR/EPUB"
mkdir -p "$TEMP_DIR/META-INF"

# 复制 mimetype（必须是第一个文件，不压缩）
cp mimetype "$TEMP_DIR/"
echo -e "${GREEN}✓${NC} 复制 mimetype"

# 复制 META-INF
cp -r META-INF/* "$TEMP_DIR/META-INF/"
echo -e "${GREEN}✓${NC} 复制 META-INF"

# 复制中文文本文件
mkdir -p "$TEMP_DIR/EPUB/text"
cp EPUB/text-cn/*.xhtml "$TEMP_DIR/EPUB/text/"
echo -e "${GREEN}✓${NC} 复制中文文本文件"

# 复制样式表
cp -r EPUB/styles "$TEMP_DIR/EPUB/"
echo -e "${GREEN}✓${NC} 复制样式表"

# 复制媒体文件（图片）
cp -r EPUB/media "$TEMP_DIR/EPUB/"
echo -e "${GREEN}✓${NC} 复制媒体文件"

# 创建中文版的 content.opf
echo -e "${BLUE}生成 content.opf...${NC}"
cat > "$TEMP_DIR/EPUB/content.opf" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" xml:lang="zh-CN" unique-identifier="epub-id-1" prefix="ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:identifier id="epub-id-1">urn:uuid:db37f40a-7104-4443-92a9-80531a60f8bd-cn</dc:identifier>
    <dc:title id="epub-title-1">现代骑士</dc:title>
    <dc:date id="epub-date">2025-11-08T00:00:00Z</dc:date>
    <dc:language>zh-CN</dc:language>
    <dc:creator id="epub-creator-1">安德烈·范·博斯贝克</dc:creator>
    <dc:contributor id="translator">AI 翻译</dc:contributor>
    <meta refines="#epub-creator-1" property="role" scheme="marc:relators">aut</meta>
    <meta refines="#translator" property="role" scheme="marc:relators">trl</meta>
    <meta property="dcterms:modified">2025-11-08T00:00:00Z</meta>
    <meta property="schema:accessMode">textual</meta>
    <meta property="schema:accessModeSufficient">textual</meta>
    <meta property="schema:accessibilityFeature">alternativeText</meta>
    <meta property="schema:accessibilityFeature">readingOrder</meta>
    <meta property="schema:accessibilityFeature">structuralNavigation</meta>
    <meta property="schema:accessibilityFeature">tableOfContents</meta>
    <meta property="schema:accessibilityHazard">none</meta>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav" />
    <item id="stylesheet1" href="styles/stylesheet1.css" media-type="text/css" />
    <item id="title_page_xhtml" href="text/title_page.xhtml" media-type="application/xhtml+xml" />
    <item id="ch001_xhtml" href="text/ch001.xhtml" media-type="application/xhtml+xml" />
EOF

# 添加所有媒体文件到 manifest
for img in EPUB/media/*; do
    if [ -f "$img" ]; then
        filename=$(basename "$img")
        ext="${filename##*.}"
        id="${filename%.*}"
        
        if [ "$ext" = "jpg" ] || [ "$ext" = "jpeg" ]; then
            media_type="image/jpeg"
        elif [ "$ext" = "png" ]; then
            media_type="image/png"
        else
            media_type="image/$ext"
        fi
        
        echo "    <item id=\"${id}_${ext}\" href=\"media/$filename\" media-type=\"$media_type\" />" >> "$TEMP_DIR/EPUB/content.opf"
    fi
done

# 完成 content.opf
cat >> "$TEMP_DIR/EPUB/content.opf" << 'EOF'
  </manifest>
  <spine toc="ncx">
    <itemref idref="title_page_xhtml" linear="yes" />
    <itemref idref="ch001_xhtml" />
  </spine>
  <guide>
    <reference type="toc" title="现代骑士" href="nav.xhtml" />
  </guide>
</package>
EOF

echo -e "${GREEN}✓${NC} 生成 content.opf"

# 创建简单的 nav.xhtml
echo -e "${BLUE}生成 nav.xhtml...${NC}"
cat > "$TEMP_DIR/EPUB/nav.xhtml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="zh-CN" xml:lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <title>目录</title>
  <link rel="stylesheet" type="text/css" href="styles/stylesheet1.css" />
</head>
<body>
<nav epub:type="toc" id="toc">
  <h1>目录</h1>
  <ol>
    <li><a href="text/title_page.xhtml">封面</a></li>
    <li><a href="text/ch001.xhtml">正文</a></li>
  </ol>
</nav>
</body>
</html>
EOF

echo -e "${GREEN}✓${NC} 生成 nav.xhtml"

# 创建 toc.ncx
echo -e "${BLUE}生成 toc.ncx...${NC}"
cat > "$TEMP_DIR/EPUB/toc.ncx" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:db37f40a-7104-4443-92a9-80531a60f8bd-cn" />
    <meta name="dtb:depth" content="1" />
    <meta name="dtb:totalPageCount" content="0" />
    <meta name="dtb:maxPageNumber" content="0" />
  </head>
  <docTitle>
    <text>现代骑士</text>
  </docTitle>
  <navMap>
    <navPoint id="navpoint-1" playOrder="1">
      <navLabel>
        <text>封面</text>
      </navLabel>
      <content src="text/title_page.xhtml" />
    </navPoint>
    <navPoint id="navpoint-2" playOrder="2">
      <navLabel>
        <text>正文</text>
      </navLabel>
      <content src="text/ch001.xhtml" />
    </navPoint>
  </navMap>
</ncx>
EOF

echo -e "${GREEN}✓${NC} 生成 toc.ncx"

echo ""
echo -e "${BLUE}开始打包 EPUB...${NC}"
echo ""

# 进入临时目录
cd "$TEMP_DIR"

# 第一步：添加 mimetype（不压缩，必须是第一个文件）
zip -0 -X "$OUTPUT_FILE" mimetype
echo -e "${GREEN}✓${NC} 添加 mimetype (无压缩)"

# 第二步：添加其他文件（压缩）
zip -r "$OUTPUT_FILE" META-INF EPUB
echo -e "${GREEN}✓${NC} 添加其他文件 (压缩)"

# 移动到工作目录
mv "$OUTPUT_FILE" "/workspaces/modern_knights/"
cd /workspaces/modern_knights

# 清理临时目录
rm -rf "$TEMP_DIR"

# 获取文件信息
if [ -f "$OUTPUT_FILE" ]; then
    file_size=$(stat -f%z "$OUTPUT_FILE" 2>/dev/null || stat -c%s "$OUTPUT_FILE" 2>/dev/null)
    file_size_mb=$(echo "scale=2; $file_size / 1024 / 1024" | bc)
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}打包完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "输出文件: ${GREEN}$OUTPUT_FILE${NC}"
    echo -e "文件大小: ${CYAN}${file_size_mb} MB${NC}"
    echo ""
    echo -e "${YELLOW}提示:${NC}"
    echo -e "1. EPUB 文件已成功创建"
    echo -e "2. 可以使用电子书阅读器打开查看"
    echo -e "3. 建议使用 Calibre 或其他 EPUB 阅读器验证"
    echo ""
else
    echo -e "${RED}错误: EPUB 文件创建失败${NC}"
    exit 1
fi
