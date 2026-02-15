# Git Workflow - Organizing Dual Project Repository

Step-by-step guide to organize and push both projects to GitHub.

---

## 📋 Current Situation

You have:
- ✅ Existing GitHub repo: https://github.com/Dimios45/packsarm
- ✅ Previous **packing** work (WBCD-Packing-RoboTwin)
- ✅ New **ALOHA** work (transfer cube experiments)

Goal: Organize both cleanly in the same repository

---

## 🚀 Step-by-Step Workflow

### Step 1: Backup Current State

```bash
cd /home/sra/packsarm

# Create backup of current work
cp -r . ../packsarm_backup_$(date +%Y%m%d)

echo "✓ Backup created"
```

### Step 2: Pull Latest from GitHub

```bash
# Make sure you're in the repo
cd /home/sra/packsarm

# Pull any changes from GitHub
git pull origin main
```

### Step 3: Organize Directory Structure

```bash
# Run the organization script
./organize_dual_repo.sh
```

This creates:
```
packsarm/
├── packing/     # Your existing packing work
└── aloha/       # Your new ALOHA work
```

### Step 4: Move Existing Files

Move your existing packing-related files to the `packing/` directory:

```bash
# If you have existing packing scripts/configs, move them
# Example (adjust paths as needed):
mv WBCD-Packing-RoboTwin packing/ 2>/dev/null || true
mv scripts/train_policy*.sh packing/scripts/ 2>/dev/null || true
mv config/sarm_packing.yaml packing/config/ 2>/dev/null || true

# Keep the main lerobot directory at root level (shared by both projects)
# Don't move it
```

### Step 5: Update Main README

```bash
# Replace old README with new dual-project README
mv README_NEW.md README.md
```

### Step 6: Review Changes

```bash
# Check what's changed
git status

# Review the new structure
tree -L 2 -d
```

Expected output:
```
.
├── aloha/
│   ├── configs/
│   ├── results/
│   └── scripts/
├── lerobot/
│   └── src/
└── packing/
    ├── config/
    ├── scripts/
    └── WBCD-Packing-RoboTwin/
```

### Step 7: Stage Changes

```bash
# Add new directories
git add aloha/
git add packing/

# Add updated main README
git add README.md

# Add gitignore if not already there
git add .gitignore

# Add requirements
git add requirements.txt

# Check what will be committed
git status
```

### Step 8: Commit Changes

```bash
git commit -m "Organize repository: Separate packing and ALOHA projects

Major changes:
- Created packing/ directory for WBCD-Packing-RoboTwin work
  - Previous best: 90% success with v2b (pretrained ResNet18)
  - Fixed vision grounding with crop_shape=[224,224]
  - Documented RA-BC bugs and fixes

- Created aloha/ directory for ALOHA transfer cube work
  - RA-BC achieves 3x improvement (24% vs 8% vanilla BC)
  - ACT baseline: 68% success (SOTA)
  - Complete experimental documentation
  - Training configs for DiffusionPolicy, ACT, SARM

- Updated main README to cover both projects
- Added detailed project-specific READMEs
- Organized scripts, configs, and results

Both projects validate SARM's effectiveness for robot learning."
```

### Step 9: Push to GitHub

```bash
git push origin main
```

### Step 10: Verify on GitHub

Visit: https://github.com/Dimios45/packsarm

You should see:
- ✅ Clean dual-project structure
- ✅ Main README showing both projects
- ✅ Separate READMEs for each project
- ✅ All scripts organized

---

## 📁 Final Repository Structure

```
packsarm/
├── README.md                          # Main (covers both projects)
├── .gitignore                         # Excludes large files
├── requirements.txt                   # Shared dependencies
├── GIT_WORKFLOW.md                    # This file
│
├── packing/                           # WBCD-Packing-RoboTwin project
│   ├── README.md                      # Packing docs (90% success)
│   ├── scripts/
│   │   ├── train_policy_v2.sh
│   │   ├── train_policy_v2b.sh        # Best (pretrained)
│   │   └── train_policy_v2_rabc.sh
│   ├── config/
│   │   └── sarm_packing.yaml
│   ├── WBCD-Packing-RoboTwin/         # Environment code
│   └── outputs/                       # Training results (gitignored)
│
├── aloha/                             # ALOHA transfer cube project
│   ├── README.md                      # ALOHA docs (detailed)
│   ├── RESULTS.md                     # Experimental findings
│   ├── scripts/
│   │   ├── train_sarm_aloha.sh
│   │   ├── train_dp_aloha_rabc_nocrop.sh
│   │   ├── train_dp_aloha_bc_nocrop.sh
│   │   ├── train_act_aloha.sh
│   │   ├── eval_dp_aloha.sh
│   │   └── upload_to_wandb.py
│   ├── configs/
│   │   ├── sarm/
│   │   ├── diffusion/
│   │   └── act/
│   └── results/
│       ├── training/                  # .jsonl files
│       ├── evaluation/                # .json files
│       └── comparison/
│
└── lerobot/                           # Shared LeRobot library
    └── src/
        └── lerobot/
            ├── policies/sarm/
            └── data_processing/sarm_annotations/
```

---

## 🎨 Making it Look Professional

### Add GitHub Topics

On GitHub repository page → Settings → Topics:
- `robot-learning`
- `behavior-cloning`
- `diffusion-policy`
- `reward-modeling`
- `manipulation`
- `sarm`
- `aloha`
- `robotwin`

### Update Repository Description

```
Two robot manipulation projects with SARM: 90% success on packing (RoboTwin) and 3x BC improvement on ALOHA
```

### Create Releases

Tag important milestones:

```bash
# Tag the packing v2b success
git tag -a packing-v2b -m "Packing: 90% success with pretrained ResNet18"

# Tag the ALOHA experiments
git tag -a aloha-v1 -m "ALOHA: RA-BC 3x improvement, ACT baseline"

# Push tags
git push origin --tags
```

### Add GitHub Actions (Optional)

Create `.github/workflows/test.yml` for CI/CD

---

## 🔄 Future Updates

### Adding New Experiments

```bash
# For packing experiments
cd packing
# ... do work ...
git add .
git commit -m "packing: Add new experiment X"
git push

# For ALOHA experiments
cd aloha
# ... do work ...
git add .
git commit -m "aloha: Add RA-BC 80K results"
git push
```

### Keeping Projects Separate

- Use **commit prefixes**: `packing:` or `aloha:`
- Keep configs/scripts in respective directories
- Shared code stays in `lerobot/`

---

## 📊 Upload to W&B

After organizing:

```bash
cd aloha
python scripts/upload_to_wandb.py
```

This creates: `https://wandb.ai/dimios45/packsarm-aloha-comparison`

---

## ✅ Checklist

Before pushing:
- [ ] Backup created
- [ ] Git pull completed
- [ ] Files organized (packing/ and aloha/)
- [ ] Main README updated
- [ ] Project READMEs in place
- [ ] .gitignore configured
- [ ] Changes committed with good message
- [ ] Pushed to GitHub
- [ ] Verified on GitHub web
- [ ] W&B upload completed (optional)
- [ ] Repository description updated
- [ ] Topics added

---

## 🆘 Troubleshooting

### "Files too large to push"

If checkpoints are too big:

```bash
# Add to .gitignore
echo "*.safetensors" >> .gitignore
echo "*.pth" >> .gitignore
git rm --cached **/*.safetensors
git commit -m "Remove large checkpoint files"
```

Use Git LFS or W&B Artifacts for model weights.

### "Merge conflicts"

```bash
# If you get conflicts after pull
git status  # See conflicting files
# Edit files to resolve <<<<< ===== >>>>> markers
git add .
git commit -m "Resolve merge conflicts"
git push
```

### "Want to undo last commit"

```bash
# Undo commit but keep changes
git reset --soft HEAD~1

# Undo commit and changes (CAREFUL!)
git reset --hard HEAD~1
```

---

## 🎉 You're Done!

Your repository now has:
- ✅ Two well-documented projects
- ✅ Clean organization
- ✅ Complete experimental results
- ✅ Reproducible scripts
- ✅ Professional presentation

Ready to share with professors, labs, or publish! 🚀
