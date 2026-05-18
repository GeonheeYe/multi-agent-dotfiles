#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
LOADER_PATH = ROOT / "scripts" / "longmemory_loader.py"


def load_module():
    spec = importlib.util.spec_from_file_location("longmemory_loader", LOADER_PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class RemoteWikiPathTest(unittest.TestCase):
    def setUp(self) -> None:
        self.loader = load_module()

    def test_default_remote_wiki_path_uses_current_wiki_root(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            self.assertEqual(self.loader.remote_wiki_path(), "/home/geonhee/wiki")

    def test_remote_wiki_dir_overrides_default(self) -> None:
        with patch.dict(os.environ, {"LONGMEMORY_REMOTE_WIKI_DIR": "/srv/wiki"}, clear=True):
            self.assertEqual(self.loader.remote_wiki_path(), "/srv/wiki")

    def test_remote_dir_keeps_legacy_longmemory_layout(self) -> None:
        with patch.dict(os.environ, {"LONGMEMORY_REMOTE_DIR": "/srv/LONGMEMORY"}, clear=True):
            self.assertEqual(self.loader.remote_wiki_path(), "/srv/LONGMEMORY/wiki")

    def test_list_local_merges_index_and_project_directories(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            wiki = Path(tmp)
            (wiki / "index.md").write_text("- [xqbot-paper](./projects/xqbot-paper/overview.md)\n", encoding="utf-8")
            (wiki / "projects" / "xqbot-paper").mkdir(parents=True)
            (wiki / "projects" / "aegis-ap").mkdir(parents=True)

            listing = self.loader.list_local(wiki)

            self.assertEqual(listing["projects"], ["aegis-ap", "xqbot-paper"])


if __name__ == "__main__":
    unittest.main()
