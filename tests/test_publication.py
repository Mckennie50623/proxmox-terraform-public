"""Public snapshot must not contain deployment-specific endpoints."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class PublicationTests(unittest.TestCase):
    def test_no_private_network_or_dynamic_dns_endpoints(self):
        forbidden = re.compile(
            r'\b192\.168\.\d+\.|\b10\.\d+\.\d+\.|'
            r'\b172\.(?:1[6-9]|2\d|3[01])\.\d+\.|'
            r'\b[\w.-]+\.duckdns\.org\b|\b[\w.-]+\.ts\.net\b'
        )
        for path in ROOT.rglob('*'):
            if not path.is_file() or any(p in ('.git', '.terraform', '__pycache__') for p in path.parts):
                continue
            try:
                text = path.read_text()
            except UnicodeDecodeError:
                continue
            with self.subTest(path=str(path.relative_to(ROOT))):
                self.assertIsNone(forbidden.search(text), 'Non-example endpoint remains')


if __name__ == '__main__':
    unittest.main()
