#!/bin/bash

# URL to Markdown Converter
# A simple script to convert web pages to clean Markdown format

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MEDIA_DIR="media"
OUTPUT_DIR="markdown"
USER_AGENT="Mozilla/5.0 (compatible; URL2MD-Converter)"

# Media file extensions
IMAGE_EXTENSIONS="jpg jpeg png gif webp svg bmp ico tiff tif"
VIDEO_EXTENSIONS="mp4 webm ogg avi mov wmv flv mkv m4v"
AUDIO_EXTENSIONS="mp3 wav ogg flac aac m4a wma opus"
DOCUMENT_EXTENSIONS="pdf doc docx ppt pptx xls xlsx zip rar 7z tar gz"
FONT_EXTENSIONS="woff woff2 ttf otf eot"

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <URL> [OUTPUT_FILE]

Convert web pages to clean Markdown format with local media downloads.

ARGUMENTS:
    URL          The web page URL to convert
    OUTPUT_FILE  Optional output file path (default: auto-generated from URL)

OPTIONS:
    -h, --help          Show this help message
    -s, --selector CSS  Use specific CSS selector to extract content
    -d, --domain DOMAIN Override domain for relative URL resolution
    -m, --media DIR     Directory to save media files (default: media)
    -o, --output DIR    Output directory (default: markdown)
    --no-media          Skip downloading media files
    --media-types TYPE  Comma-separated media types to download: images,videos,audio,documents,fonts (default: all)
    --keep-html         Keep HTML file for debugging

EXAMPLES:
    $0 https://example.com/article
    $0 https://blog.com/post -s ".content" -o articles
    $0 https://site.com/page.html my-article.md
    $0 https://tutorial.com/page --media-types images,videos -m assets

EOF
    exit 0
}

# Function to clean filename
clean_filename() {
    local url="$1"
    # Extract filename from URL, remove protocol and clean up
    local filename=$(echo "$url" | sed 's|^https\?://||' | sed 's|/$||' | tr '/' '_' | tr -cd '[:alnum:]._-')
    if [[ -z "$filename" ]]; then
        filename="webpage_$(date +%s)"
    fi
    echo "${filename}.md"
}

# Function to detect media type from file extension
get_media_type() {
    local url="$1"
    local filename=$(basename "$url" | cut -d'?' -f1 | cut -d'#' -f1)
    local extension=$(echo "$filename" | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]')
    
    if echo " $IMAGE_EXTENSIONS " | grep -q " $extension "; then
        echo "images"
    elif echo " $VIDEO_EXTENSIONS " | grep -q " $extension "; then
        echo "videos"
    elif echo " $AUDIO_EXTENSIONS " | grep -q " $extension "; then
        echo "audio"
    elif echo " $DOCUMENT_EXTENSIONS " | grep -q " $extension "; then
        echo "documents"
    elif echo " $FONT_EXTENSIONS " | grep -q " $extension "; then
        echo "fonts"
    else
        echo "other"
    fi
}

# Function to check if media type should be downloaded
should_download_media_type() {
    local media_type="$1"
    if [[ -z "$MEDIA_TYPES_FILTER" ]]; then
        return 0  # Download all if no filter specified
    fi
    
    if echo ",$MEDIA_TYPES_FILTER," | grep -q ",$media_type,"; then
        return 0  # Download this type
    fi
    
    return 1  # Skip this type
}

# Function to resolve relative URLs to absolute
resolve_url() {
    local base_url="$1"
    local url="$2"
    
    # Already absolute
    if [[ "$url" =~ ^https?:// ]]; then
        echo "$url"
        return 0
    fi
    
    # Protocol relative
    if [[ "$url" =~ ^// ]]; then
        local protocol=$(echo "$base_url" | sed -n 's|^\(https\?\)://.*|\1|p')
        echo "${protocol}:$url"
        return 0
    fi
    
    # Root relative
    if [[ "$url" =~ ^/ ]]; then
        local domain=$(echo "$base_url" | sed -n 's|^\(https\?://[^/]*\).*|\1|p')
        echo "${domain}${url}"
        return 0
    fi
    
    # Path relative
    local base_path=$(echo "$base_url" | sed 's|/[^/]*$|/|')
    echo "${base_path}${url}"
}

# Function to download media file and return local path
download_media() {
    local media_url="$1"
    local base_name="$2"
    
    # Skip data URLs and already local paths
    if [[ "$media_url" =~ ^(data:|$MEDIA_DIR/) ]]; then
        echo "$media_url"
        return 0
    fi
    
    # Detect media type
    local media_type=$(get_media_type "$media_url")
    
    # Check if this media type should be downloaded
    if ! should_download_media_type "$media_type"; then
        echo "$media_url"  # Return original URL if not downloading this type
        return 0
    fi
    
    # Extract filename and extension
    local filename=$(basename "$media_url" | cut -d'?' -f1 | cut -d'#' -f1)
    if [[ ! "$filename" =~ \. ]]; then
        # Try to detect extension from URL or content-type
        if [[ "$media_url" =~ \.(jpe?g|png|gif|webp|svg|bmp|ico|tiff?)($|\?) ]]; then
            local ext=$(echo "$media_url" | grep -oE '\.(jpe?g|png|gif|webp|svg|bmp|ico|tiff?)($|\?)' | head -1 | sed 's/?$//')
            filename="media${ext}"
        else
            filename="media.bin"  # Generic fallback
        fi
    fi
    
    # Clean filename
    filename=$(echo "$filename" | sed 's/[^a-zA-Z0-9._-]/_/g')
    local local_filename="${base_name}_${filename}"
    
    # Create media type subdirectory
    local media_subdir="$MEDIA_DIR/$media_type"
    mkdir -p "$media_subdir"
    local local_path="$media_subdir/$local_filename"
    
    # Get appropriate emoji for media type
    local emoji="📄"
    case "$media_type" in
        "images") emoji="🖼️" ;;
        "videos") emoji="🎬" ;;
        "audio") emoji="🎵" ;;
        "documents") emoji="📄" ;;
        "fonts") emoji="🔤" ;;
        "other") emoji="📎" ;;
    esac
    
    # Download if not exists
    if [[ ! -f "$local_path" ]]; then
        echo "  📥 Downloading $emoji $media_type: $media_url"
        
        # Use appropriate timeout based on media type
        local timeout=15
        if [[ "$media_type" == "videos" ]]; then
            timeout=60  # Videos might be larger
        elif [[ "$media_type" == "documents" ]]; then
            timeout=30  # Documents can be large
        fi
        
        if wget -q --timeout="$timeout" --tries=2 --user-agent="$USER_AGENT" "$media_url" -O "$local_path" 2>/dev/null; then
            if [[ -s "$local_path" ]]; then
                local file_size=$(du -h "$local_path" | cut -f1)
                echo "  ✅ Saved: $local_filename ($file_size)"
                echo "$media_type/$local_filename"
            else
                rm -f "$local_path"
                echo "  ❌ Failed: Empty file"
                echo "$media_url"
            fi
        else
            echo "  ❌ Failed to download $media_type"
            echo "$media_url"
        fi
    else
        local file_size=$(du -h "$local_path" | cut -f1)
        echo "  ♻️  Using cached $emoji: $local_filename ($file_size)"
        echo "$media_type/$local_filename"
    fi
}

# Function to process all media in markdown content
process_media() {
    local content="$1"
    local base_url="$2"
    local base_name="$3"
    local temp_file=$(mktemp)
    local media_urls_file=$(mktemp)
    local processed=0
    
    if [[ "$SKIP_MEDIA" == "true" ]]; then
        echo "$content"
        return 0
    fi
    
    echo "$content" > "$temp_file"
    echo "🔍 Scanning for media files..."
    
    # Find all media URLs in various formats:
    # 1. Markdown images: ![alt](url)
    # 2. HTML img tags: <img src="url">
    # 3. HTML video tags: <video src="url"> and <source src="url">
    # 4. HTML audio tags: <audio src="url"> and <source src="url">
    # 5. HTML links to documents: <a href="url.pdf">
    # 6. CSS font references: url(font.woff)
    
    # Extract markdown image URLs
    grep -oE '!\[[^]]*\]\([^)]+\)' "$temp_file" | sed -n 's/.*(\([^)]*\)).*/\1/p' > "$media_urls_file"
    
    # Extract HTML img tag URLs
    grep -oE '<img[^>]+src=["\047]([^"\047]+)["\047]' "$temp_file" | sed -n 's/.*src=["\047]\([^"\047]*\)["\047].*/\1/p' >> "$media_urls_file"
    
    # Extract HTML video URLs
    grep -oE '<video[^>]+src=["\047]([^"\047]+)["\047]' "$temp_file" | sed -n 's/.*src=["\047]\([^"\047]*\)["\047].*/\1/p' >> "$media_urls_file"
    grep -oE '<source[^>]+src=["\047]([^"\047]+)["\047]' "$temp_file" | sed -n 's/.*src=["\047]\([^"\047]*\)["\047].*/\1/p' >> "$media_urls_file"
    
    # Extract HTML audio URLs
    grep -oE '<audio[^>]+src=["\047]([^"\047]+)["\047]' "$temp_file" | sed -n 's/.*src=["\047]\([^"\047]*\)["\047].*/\1/p' >> "$media_urls_file"
    
    # Extract document links (PDF, DOC, etc.)
    grep -oE '<a[^>]+href=["\047]([^"\047]+\.(pdf|doc|docx|ppt|pptx|xls|xlsx|zip|rar|7z|tar|gz))["\047]' "$temp_file" | sed -n 's/.*href=["\047]\([^"\047]*\)["\047].*/\1/p' >> "$media_urls_file"
    
    # Extract CSS font URLs
    grep -oE 'url\([^)]*\.(woff2?|ttf|otf|eot)[^)]*\)' "$temp_file" | sed -n 's/url(\([^)]*\))/\1/p' | sed 's/["\047]//g' >> "$media_urls_file"
    
    # Process each unique media URL
    while IFS= read -r media_url; do
        [[ -z "$media_url" ]] && continue
        
        # Skip data URLs and already local media
        if [[ "$media_url" =~ ^(data:|$MEDIA_DIR/|#) ]]; then
            continue
        fi
        
        # Resolve relative URL
        local resolved_url=$(resolve_url "$base_url" "$media_url")
        local media_type=$(get_media_type "$resolved_url")
        
        echo "    Processing $media_type: $resolved_url"
        
        # Download media file
        local local_path=$(download_media "$resolved_url" "$base_name")
        
        # Replace in content if download was successful
        if [[ "$local_path" != "$resolved_url" && "$local_path" != "$media_url" ]]; then
            # Add media/ prefix if not already present
            if [[ ! "$local_path" =~ ^$MEDIA_DIR/ ]]; then
                local_path="$MEDIA_DIR/$local_path"
            fi
            
            # Replace both original and resolved URLs
            sed -i "s|$media_url|$local_path|g" "$temp_file"
            sed -i "s|$resolved_url|$local_path|g" "$temp_file"
            ((processed++))
        fi
        
    done < <(sort -u "$media_urls_file" | head -50)  # Limit to first 50 media files
    
    echo "✅ Processed $processed media files"
    cat "$temp_file"
    rm -f "$temp_file" "$media_urls_file"
}

# Main conversion function
convert_url() {
    local url="$1"
    local output_file="$2"
    local css_selector="$3"
    local domain_override="$4"
    
    echo -e "${BLUE}🌐 Converting: $url${NC}"
    
    # Generate output filename if not provided
    if [[ -z "$output_file" ]]; then
        output_file="$OUTPUT_DIR/$(clean_filename "$url")"
    fi
    
    # Create output directory
    mkdir -p "$(dirname "$output_file")" "$OUTPUT_DIR"
    
    # Create temporary files
    local temp_html=$(mktemp)
    local temp_md=$(mktemp)
    
    # Download HTML content
    echo "📄 Fetching HTML content..."
    if ! wget -q --timeout=30 --tries=3 --user-agent="$USER_AGENT" "$url" -O "$temp_html"; then
        echo -e "${RED}❌ Failed to fetch HTML from: $url${NC}"
        rm -f "$temp_html" "$temp_md"
        exit 1
    fi
    
    # Convert to Markdown using html2markdown binary
    echo "🔄 Converting to Markdown..."
    local domain_param=""
    if [[ -n "$domain_override" ]]; then
        domain_param="-domain=\"$domain_override\""
    fi
    
    local selector_param=""
    if [[ -n "$css_selector" ]]; then
        selector_param="-sel=\"$css_selector\""
    fi
    
    if ! eval "./html2markdown $domain_param $selector_param" < "$temp_html" > "$temp_md" 2>/dev/null; then
        echo -e "${RED}❌ Failed to convert HTML to Markdown${NC}"
        rm -f "$temp_html" "$temp_md"
        exit 1
    fi
    
    # Check if conversion produced content
    if [[ ! -s "$temp_md" ]]; then
        echo -e "${RED}❌ Conversion produced empty result${NC}"
        rm -f "$temp_html" "$temp_md"
        exit 1
    fi
    
    # Process media files and get final content
    local base_name=$(basename "$output_file" .md)
    local final_content=$(process_media "$(cat "$temp_md")" "$url" "$base_name")
    
    # Write final content to output file
    echo "$final_content" > "$output_file"
    
    # Clean up temporary files (unless keeping HTML)
    if [[ "$KEEP_HTML" != "true" ]]; then
        rm -f "$temp_html"
    else
        local html_file="${output_file%.md}.html"
        mv "$temp_html" "$html_file"
        echo "🔧 HTML file saved: $html_file"
    fi
    rm -f "$temp_md"
    
    # Show results
    local file_size=$(wc -c < "$output_file" 2>/dev/null || echo "0")
    echo -e "${GREEN}✅ Conversion complete!${NC}"
    echo -e "${GREEN}📄 Output: $output_file ($file_size bytes)${NC}"
    
    if [[ "$SKIP_MEDIA" != "true" && -d "$MEDIA_DIR" ]]; then
        local total_media=$(find "$MEDIA_DIR" -type f | wc -l)
        echo -e "${GREEN}📎 Media: $total_media files in $MEDIA_DIR/${NC}"
        
        # Show breakdown by media type
        for media_type in images videos audio documents fonts other; do
            if [[ -d "$MEDIA_DIR/$media_type" ]]; then
                local count=$(find "$MEDIA_DIR/$media_type" -type f | wc -l)
                if [[ $count -gt 0 ]]; then
                    local emoji="📄"
                    case "$media_type" in
                        "images") emoji="🖼️" ;;
                        "videos") emoji="🎬" ;;
                        "audio") emoji="🎵" ;;
                        "documents") emoji="📄" ;;
                        "fonts") emoji="🔤" ;;
                        "other") emoji="📎" ;;
                    esac
                    echo -e "${GREEN}  $emoji $media_type: $count files${NC}"
                fi
            fi
        done
    fi
}

# Parse command line arguments
CSS_SELECTOR=""
DOMAIN_OVERRIDE=""
SKIP_MEDIA=""
KEEP_HTML=""
MEDIA_TYPES_FILTER=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -s|--selector)
            CSS_SELECTOR="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN_OVERRIDE="$2"
            shift 2
            ;;
        -m|--media)
            MEDIA_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --no-media)
            SKIP_MEDIA="true"
            shift
            ;;
        --media-types)
            MEDIA_TYPES_FILTER="$2"
            shift 2
            ;;
        --keep-html)
            KEEP_HTML="true"
            shift
            ;;
        # Legacy support for old --no-images option
        --no-images)
            SKIP_MEDIA="true"
            shift
            ;;
        -i|--images)
            MEDIA_DIR="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            echo "Use --help for usage information."
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

# Check for required arguments
if [[ $# -eq 0 ]]; then
    echo -e "${RED}❌ Error: URL is required${NC}"
    echo "Use --help for usage information."
    exit 1
fi

URL="$1"
OUTPUT_FILE="$2"

# Validate URL
if [[ ! "$URL" =~ ^https?:// ]]; then
    echo -e "${RED}❌ Error: Invalid URL format. Must start with http:// or https://${NC}"
    exit 1
fi

# Check for html2markdown binary
if [[ ! -f "./html2markdown" ]]; then
    echo -e "${RED}❌ Error: html2markdown binary not found in current directory${NC}"
    echo "Please ensure the html2markdown binary is available."
    exit 1
fi

# Check for wget
if ! command -v wget &> /dev/null; then
    echo -e "${RED}❌ Error: wget is required for downloading content${NC}"
    echo "Please install wget: sudo apt-get install wget"
    exit 1
fi

# Main execution
echo -e "${BLUE}🚀 URL to Markdown Converter${NC}"
echo ""

convert_url "$URL" "$OUTPUT_FILE" "$CSS_SELECTOR" "$DOMAIN_OVERRIDE"

echo ""
echo -e "${BLUE}🎉 Done!${NC}"