"""layer-check 가 실제로 무엇을 잡는지 검증한다.

규칙을 바꿨는데 이 테스트가 안 깨지면 그 규칙에는 테스트가 없는 것이다 (core-principles · 변이).

실행: python3 -m unittest tests/test_layer_check.py
"""
from __future__ import annotations

import importlib.machinery
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

# 바이트코드 캐시를 쓰지 않는다. pyc 유효성은 원본의 **초 단위** mtime 으로 판정하므로,
# 같은 초 안에 스크립트를 고쳐 다시 돌리면 옛 바이트코드가 그대로 실행된다 —
# 규칙을 고쳤는데 테스트가 안 깨지는 것처럼 보이는 함정이다.
sys.dont_write_bytecode = True

SCRIPT = Path(__file__).resolve().parents[1] / "bin/layer-check"
LOADER = importlib.machinery.SourceFileLoader("layer_check", str(SCRIPT))
SPEC = importlib.util.spec_from_loader(LOADER.name, LOADER)
layer_check = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = layer_check
LOADER.exec_module(layer_check)


class CheckCase(unittest.TestCase):
    def findings(self, relative: str, source: str) -> list[str]:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory).resolve()   # macOS 의 /var → /private/var 를 맞춰 둔다
            path = root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(source, encoding="utf-8")
            with patch.object(layer_check, "REPO", root):
                return layer_check.check_file(path)


class BackendSingleDeclarationTest(CheckCase):
    """백엔드 Kotlin — 파일 하나에 최상위 선언 하나."""

    BASE = "backend/core/core-order/src/main/kotlin/order/domain/service"

    def test_one_class_passes(self) -> None:
        self.assertEqual(
            self.findings(f"{self.BASE}/OrderService.kt", "class OrderService {\n}\n"), []
        )

    def test_two_classes_are_flagged(self) -> None:
        found = self.findings(
            f"{self.BASE}/OrderService.kt",
            "class OrderService {\n}\n\nclass PaymentService {\n}\n",
        )
        self.assertEqual(len(found), 1)
        self.assertIn("최상위 선언이 2개다", found[0])

    def test_collection_file_is_flagged(self) -> None:
        found = self.findings(
            f"{self.BASE}/Dtos.kt",
            "data class OrderRequestDto(val id: Long)\n\ndata class OrderResponseDto(val id: Long)\n",
        )
        self.assertEqual(len(found), 1)

    def test_nested_class_is_not_counted(self) -> None:
        self.assertEqual(
            self.findings(
                f"{self.BASE}/OrderService.kt",
                "class OrderService {\n    class Inner {\n    }\n}\n",
            ),
            [],
        )

    def test_top_level_object_is_counted(self) -> None:
        found = self.findings(
            f"{self.BASE}/OrderService.kt",
            "class OrderService {\n}\n\nprivate object Unrelated\n",
        )
        self.assertEqual(len(found), 1)
        self.assertIn("Unrelated", found[0])

    def test_sealed_subtypes_do_not_count(self) -> None:
        self.assertEqual(
            self.findings(
                f"{self.BASE}/OrderResult.kt",
                "sealed class OrderResult\n\nclass Accepted : OrderResult()\n\nclass Rejected : OrderResult()\n",
            ),
            [],
        )

    def test_file_name_must_match_declaration(self) -> None:
        found = self.findings(f"{self.BASE}/Order.kt", "class OrderService {\n}\n")
        self.assertEqual(len(found), 1)
        self.assertIn("파일 이름과 선언 이름이 다르다", found[0])

    def test_top_level_functions_only_is_not_a_target(self) -> None:
        self.assertEqual(
            self.findings(f"{self.BASE}/OrderExtensions.kt", "fun Order.toResult(): OrderResult = TODO()\n"),
            [],
        )

    def test_declaration_in_block_comment_is_ignored(self) -> None:
        self.assertEqual(
            self.findings(
                f"{self.BASE}/OrderService.kt",
                "/*\nclass Old {\n}\n*/\nclass OrderService {\n}\n",
            ),
            [],
        )

    def test_non_kotlin_file_is_skipped(self) -> None:
        self.assertEqual(self.findings("backend/README.md", "class A\nclass B\n"), [])


class FrontendSingleLeadTest(CheckCase):
    """프론트 — 한 파일에 주역(컴포넌트·훅) 하나."""

    def test_one_component_passes(self) -> None:
        self.assertEqual(
            self.findings(
                "frontend/src/order/screens/OrderScreen.tsx",
                "export function OrderScreen() {\n  return null\n}\n",
            ),
            [],
        )

    def test_two_components_are_flagged(self) -> None:
        found = self.findings(
            "frontend/src/order/screens/OrderScreen.tsx",
            "export function OrderScreen() {\n  return null\n}\n\nexport function OrderRow() {\n  return null\n}\n",
        )
        self.assertEqual(len(found), 1)
        self.assertIn("주역이 2개다", found[0])

    def test_two_hooks_are_flagged(self) -> None:
        found = self.findings(
            "frontend/src/order/hooks/useOrderList.ts",
            "export const useOrderList = () => {}\n\nexport const useOrderDetail = () => {}\n",
        )
        self.assertEqual(len(found), 1)

    def test_helper_const_is_not_a_lead(self) -> None:
        self.assertEqual(
            self.findings(
                "frontend/src/order/screens/OrderScreen.tsx",
                "export function OrderScreen() {\n  return null\n}\n\nexport const formatMoney = (n: number) => String(n)\n",
            ),
            [],
        )

    def test_types_folder_is_exempt(self) -> None:
        self.assertEqual(
            self.findings(
                "frontend/src/order/types/order.ts",
                "export const A = () => {}\n\nexport const B = () => {}\n",
            ),
            [],
        )

    def test_styles_file_is_exempt(self) -> None:
        self.assertEqual(
            self.findings(
                "frontend/src/order/screens/OrderScreen.styles.ts",
                "export const Header = () => {}\n\nexport const Body = () => {}\n",
            ),
            [],
        )


class ScopeTest(CheckCase):
    """대상 밖 파일은 건드리지 않는다."""

    def test_repo_outside_file_is_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as outside, tempfile.TemporaryDirectory() as root:
            path = Path(outside) / "Foo.kt"
            path.write_text("class A\nclass B\n", encoding="utf-8")
            with patch.object(layer_check, "REPO", Path(root)):
                self.assertEqual(layer_check.check_file(path), [])


if __name__ == "__main__":
    unittest.main()
