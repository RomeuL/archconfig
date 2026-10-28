import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[1] / "home/.config/waybar/scripts/agents.py"
spec = importlib.util.spec_from_file_location("waybar_agents", SCRIPT)
agents = importlib.util.module_from_spec(spec)
spec.loader.exec_module(agents)


class AgentContextTests(unittest.TestCase):
    def test_codex_uses_last_request_instead_of_cumulative_session_tokens(self):
        session = {"info": {
            "last_token_usage": {"total_tokens": 25000},
            "total_token_usage": {"total_tokens": 9000000},
            "model_context_window": 100000,
        }}
        self.assertEqual(agents.context_used("codex", [session]), 25)

    def test_latest_session_context_is_not_summed(self):
        sessions = [{"context_window": {"used_percentage": 12}},
                    {"context_window": {"used_percentage": 60}}]
        self.assertEqual(agents.context_used("claude", sessions), 12)

    def test_missing_context_is_unknown(self):
        for agent in ("claude", "codex"):
            for sessions in ([], [{}], [{"info": {"model_context_window": 0}}]):
                with self.subTest(agent=agent, sessions=sessions):
                    self.assertIsNone(agents.context_used(agent, sessions))

    def test_zero_context_is_valid(self):
        self.assertEqual(agents.context_used("claude", [
            {"context_window": {"used_percentage": 0}}]), 0)
        self.assertEqual(agents.context_used("codex", [{"info": {
            "last_token_usage": {"total_tokens": 0}, "model_context_window": 100000,
        }}]), 0)

    def render_agent(self, agent, session):
        found = [("1", 0, "address", "", agent, "idle", "icon")]
        with patch.object(agents, f"{agent}_usage", return_value=[session]), \
                patch.object(agents, f"{agent}_tooltip", return_value=[]):
            return agents.render(found)["text"]

    def test_bar_distinguishes_rate_limit_from_context_for_both_agents(self):
        sessions = {
            "claude": {"rate_limits": {"five_hour": {"used_percentage": 50}},
                       "context_window": {"used_percentage": 12}},
            "codex": {"rate_limits": {"primary": {"used_percent": 50}},
                      "info": {"last_token_usage": {"total_tokens": 12000},
                               "model_context_window": 100000}},
        }
        for agent, session in sessions.items():
            with self.subTest(agent=agent):
                text = self.render_agent(agent, session)
                self.assertIn("5h <span", text)
                self.assertIn("50%</span> · ctx <span", text)
                self.assertIn("12%</span>", text)

    def test_context_is_shown_without_rate_limit(self):
        text = self.render_agent("claude", {"context_window": {"used_percentage": 0}})
        self.assertIn("ctx <span", text)
        self.assertIn("0%</span>", text)
        self.assertNotIn("5h", text)

    def test_missing_context_does_not_invent_a_percentage(self):
        text = self.render_agent("codex", {"rate_limits": {"primary": {"used_percent": 30}}})
        self.assertIn("5h <span", text)
        self.assertNotIn("ctx", text)

    def test_no_sessions_keeps_module_hidden(self):
        self.assertEqual(agents.render([]), {"text": "", "class": "empty"})


if __name__ == "__main__":
    unittest.main()
