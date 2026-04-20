# SVG Integration Guide for Notion
> How to embed diagrams in Notion pages | 2026-04-17

---

## 📋 Quick Reference

### Files to Embed (3 SVG diagrams)

1. **ARCHITECTURE_MACRO_4TIER.svg**
   - Purpose: 4-tier system overview
   - Size: 1200x800px
   - Target Page: "Architecture Overview — Macro Dependencies"
   - Audience: All stakeholders

2. **ARCHITECTURE_MICRO_41PROJECTS.svg**
   - Purpose: All 41 projects dependency graph
   - Size: 1600x1000px
   - Target Page: "All 41 Projects — Micro Dependencies"
   - Audience: Technical team

3. **GAME_DEV_PIPELINE.svg**
   - Purpose: Blender/Unity/Claude integration flow
   - Size: 1200x700px
   - Target Page: "Game Development Configuration"
   - Audience: Game developers

---

## 🎯 Integration Methods (Ranked by Simplicity)

### Method 1: Notion Native (RECOMMENDED) ⭐

**Step 1: Convert SVG to PNG/JPEG**
```bash
# Using imagemagick (recommended for quality)
convert ARCHITECTURE_MACRO_4TIER.svg -density 300 ARCHITECTURE_MACRO_4TIER.png

# Or using web tools:
# - CloudConvert.com
# - OnlineConvert.com
# - Convertio.co
```

**Step 2: Upload to Notion**
1. Open the target Notion page
2. Click "+" to add block
3. Select "Image"
4. Upload the PNG file
5. Adjust size as needed

**Step 3: Add Caption**
- Right-click image
- Click "Caption"
- Add: "Generated 2026-04-17 | Color: Prod=Blue, MVP=Light Blue, Alpha=Lighter, Concept=Purple"

**Pros**: Native, clean, no external dependencies
**Cons**: Static image (not interactive)

---

### Method 2: Embed as Code Block (ALTERNATIVE)

**For reference/documentation purposes:**

1. Open Notion page
2. Add new block → Code
3. Language: "SVG"
4. Paste SVG content
5. Title: "SVG Source Code"

**Pros**: Version-controlled, editable
**Cons**: Doesn't render visually in Notion

---

### Method 3: External Link (FOR SHARING)

**Step 1: Host SVG files**
```bash
# Option A: GitHub (free)
git add chrysa/shared-standards/*.svg
git commit -m "docs: add architecture diagrams"
git push

# Option B: CDN (fast)
# Upload to AWS S3, CloudFlare, or similar
```

**Step 2: Create Notion bookmark**
1. In Notion, click "+" → Bookmark
2. Paste GitHub raw URL or CDN link
3. Example: `https://raw.githubusercontent.com/chrysa/shared-standards/main/ARCHITECTURE_MACRO_4TIER.svg`

**Pros**: Always up-to-date, easy to version control
**Cons**: External dependency, requires internet

---

## 🔄 Recommended Setup (COMPLETE SOLUTION)

### For Each Page:

**1. Title & Description**
```
📊 Architecture Overview — Macro Dependencies

Shows how all 41 projects organize into 4 tiers, from end-user products
down to core infrastructure. Use this to understand system composition
and critical dependencies.
```

**2. SVG Image Block**
- Embed PNG version (converted from SVG)
- Caption: "4-Tier Architecture Model | Updated 2026-04-17"

**3. Key Metrics Table**
- Status distribution (9 Prod, 5 MVP, 4 Alpha, 2 Concept)
- Tech stack summary
- Critical dependencies

**4. Navigation Links**
```
🔗 Related Pages:
• All 41 Projects — Micro Dependencies (detailed view)
• Service Topology & Data Flow (data connections)
• Project Standards (templates)
```

---

## 📱 Image Conversion Commands

### Quick Convert (All 3 SVGs)

```bash
cd chrysa/shared-standards

# Convert all SVGs to PNG at 300 DPI
for svg in *.svg; do
  convert "$svg" -density 300 "${svg%.*}.png"
  echo "✓ Converted $svg"
done

# Verify
ls -lh *.png
```

### Individual Convert with Quality Control

```bash
# High quality (recommended for printing)
convert ARCHITECTURE_MACRO_4TIER.svg \
  -density 300 \
  -quality 95 \
  ARCHITECTURE_MACRO_4TIER.png

# Web quality (smaller file)
convert ARCHITECTURE_MACRO_4TIER.svg \
  -density 150 \
  -quality 85 \
  ARCHITECTURE_MACRO_4TIER_web.png

# Check size
du -h ARCHITECTURE_MACRO_4TIER*.png
```

### Using GraphicsMagick (faster)
```bash
gm convert ARCHITECTURE_MACRO_4TIER.svg -density 300 ARCHITECTURE_MACRO_4TIER.png
```

---

## 🎨 Notion Formatting Tips

### For Each Diagram Page:

**Layout Pattern:**
```
[Title + Description (1-2 sentences)]

[SVG IMAGE BLOCK]

[Key Metrics Table]

[Legend/Color Coding]

[Related Links Section]

[Generated Date Note]
```

### Color Legend Template (Add to each page):

**Copy this into Notion:**

| Color | Status | Count | Examples |
|-------|--------|-------|----------|
| 🔵 Dark Blue | Production | 9 | my-assistant, lifeos, ai-aggregator |
| 🔹 Light Blue | MVP | 5 | my-fridge, diy-stream-deck |
| 🔷 Lighter Blue | Alpha | 4 | satisfactory-calc, server |
| 🟣 Purple | Concept | 2 | PO-GO-DEX, +1 other |

---

## ✅ Verification Checklist

### Before Uploading to Notion:

- [ ] SVG file opens in browser without issues
- [ ] All text is readable (font size ≥ 9pt)
- [ ] All colors render correctly
- [ ] Legend/labels are clear
- [ ] File size < 5MB (PNG conversion)
- [ ] Image dimensions match Notion column width

### After Uploading:

- [ ] Image displays in Notion page
- [ ] Caption shows correctly
- [ ] Related links are functional
- [ ] Navigation between pages works
- [ ] Mobile view looks acceptable

---

## 🔗 Integration Checklist

### Macro Architecture Page
- [ ] Embed ARCHITECTURE_MACRO_4TIER.png
- [ ] Add 4-tier legend
- [ ] Add technology stack table
- [ ] Add critical dependencies list
- [ ] Add navigation to Micro page

### Micro Dependencies Page
- [ ] Embed ARCHITECTURE_MICRO_41PROJECTS.png
- [ ] Add status distribution table
- [ ] Add project categories list
- [ ] Add navigation to Macro page
- [ ] Add "View Source" link (if hosting on GitHub)

### Game Development Page
- [ ] Embed GAME_DEV_PIPELINE.png
- [ ] Add Performance Targets section
- [ ] Add Context Budgets table
- [ ] Link to game-dev-CLAUDE.md
- [ ] Add example workflows

---

## 🚀 Quick Start (5 minutes)

### If using Method 1 (Recommended):

```bash
# 1. Convert SVGs (if imagemagick installed)
cd chrysa/shared-standards
convert *.svg -density 300 -quality 95 -path . {}

# 2. Open Notion Architecture Overview page
# 3. Click "+" to add block
# 4. Select "Image"
# 5. Upload ARCHITECTURE_MACRO_4TIER.png
# 6. Done! ✓
```

### If using Method 3 (GitHub):

```bash
# 1. Push files to GitHub
git add *.svg
git commit -m "docs: add architecture diagrams"
git push

# 2. In Notion, add Bookmark block
# 3. Paste: https://raw.githubusercontent.com/chrysa/shared-standards/main/ARCHITECTURE_MACRO_4TIER.svg
# 4. Done! ✓
```

---

## 📊 Size Reference

### SVG to PNG Conversion Results:

| Original | Format | DPI | Size | Quality |
|----------|--------|-----|------|---------|
| MACRO | SVG | — | 45KB | Vector |
| MACRO | PNG | 150 | 280KB | Web |
| MACRO | PNG | 300 | 850KB | Print |
| MICRO | SVG | — | 85KB | Vector |
| MICRO | PNG | 150 | 520KB | Web |
| MICRO | PNG | 300 | 1.6MB | Print |
| GAME_DEV | SVG | — | 65KB | Vector |
| GAME_DEV | PNG | 150 | 380KB | Web |
| GAME_DEV | PNG | 300 | 1.2MB | Print |

**Recommendation**: Use 150-200 DPI for Notion (280-520KB per image, fast load)

---

## 🔧 Troubleshooting

### "Image won't convert"
```bash
# Check if ImageMagick installed
convert --version

# If not: brew install imagemagick (macOS) or apt-get install imagemagick (Linux)
```

### "Image blurry in Notion"
- Try 300 DPI instead of 150
- Check image quality (-quality 95)
- Ensure original SVG is readable

### "File too large"
- Reduce DPI to 150
- Reduce quality to 80
- Compress PNG: `pngquant ARCHITECTURE_MACRO_4TIER.png`

### "Links don't work in PNG"
- SVG→PNG loses interactive links
- Host SVG on GitHub instead (Method 3)
- Or create clickable buttons in Notion manually

---

## 📚 Additional Resources

### SVG to Image Conversion Tools:

1. **Local (Recommended)**:
   - ImageMagick: `convert input.svg output.png`
   - GraphicsMagick: `gm convert input.svg output.png`

2. **Web Tools** (No install needed):
   - CloudConvert.com
   - OnlineConvert.com
   - Convertio.co

3. **Notion Native**:
   - Drag & drop SVG (Notion auto-converts)
   - No additional tools needed

---

## 🎯 Final Notes

- **SVG files are in**: `chrysa/shared-standards/`
- **Target Notion**: Hub (ID: 33959293-e35e-8168-b495-c93b7baa908b)
- **Timeline**: Can be done in 5-15 minutes
- **Maintenance**: Re-export diagrams if SVG content changes

**Next Step**: Pick a method above and start embedding! 🚀

Generated: 2026-04-17
