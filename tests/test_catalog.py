"""Regression checks for the catalog generator; no plugin runtimes are started."""

import hashlib
import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


class CatalogTests(unittest.TestCase):
    source = Path(__file__).resolve().parents[1]

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="catalog-tests-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.registry = json.loads((self.source / "plugins.json").read_text(encoding="utf-8"))
        shutil.copytree(self.source / "assets", self.root / "assets")
        self.save_registry()

    def save_registry(self):
        (self.root / "plugins.json").write_text(
            json.dumps(self.registry, indent=2, ensure_ascii=False) + "\n", encoding="utf-8"
        )

    def run_generator(self, mode="Check", ok=True):
        result = subprocess.run(
            [shutil.which("pwsh") or "pwsh", "-NoProfile", "-File",
             str(self.source / "scripts/generate-marketplace.ps1"),
             "-" + mode, "-Root", str(self.root)],
            capture_output=True, text=True, encoding="utf-8", timeout=30,
        )
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual(result.stdout.strip(), "")
        else:
            self.assertNotEqual(result.returncode, 0)
        return result.stdout + result.stderr

    def snapshot(self):
        return {str(path.relative_to(self.root)): hashlib.sha256(path.read_bytes()).hexdigest()
                for path in self.root.rglob("*") if path.is_file()}

    def test_generation_is_deterministic_and_check_is_read_only(self):
        self.run_generator("Write")
        first = self.snapshot()
        self.run_generator()
        self.assertEqual(first, self.snapshot())
        self.run_generator("Write")
        self.assertEqual(first, self.snapshot())

    def test_check_reports_drift_without_writing(self):
        before = self.snapshot()
        self.assertIn("stale", self.run_generator(ok=False))
        self.assertEqual(before, self.snapshot())

    def test_groups_and_ids_are_preserved(self):
        self.run_generator("Write")
        codex = json.loads((self.root / ".agents/plugins/marketplace.json").read_text(encoding="utf-8"))
        claude = json.loads((self.root / ".claude-plugin/marketplace.json").read_text(encoding="utf-8"))
        kimi = json.loads((self.root / "kimi-marketplace.json").read_text(encoding="utf-8"))
        ordered = sorted(self.registry["plugins"], key=lambda p: (p["maintenance"] != "maintained", p["displayName"].lower()))
        expected = [p["name"] for p in ordered]
        self.assertEqual([p["name"] for p in codex["plugins"]], expected)
        self.assertEqual([p["name"] for p in claude["plugins"]], expected)
        self.assertEqual([p["id"] for p in kimi["plugins"]],
                         [p["name"] for p in ordered if "kimi-code" in p["providers"]])
        self.assertEqual(codex["name"], "0langas-plugins")
        self.assertEqual(claude["name"], "0langas-plugins")
        self.assertEqual(codex["interface"]["displayName"], "0langa\u2019s Plugins")
        self.assertEqual([p["category"] for p in codex["plugins"]], ["Maintained"] * 4 + ["Dormant"] * 5)
        for plugin in claude["plugins"]:
            if plugin["category"] == "Dormant":
                self.assertTrue(plugin["description"].startswith("Dormant:"))
        generated = json.loads((self.root / "plugins.json").read_text(encoding="utf-8"))
        for plugin in generated["plugins"]:
            self.assertEqual(plugin["installCommands"]["codex"], f"codex plugin add {plugin['name']}@0langas-plugins")

    def test_duplicate_plugin_rejected(self):
        self.registry["plugins"].append(dict(self.registry["plugins"][0]))
        self.save_registry()
        self.assertIn("Duplicate plugin ID", self.run_generator("Write", ok=False))

    def test_invalid_maintenance_rejected(self):
        self.registry["plugins"][0]["maintenance"] = "forgotten"
        self.save_registry()
        self.assertIn("maintenance status", self.run_generator("Write", ok=False))

    def test_wrong_provider_support_rejected(self):
        self.registry["plugins"][0]["providerSupport"]["kimi-code"] = "maintained"
        self.save_registry()
        self.assertIn("support status", self.run_generator("Write", ok=False))

    def test_missing_asset_rejected(self):
        self.registry["plugins"][0]["assets"]["icon"] = "assets/missing.png"
        self.save_registry()
        self.assertIn("asset is missing", self.run_generator("Write", ok=False))

    def test_asset_outside_checkout_rejected(self):
        self.registry["plugins"][0]["assets"]["icon"] = "../outside.png"
        self.save_registry()
        self.assertIn("inside the marketplace", self.run_generator("Write", ok=False))

    def test_inconsistent_pin_rejected(self):
        for key, value in (("sha", "main"), ("ref", "v99.0.0")):
            with self.subTest(key=key):
                original = self.registry["plugins"][0]["source"][key]
                self.registry["plugins"][0]["source"][key] = value
                self.save_registry()
                self.assertIn("release pin", self.run_generator("Write", ok=False))
                self.registry["plugins"][0]["source"][key] = original

    def test_orphan_catalog_entry_rejected(self):
        self.run_generator("Write")
        path = self.root / ".claude-plugin/marketplace.json"
        catalog = json.loads(path.read_text(encoding="utf-8"))
        catalog["plugins"].append({"name": "orphan", "source": "./missing"})
        path.write_text(json.dumps(catalog), encoding="utf-8")
        before = self.snapshot()
        self.assertIn("stale", self.run_generator(ok=False))
        self.assertEqual(before, self.snapshot())

    def test_orphan_documentation_rejected(self):
        (self.root / "docs/plugins/orphan").mkdir(parents=True)
        self.assertIn("Orphan plugin documentation", self.run_generator("Write", ok=False))


if __name__ == "__main__":
    unittest.main()
