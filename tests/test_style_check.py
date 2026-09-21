"""style-check 가 '통과'와 '미검사'를 구분하는지 검증한다.

이 스크립트의 존재 이유가 그 구분이다 — 도구가 없을 때 조용히 0을 내면
초록불이 아무것도 뜻하지 않게 된다 (core-principles · 통과와 미검사는 겉보기가 같다).

실행: python3 -m unittest tests/test_style_check.py
"""
from __future__ import annotations

import importlib.machinery
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

# pyc 캐시를 쓰지 않는다 — 이유는 test_layer_check.py 의 같은 줄에 적혀 있다.
sys.dont_write_bytecode = True

SCRIPT = Path(__file__).resolve().parents[1] / "bin/style-check"
LOADER = importlib.machinery.SourceFileLoader("style_check", str(SCRIPT))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
style_check = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = style_check
LOADER.exec_module(style_check)


class CheckerForTest(unittest.TestCase):
    """어느 파일을 어느 검사에 붙일지."""

    def checker(self, relative: str) -> tuple[str, str] | None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("", encoding="utf-8")
            with patch.object(style_check, "REPO", root):
                return style_check.checker_for(path)

    def test_kotlin_goes_to_ktlint(self) -> None:
        self.assertEqual(
            self.checker("backend/core/core-order/src/main/kotlin/Order.kt"),
            ("./gradlew ktlintCheck", "backend"),
        )

    def test_tsx_goes_to_tsc(self) -> None:
        self.assertEqual(
            self.checker("frontend/src/order/screens/OrderScreen.tsx"),
            ("tsc --noEmit", "frontend"),
        )

    def test_markdown_is_not_a_target(self) -> None:
        self.assertIsNone(self.checker("backend/README.md"))

    def test_frontend_outside_src_is_not_a_target(self) -> None:
        self.assertIsNone(self.checker("frontend/app.config.ts"))

    def test_outside_repo_is_not_a_target(self) -> None:
        with tempfile.TemporaryDirectory() as outside, tempfile.TemporaryDirectory() as root:
            path = Path(outside).resolve() / "Order.kt"
            path.write_text("", encoding="utf-8")
            with patch.object(style_check, "REPO", Path(root).resolve()):
                self.assertIsNone(style_check.checker_for(path))


class MissingToolTest(unittest.TestCase):
    """도구가 없으면 통과가 아니라 미검사다."""

    def test_backend_without_gradlew_is_not_a_pass(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            with patch.object(style_check, "REPO", root), \
                 patch.object(style_check, "tracked_count", return_value=0):
                outcome = style_check.check_backend()
        self.assertFalse(outcome.ran)
        self.assertFalse(outcome.passed)
        self.assertIn("gradlew", outcome.detail)

    def test_frontend_without_node_modules_is_not_a_pass(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            with patch.object(style_check, "REPO", root), \
                 patch.object(style_check, "tracked_count", return_value=0):
                outcome = style_check.check_frontend()
        self.assertFalse(outcome.ran)
        self.assertFalse(outcome.passed)
        self.assertIn("node_modules", outcome.detail)

    def test_file_count_is_reported_even_when_unavailable(self) -> None:
        """대상이 0개인데 초록불이 뜨는 구멍을 보이게 한다."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()
            with patch.object(style_check, "REPO", root), \
                 patch.object(style_check, "tracked_count", return_value=0):
                outcome = style_check.check_backend()
        self.assertEqual(outcome.file_count, 0)


if __name__ == "__main__":
    unittest.main()
