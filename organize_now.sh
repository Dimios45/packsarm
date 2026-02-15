#!/bin/bash
# Custom organization for current packsarm state
set -e

echo "============================================================"
echo "Organizing PACKSARM repository (current structure)"
echo "============================================================"

# Move WBCD-Packing-RoboTwin to packing/
if [ -d "WBCD-Packing-RoboTwin" ]; then
    echo "Moving WBCD-Packing-RoboTwin to packing/..."
    mv WBCD-Packing-RoboTwin packing/ 2>/dev/null || cp -r WBCD-Packing-RoboTwin packing/
    echo "  ✓ Moved"
fi

# Move RoboTwin to packing/
if [ -d "RoboTwin" ]; then
    echo "Moving RoboTwin to packing/..."
    mv RoboTwin packing/ 2>/dev/null || cp -r RoboTwin packing/
    echo "  ✓ Moved"
fi

# Move packing-specific scripts if they exist in root
if [ -f "run_data_efficiency.sh" ]; then
    echo "Moving packing scripts..."
    mkdir -p packing/scripts
    mv run_data_efficiency.sh packing/scripts/ 2>/dev/null || cp run_data_efficiency.sh packing/scripts/
    echo "  ✓ Moved run_data_efficiency.sh"
fi

# Move packsarm outputs to aloha (these are ALOHA outputs)
if [ -d "packsarm/outputs" ]; then
    echo "Moving ALOHA outputs from packsarm/outputs to aloha/..."
    mkdir -p aloha/outputs
    cp -r packsarm/outputs/* aloha/outputs/ 2>/dev/null || true
    echo "  ✓ Copied to aloha/outputs"
fi

# Move outputs directory if it contains packing stuff
if [ -d "outputs" ]; then
    echo "Checking outputs directory..."
    # Check if it has packing-related content
    if ls outputs/ | grep -q "policy"; then
        echo "Moving to packing/outputs..."
        mkdir -p packing/outputs
        cp -r outputs/* packing/outputs/ 2>/dev/null || true
        echo "  ✓ Copied to packing/outputs"
    fi
fi

# Update main README
if [ -f "README_NEW.md" ]; then
    echo "Updating main README..."
    mv README.md README_OLD.md 2>/dev/null || true
    mv README_NEW.md README.md
    echo "  ✓ README updated (old saved as README_OLD.md)"
fi

# Move RESULTS.md to aloha/
if [ -f "RESULTS.md" ] && [ ! -f "aloha/RESULTS.md" ]; then
    echo "Moving RESULTS.md to aloha/..."
    mv RESULTS.md aloha/
    echo "  ✓ Moved"
fi

# Create .gitkeep for empty directories
find packing aloha -type d -empty -exec touch {}/.gitkeep \; 2>/dev/null || true

echo ""
echo "============================================================"
echo "✓ Organization complete!"
echo "============================================================"
echo ""
echo "Structure:"
echo "  packing/"
echo "    ├── WBCD-Packing-RoboTwin/"
echo "    ├── RoboTwin/"
echo "    ├── scripts/"
echo "    ├── outputs/"
echo "    └── README.md"
echo ""
echo "  aloha/"
echo "    ├── outputs/"
echo "    ├── scripts/"
echo "    ├── configs/"
echo "    ├── results/"
echo "    ├── README.md"
echo "    └── RESULTS.md"
echo ""
echo "  lerobot/ (shared)"
echo ""
echo "Next steps:"
echo "  1. Review the organization:"
echo "     ls -la packing/ aloha/"
echo ""
echo "  2. Add to git:"
echo "     git add ."
echo ""
echo "  3. Commit:"
echo "     git commit -m 'Organize: Separate packing and ALOHA projects'"
echo ""
echo "  4. Push:"
echo "     git push origin main"
