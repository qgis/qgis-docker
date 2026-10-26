"""Unit tests for qgis_startup.py.

These tests verify the monkey-patched exception handlers without requiring
a running QGIS instance by mocking the qgis imports.
"""

import importlib
import sys
import types
from io import StringIO
from unittest import mock

import pytest


# ---------------------------------------------------------------------------
# Fixtures: build minimal stubs for the ``qgis`` package so that
# qgis_startup.py can be imported outside of a real QGIS environment.
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True)
def _mock_qgis(monkeypatch):
    """Inject lightweight stubs for ``qgis.utils`` and ``qgis.core``."""
    # qgis package
    qgis_pkg = types.ModuleType("qgis")
    # qgis.utils
    qgis_utils = types.ModuleType("qgis.utils")
    qgis_utils.showException = None
    qgis_utils.open_stack_dialog = None
    qgis_pkg.utils = qgis_utils
    # qgis.core  with Qgis.Warning
    qgis_core = types.ModuleType("qgis.core")
    qgis_sentinel = type("Qgis", (), {"Warning": 1})()
    qgis_core.Qgis = qgis_sentinel
    qgis_pkg.core = qgis_core

    monkeypatch.setitem(sys.modules, "qgis", qgis_pkg)
    monkeypatch.setitem(sys.modules, "qgis.utils", qgis_utils)
    monkeypatch.setitem(sys.modules, "qgis.core", qgis_core)

    yield qgis_utils

    # Remove the module from the cache so it is re-imported each time
    sys.modules.pop("qgis_startup", None)


@pytest.fixture()
def startup_module(_mock_qgis):
    """Import (or re-import) qgis_startup and return the module."""
    startup_path = str(
        __import__("pathlib").Path(__file__).resolve().parent.parent
        / "desktop"
        / "scripts"
        / "test_runner"
        / "qgis_startup.py"
    )
    spec = importlib.util.spec_from_file_location("qgis_startup", startup_path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

class TestShowException:
    """Tests for the patched ``_showException``."""

    def test_prints_message(self, startup_module, capsys):
        try:
            raise ValueError("boom")
        except ValueError:
            exc_type, exc_value, exc_tb = sys.exc_info()

        startup_module._showException(exc_type, exc_value, exc_tb, "Error occurred")
        captured = capsys.readouterr()
        assert "Error occurred" in captured.out

    def test_prints_traceback(self, startup_module, capsys):
        try:
            raise RuntimeError("detailed error")
        except RuntimeError:
            exc_type, exc_value, exc_tb = sys.exc_info()

        startup_module._showException(exc_type, exc_value, exc_tb, "msg")
        captured = capsys.readouterr()
        assert "RuntimeError" in captured.out
        assert "detailed error" in captured.out

    def test_does_not_raise(self, startup_module):
        """The whole point: should never raise even on weird input."""
        try:
            raise TypeError("test")
        except TypeError:
            exc_type, exc_value, exc_tb = sys.exc_info()
        # Must not raise
        startup_module._showException(exc_type, exc_value, exc_tb, "safe")


class TestOpenStackDialog:
    """Tests for the patched ``_open_stack_dialog``."""

    def test_prints_message(self, startup_module, capsys):
        try:
            raise ValueError("dialog test")
        except ValueError:
            exc_type, exc_value, exc_tb = sys.exc_info()

        startup_module._open_stack_dialog(exc_type, exc_value, exc_tb, "dialog msg")
        captured = capsys.readouterr()
        assert "dialog msg" in captured.out

    def test_does_not_raise(self, startup_module):
        try:
            raise ValueError("x")
        except ValueError:
            exc_type, exc_value, exc_tb = sys.exc_info()
        startup_module._open_stack_dialog(exc_type, exc_value, exc_tb, "safe")


class TestMonkeyPatching:
    """Verify that importing the module patches qgis.utils."""

    def test_show_exception_is_patched(self, startup_module, _mock_qgis):
        assert _mock_qgis.showException is startup_module._showException

    def test_open_stack_dialog_is_patched(self, startup_module, _mock_qgis):
        assert _mock_qgis.open_stack_dialog is startup_module._open_stack_dialog
