# 📦 URL → Markdown (Modern Terminal Edition)

A comprehensive **multi-platform** URL to Markdown converter that turns any web page into clean, offline‑readable Markdown with complete media support.

**Cross-platform compatibility:**
- **Linux/macOS**: Native bash scripts with comprehensive media processing  
- **Windows**: Native batch files (.bat) + PowerShell for advanced features
- **Universal**: Go-based html2markdown core works everywhere

## 🌟 What makes this special?

✅ **Complete Media Handling** - Downloads and localizes ALL media types:
- 🖼️ **Images**: jpg, png, gif, webp, svg, bmp, ico, tiff  
- 🎬 **Videos**: mp4, webm, ogg, avi, mov, wmv, flv, mkv
- 🎵 **Audio**: mp3, wav, ogg, flac, aac, m4a, wma, opus
- 📄 **Documents**: pdf, doc, docx, ppt, pptx, xls, xlsx, zip, rar, 7z, tar, gz
- 🔤 **Fonts**: woff, woff2, ttf, otf, eot

✅ **Smart Organization** - Automatic media categorization in subdirectories  
✅ **CSS Selector Support** - Extract specific content using CSS selectors  
✅ **Batch Processing** - Convert multiple URLs efficiently  
✅ **Cross-Platform** - Native scripts for Linux, macOS, and Windows  
✅ **Zero Build Steps** - Ready to use out of the box  

## 🚀 Quick Start

### Linux/macOS
```bash
# 1. Clone and setup
git clone https://github.com/albinxavierdev/url2md.git
cd url2md
chmod +x url2md.sh batch-convert.sh

# 2. Convert a webpage
./url2md.sh https://en.wikipedia.org/wiki/Markdown

# 3. Check results
ls markdown/ && ls media/
```

### Windows  
```cmd
REM 1. Clone and setup
git clone https://github.com/albinxavierdev/url2md.git
cd url2md
setup.bat

REM 2. Convert a webpage  
url2md.bat https://en.wikipedia.org/wiki/Markdown

REM 3. Check results
dir markdown & dir media
```

## 📑 Feature Matrix

| Feature | Linux/macOS | Windows | Description |
|---------|-------------|---------|-------------|
| **URL → Markdown** | ✅ `url2md.sh` | ✅ `url2md.bat` | Single URL conversion |
| **Batch Processing** | ✅ `batch-convert.sh` | ✅ `batch-convert.bat` | Multiple URL processing |
| **Media Download** | ✅ Full support | ✅ PowerShell script | All media types |
| **CSS Selectors** | ✅ Built-in | ✅ Built-in | Target specific content |
| **Auto Setup** | ✅ Manual | ✅ `setup.bat` | Dependency checking |

## 🛠️ Dependencies

**Linux/macOS:**
- `bash` - Shell script runtime
- `wget` - Download manager  
- `html2markdown` - Core converter (included)

**Windows:**
- `PowerShell 3.0+` - Advanced media processing
- `curl` or `PowerShell` - Download capability
- `html2markdown.exe` - Core converter (included)

**Installation:**

*Ubuntu/Debian:*
```bash
sudo apt update && sudo apt install -y wget curl git
```

*Windows:*
```powershell
# Using Chocolatey
choco install curl git

# Or using Scoop  
scoop install curl git
```

## 📚 Usage Examples

### Basic Conversion

**Linux/macOS:**
```bash
# Convert entire page
./url2md.sh https://example.com/article

# Extract specific content
./url2md.sh https://blog.com/post -s ".content"

# Custom output
./url2md.sh https://site.com/page -o "articles" -m "assets"
```

**Windows:**
```cmd
REM Convert entire page
url2md.bat https://example.com/article

REM Extract specific content  
url2md.bat https://blog.com/post -s ".content"

REM Custom output
url2md.bat https://site.com/page -o "articles" -m "assets"
```

### Media Control

```bash
# Download all media types (default)
./url2md.sh https://tutorial.com/guide

# Skip all media  
./url2md.sh https://text-blog.com/post --no-media

# Download specific types only
./url2md.sh https://course.com/lesson --media-types images,videos,documents
```

### Batch Processing

**Create URL list:**
```bash
cat > urls.txt << EOF
https://blog.example.com/post1  
https://tutorial.com/guide
https://docs.example.com/api
EOF
```

**Process all URLs:**

*Linux/macOS:*
```bash
./batch-convert.sh urls.txt -o "batch-articles" -s ".content"
```

*Windows:*
```cmd
batch-convert.bat urls.txt -o "batch-articles" -s ".content"
```

## 🎯 Common Use Cases

### 📰 News Articles
```bash
# BBC articles
./url2md.sh https://www.bbc.com/news/article -s ".story-body"

# TechCrunch  
./url2md.sh https://techcrunch.com/article -s ".article-content"
```

### 📚 Documentation
```bash
# GitHub README
./url2md.sh https://github.com/user/repo -s "#readme"

# API docs with images and examples
./url2md.sh https://docs.python.org/tutorial/ --media-types images,documents
```

### 🎓 Educational Content
```bash
# Wikipedia articles
./url2md.sh https://en.wikipedia.org/wiki/Topic -s "#mw-content-text"

# Course materials with videos
./url2md.sh https://course.com/lesson --media-types images,videos,documents
```

## 📁 Output Structure

```
project/
├── url2md.sh / url2md.bat          # Main converter
├── batch-convert.sh / .bat         # Batch processor  
├── setup.bat                       # Windows setup (Windows only)
├── Process-Media.ps1               # PowerShell media processor (Windows)
├── html2markdown / .exe            # Core converter binary
├── markdown/                       # Converted Markdown files
│   ├── example_com_article.md
│   └── tutorial_guide.md
├── media/                          # Downloaded media (organized by type)
│   ├── images/
│   ├── videos/  
│   ├── audio/
│   ├── documents/
│   └── fonts/
└── batch-converted/                # Batch processing output
```

## ⚙️ Advanced Options

### Command Reference

**Linux/macOS:**
```bash
./url2md.sh [OPTIONS] <URL> [OUTPUT_FILE]

Options:
  -s, --selector CSS    CSS selector for content extraction
  -d, --domain DOMAIN   Domain override for relative URLs
  -m, --media DIR       Media directory (default: media)  
  -o, --output DIR      Output directory (default: markdown)
  --no-media           Skip all media downloads
  --media-types LIST   Comma-separated media types
  --keep-html          Keep HTML for debugging
  -h, --help           Show help
```

**Windows:** Same options, replace `./url2md.sh` with `url2md.bat`

### CSS Selectors for Popular Sites

| Site Type | CSS Selector | Example |
|-----------|--------------|---------|
| WordPress | `.entry-content` | Most blog posts |
| Medium | `article` | Medium articles |
| GitHub | `#readme` | Repository README |
| Wikipedia | `#mw-content-text` | Article content |
| Documentation | `.docs-content` | Many doc sites |

## 🐛 Troubleshooting

### Common Issues

**"Binary not found"**
```bash
# Linux/macOS: Build from source
go build -o html2markdown ./cli

# Windows: Use setup script
setup.bat
```

**"Permission denied"**
```bash
# Linux/macOS: Fix permissions
chmod +x url2md.sh batch-convert.sh

# Windows: Run as Administrator if needed
```

**"Empty output"**
```bash
# Try different CSS selectors
./url2md.sh URL -s "main"
./url2md.sh URL -s ".content"  
./url2md.sh URL -s "article"

# Debug with HTML inspection
./url2md.sh URL --keep-html
```

**"Media not downloading"**
```bash
# Test network connectivity
curl -I https://example.com

# Skip problematic media
./url2md.sh URL --media-types images

# Skip all media
./url2md.sh URL --no-media
```

## 🔧 Development

### File Structure
- `url2md.sh` - Linux/macOS main script
- `url2md.bat` - Windows main script  
- `batch-convert.sh/.bat` - Batch processing
- `Process-Media.ps1` - Windows PowerShell media processor
- `setup.bat` - Windows automated setup
- `html2markdown` - Go binary for HTML→Markdown conversion

### Contributing
1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`  
3. Make changes and test on both Linux and Windows
4. Commit: `git commit -m 'Add new feature'`
5. Push: `git push origin feature/new-feature`
6. Open Pull Request

## 📋 Roadmap

- [ ] **JavaScript Rendering** - Support for SPA/dynamic content using headless browsers
- [ ] **Parallel Processing** - Multi-threaded media downloads  
- [ ] **API Mode** - REST API for conversions
- [ ] **Docker Image** - Containerized deployment
- [ ] **Web UI** - Browser-based interface
- [ ] **Browser Extensions** - Direct conversion from browser
- [ ] **Cloud Storage** - Direct upload to cloud services

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on the excellent [html-to-markdown](https://github.com/JohannesKaufmann/html-to-markdown) Go library
- Cross-platform compatibility for maximum accessibility  
- Community-driven development and testing

---

**Made with ❤️ for the developer community**

Convert any webpage to Markdown, anywhere, anytime! 🚀