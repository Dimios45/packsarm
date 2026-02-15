#!/bin/bash
# Final cleanup for packsarm repository
set -e

echo "============================================================"
echo "Final cleanup and organization"
echo "============================================================"

# Move ALOHA scripts from packsarm/scripts to aloha/scripts
if [ -d "packsarm/scripts" ]; then
    echo "Moving ALOHA scripts to aloha/scripts..."
    mkdir -p aloha/scripts
    cp -r packsarm/scripts/* aloha/scripts/ 2>/dev/null || true
    echo "  ✓ Moved"
fi

# Move ALOHA configs if they exist
if [ -d "packsarm/config" ]; then
    echo "Moving configs to aloha/configs..."
    mkdir -p aloha/configs
    cp -r packsarm/config/* aloha/configs/ 2>/dev/null || true
    echo "  ✓ Moved"
fi

# Remove duplicate RESULTS.md from root (keep only in aloha/)
if [ -f "RESULTS.md" ] && [ -f "aloha/RESULTS.md" ]; then
    echo "Removing duplicate RESULTS.md from root..."
    rm RESULTS.md
    echo "  ✓ Removed (kept in aloha/)"
fi

# Update .gitignore to exclude environments and large files
echo "Updating .gitignore..."
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
*.egg-info/

# Virtual Environments (exclude all env directories)
sarm-env/
robotwin-env/
venv/
env/
ENV/

# IDE
.vscode/
.idea/
*.swp

# Model Checkpoints (too large)
*.safetensors
*.bin
*.pth
*.pt
*.ckpt

# Outputs (keep structure, ignore large files)
outputs/*/checkpoints/
packsarm/outputs/
*.mp4
*.avi

# Cache
.cache/
*.parquet
wandb/

# Logs
*.log
logs/

# OS
.DS_Store
Thumbs.db

# Keep directory structure
!.gitkeep
EOF
echo "  ✓ Updated"

# Create summary of what's where
echo ""
echo "============================================================"
echo "✓ Cleanup complete!"
echo "============================================================"
echo ""
echo "Final structure:"
echo ""
echo "📦 packing/ (WBCD-Packing-RoboTwin)"
echo "   ├── WBCD-Packing-RoboTwin/"
echo "   ├── RoboTwin/"
echo "   ├── scripts/"
echo "   └── README.md"
echo ""
echo "📦 aloha/ (Transfer cube)"
echo "   ├── scripts/          ← All ALOHA training/eval scripts"
echo "   ├── configs/          ← Model configs"
echo "   ├── outputs/          ← Training outputs"
echo "   ├── README.md         ← Detailed docs"
echo "   └── RESULTS.md        ← Experimental findings"
echo ""
echo "📦 lerobot/ (Shared library)"
echo ""
echo "🗑️  Can be removed (already copied):"
echo "   - packsarm/ (old directory)"
echo "   - outputs/ (if empty or duplicates)"
echo ""
echo "Next: Review and commit!"
