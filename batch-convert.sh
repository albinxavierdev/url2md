#!/bin/bash

# Batch URL to Markdown Converter
# Process multiple URLs from a text file

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Default settings
URLS_FILE="urls.txt"
OUTPUT_DIR="batch-converted"
DELAY=1
CSS_SELECTOR=""

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS] [URLS_FILE]

Batch convert multiple URLs to Markdown format.

ARGUMENTS:
    URLS_FILE    File containing URLs (one per line) - default: urls.txt

OPTIONS:
    -h, --help          Show this help
    -o, --output DIR    Output directory (default: batch-converted)
    -s, --selector CSS  CSS selector for content extraction
    -d, --delay SECS    Delay between requests in seconds (default: 1)
    --no-media          Skip media downloads
    --media-types TYPE  Comma-separated media types: images,videos,audio,documents,fonts
    --parallel N        Process N URLs in parallel (experimental)

EXAMPLE:
    $0 urls.txt -o articles -s ".content" -d 2

EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -s|--selector)
            CSS_SELECTOR="$2"
            shift 2
            ;;
        -d|--delay)
            DELAY="$2"
            shift 2
            ;;
        --no-media)
            NO_MEDIA="--no-media"
            shift
            ;;
        --media-types)
            MEDIA_TYPES="--media-types $2"
            shift 2
            ;;
        # Legacy support
        --no-images)
            NO_MEDIA="--no-media"
            shift
            ;;
        -*)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            URLS_FILE="$1"
            shift
            ;;
    esac
done

# Check for URLs file
if [[ ! -f "$URLS_FILE" ]]; then
    echo -e "${RED}❌ URLs file not found: $URLS_FILE${NC}"
    echo "Create a file with one URL per line."
    exit 1
fi

# Check for url2md.sh script
if [[ ! -f "./url2md.sh" ]]; then
    echo -e "${RED}❌ url2md.sh script not found${NC}"
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Count URLs
TOTAL_URLS=$(wc -l < "$URLS_FILE")
echo -e "${BLUE}🚀 Batch processing $TOTAL_URLS URLs...${NC}"
echo ""

# Process URLs
SUCCESS_COUNT=0
FAILED_COUNT=0
CURRENT=0

while IFS= read -r url; do
    # Skip empty lines and comments
    if [[ -z "$url" || "$url" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    ((CURRENT++))
    echo -e "${BLUE}[$CURRENT/$TOTAL_URLS] Processing: $url${NC}"
    
    # Build command
    cmd="./url2md.sh"
    if [[ -n "$CSS_SELECTOR" ]]; then
        cmd="$cmd -s \"$CSS_SELECTOR\""
    fi
    if [[ -n "$NO_MEDIA" ]]; then
        cmd="$cmd $NO_MEDIA"
    fi
    if [[ -n "$MEDIA_TYPES" ]]; then
        cmd="$cmd $MEDIA_TYPES"
    fi
    cmd="$cmd -o \"$OUTPUT_DIR\" \"$url\""
    
    # Execute conversion
    if eval "$cmd"; then
        ((SUCCESS_COUNT++))
        echo -e "${GREEN}✅ Success${NC}"
    else
        ((FAILED_COUNT++))
        echo -e "${RED}❌ Failed${NC}"
        echo "$url" >> "$OUTPUT_DIR/failed-urls.txt"
    fi
    
    echo ""
    
    # Respectful delay
    if [[ $CURRENT -lt $TOTAL_URLS ]]; then
        sleep "$DELAY"
    fi
    
done < "$URLS_FILE"

# Summary
echo -e "${BLUE}=== BATCH CONVERSION COMPLETE ===${NC}"
echo -e "${GREEN}✅ Successful: $SUCCESS_COUNT${NC}"
echo -e "${RED}❌ Failed: $FAILED_COUNT${NC}"
echo -e "${BLUE}📁 Output directory: $OUTPUT_DIR${NC}"

if [[ $FAILED_COUNT -gt 0 ]]; then
    echo -e "${RED}📋 Failed URLs saved to: $OUTPUT_DIR/failed-urls.txt${NC}"
fi