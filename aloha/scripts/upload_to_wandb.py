#!/usr/bin/env python3
"""
Upload all training and evaluation results to Weights & Biases
"""

import json
import os
from pathlib import Path
import wandb

# Model configurations to upload
MODELS = [
    {
        "name": "ACT-80K",
        "policy": "ACT",
        "steps": 80000,
        "epochs": 256,
        "use_rabc": False,
        "training_metrics": "packsarm/outputs/act_aloha_80k/training_metrics.jsonl",
        "eval_info": "packsarm/outputs/eval_act_80k/eval_info.json",
        "config": "packsarm/outputs/act_aloha_80k/checkpoints/last/pretrained_model/train_config.json"
    },
    {
        "name": "ACT-20K",
        "policy": "ACT",
        "steps": 20000,
        "epochs": 64,
        "use_rabc": False,
        "training_metrics": "packsarm/outputs/act_aloha_20k/training_metrics.jsonl",
        "eval_info": "packsarm/outputs/eval_act_20k/eval_info.json",
        "config": "packsarm/outputs/act_aloha_20k/checkpoints/last/pretrained_model/train_config.json"
    },
    {
        "name": "RA-BC-Diffusion-80K",
        "policy": "DiffusionPolicy",
        "steps": 80000,
        "epochs": 256,
        "use_rabc": True,
        "training_metrics": "packsarm/outputs/dp_aloha_rabc_nocrop_80k/training_metrics.jsonl",
        "eval_info": None,  # Not evaluated yet
        "config": None
    },
    {
        "name": "RA-BC-Diffusion-10K",
        "policy": "DiffusionPolicy",
        "steps": 10000,
        "epochs": 32,
        "use_rabc": True,
        "training_metrics": None,  # Need to find this
        "eval_info": "packsarm/outputs/eval_rabc_nocrop_10k/eval_info.json",
        "config": None
    },
    {
        "name": "Vanilla-BC-Diffusion-10K",
        "policy": "DiffusionPolicy",
        "steps": 10000,
        "epochs": 32,
        "use_rabc": False,
        "training_metrics": "packsarm/outputs/dp_aloha_bc_nocrop_10k/training_metrics.jsonl",
        "eval_info": "packsarm/outputs/eval_bc_nocrop_10k/eval_info.json",
        "config": "packsarm/outputs/dp_aloha_bc_nocrop_10k/checkpoints/last/pretrained_model/train_config.json"
    }
]

def load_jsonl(filepath):
    """Load JSONL file and return list of dictionaries"""
    data = []
    with open(filepath, 'r') as f:
        for line in f:
            data.append(json.loads(line))
    return data

def load_json(filepath):
    """Load JSON file"""
    with open(filepath, 'r') as f:
        return json.load(f)

def upload_model(model_config, project_name="packsarm-aloha-comparison"):
    """Upload a single model's training and eval data to wandb"""

    print(f"\n{'='*60}")
    print(f"Uploading {model_config['name']}...")
    print(f"{'='*60}")

    # Initialize wandb run
    run = wandb.init(
        project=project_name,
        name=model_config["name"],
        config={
            "policy": model_config["policy"],
            "steps": model_config["steps"],
            "epochs": model_config["epochs"],
            "use_rabc": model_config["use_rabc"],
            "dataset": "lerobot/aloha_sim_transfer_cube_human",
            "task": "AlohaTransferCube-v0"
        },
        reinit=True
    )

    # Upload training metrics
    if model_config["training_metrics"] and os.path.exists(model_config["training_metrics"]):
        print(f"Uploading training metrics from {model_config['training_metrics']}")
        training_data = load_jsonl(model_config["training_metrics"])

        for entry in training_data:
            step = entry.get("steps", 0)

            # Log all training metrics
            log_dict = {"train/step": step}
            for key, value in entry.items():
                if key != "steps" and isinstance(value, (int, float)):
                    log_dict[f"train/{key}"] = value

            wandb.log(log_dict, step=step)

        print(f"  ✓ Logged {len(training_data)} training steps")
    else:
        print(f"  ⚠ No training metrics found")

    # Upload evaluation results
    if model_config["eval_info"] and os.path.exists(model_config["eval_info"]):
        print(f"Uploading eval results from {model_config['eval_info']}")
        eval_data = load_json(model_config["eval_info"])

        # Extract overall metrics
        if "aggregated" in eval_data:
            agg = eval_data["aggregated"]["overall"]

            wandb.log({
                "eval/success_rate": agg.get("pc_success", 0),
                "eval/avg_sum_reward": agg.get("avg_sum_reward", 0),
                "eval/avg_max_reward": agg.get("avg_max_reward", 0),
                "eval/n_episodes": agg.get("n_episodes", 0),
                "eval/avg_ep_time_s": agg.get("eval_ep_s", 0)
            })

            print(f"  ✓ Success Rate: {agg.get('pc_success', 0)}%")
            print(f"  ✓ Avg Sum Reward: {agg.get('avg_sum_reward', 0):.2f}")

        # Upload episode-by-episode results
        if "episodes" in eval_data:
            episodes_data = []
            for ep_idx, ep_data in eval_data["episodes"].items():
                episodes_data.append({
                    "episode": int(ep_idx),
                    "success": ep_data.get("success", False),
                    "sum_reward": ep_data.get("sum_reward", 0),
                    "max_reward": ep_data.get("max_reward", 0)
                })

            # Create wandb table
            table = wandb.Table(
                columns=["episode", "success", "sum_reward", "max_reward"],
                data=[[ep["episode"], ep["success"], ep["sum_reward"], ep["max_reward"]]
                      for ep in episodes_data]
            )
            wandb.log({"eval/episodes": table})
            print(f"  ✓ Logged {len(episodes_data)} episode results")
    else:
        print(f"  ⚠ No eval results found")

    # Upload config if available
    if model_config["config"] and os.path.exists(model_config["config"]):
        print(f"Uploading config from {model_config['config']}")
        config_data = load_json(model_config["config"])
        wandb.config.update({"full_config": config_data})
        print(f"  ✓ Config uploaded")

    # Finish the run
    wandb.finish()
    print(f"✓ Completed {model_config['name']}\n")

def create_comparison_table(project_name="packsarm-aloha-comparison"):
    """Create a comparison table across all models"""

    print(f"\n{'='*60}")
    print(f"Creating comparison table...")
    print(f"{'='*60}")

    run = wandb.init(
        project=project_name,
        name="Model-Comparison",
        job_type="comparison",
        reinit=True
    )

    # Gather all results
    results = []
    for model_config in MODELS:
        if model_config["eval_info"] and os.path.exists(model_config["eval_info"]):
            eval_data = load_json(model_config["eval_info"])
            if "aggregated" in eval_data:
                agg = eval_data["aggregated"]["overall"]
                results.append({
                    "Model": model_config["name"],
                    "Policy": model_config["policy"],
                    "Steps": model_config["steps"],
                    "Epochs": model_config["epochs"],
                    "RA-BC": "✓" if model_config["use_rabc"] else "✗",
                    "Success Rate (%)": agg.get("pc_success", 0),
                    "Avg Sum Reward": round(agg.get("avg_sum_reward", 0), 2),
                    "Avg Max Reward": round(agg.get("avg_max_reward", 0), 2)
                })

    # Sort by success rate
    results.sort(key=lambda x: x["Success Rate (%)"], reverse=True)

    # Create wandb table
    table = wandb.Table(
        columns=list(results[0].keys()),
        data=[list(r.values()) for r in results]
    )

    wandb.log({"comparison/all_models": table})

    # Also log as summary
    for result in results:
        print(f"  {result['Model']}: {result['Success Rate (%)']}%")

    wandb.finish()
    print(f"✓ Comparison table created\n")

def main():
    print(f"\n{'='*60}")
    print(f"UPLOADING PACKSARM RESULTS TO WEIGHTS & BIASES")
    print(f"{'='*60}")

    # Try to login with existing credentials
    try:
        wandb.login(relogin=False)
        print("✓ Logged into W&B successfully")
    except Exception as e:
        print(f"\n⚠ Could not login to W&B: {e}")
        print("Please run: wandb login")
        return

    project_name = "packsarm-aloha-comparison"

    # Upload each model
    for model_config in MODELS:
        try:
            upload_model(model_config, project_name)
        except Exception as e:
            print(f"✗ Error uploading {model_config['name']}: {e}")

    # Create comparison table
    try:
        create_comparison_table(project_name)
    except Exception as e:
        print(f"✗ Error creating comparison table: {e}")

    print(f"\n{'='*60}")
    print(f"✓ ALL UPLOADS COMPLETE!")
    print(f"View at: https://wandb.ai/<your-username>/{project_name}")
    print(f"{'='*60}\n")

if __name__ == "__main__":
    main()
