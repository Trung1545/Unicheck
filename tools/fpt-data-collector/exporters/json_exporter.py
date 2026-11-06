import json
from pathlib import Path
from models import MasterDataset

class JsonExporter:
    @staticmethod
    def export(dataset: MasterDataset, output_path: str):
        path = Path(output_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        with open(path, "w", encoding="utf-8") as f:
            f.write(dataset.model_dump_json(indent=2))
        print(f"[EXPORTER] Master dataset exported to JSON: {path} ({path.stat().st_size} bytes)")
