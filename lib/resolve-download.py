#!/usr/bin/env python3
"""Parse official Google Antigravity download-page JavaScript asset URLs.

Network access remains in the calling shell's curl invocation. This helper only
parses saved HTML and emits an HTTPS asset URL so every downloaded source stays
visible to the installer.
"""
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urljoin, urlparse
import sys

class ScriptAssets(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.urls = []

    def handle_starttag(self, tag, attrs):
        if tag.lower() not in ("script", "link"):
            return
        for key, value in attrs:
            if key.lower() not in ("src", "href") or not value:
                continue
            parsed = urlparse(value)
            if parsed.path.lower().endswith(".js"):
                self.urls.append(value)

def bundle_url(html_path, page_url):
    parser = ScriptAssets()
    parser.feed(Path(html_path).read_text(encoding="utf-8", errors="replace"))
    if not parser.urls:
        return ""
    preferred = [u for u in parser.urls if "main-" in urlparse(u).path.lower()]
    candidates = preferred or parser.urls
    result = urljoin(page_url, candidates[-1])
    parsed = urlparse(result)
    base = urlparse(page_url)
    if parsed.scheme != "https" or parsed.hostname != base.hostname:
        return ""
    return result

def main():
    if len(sys.argv) != 4 or sys.argv[1] != "bundle-url":
        print("Usage: resolve-download.py bundle-url HTML_FILE PAGE_URL", file=sys.stderr)
        return 2
    print(bundle_url(sys.argv[2], sys.argv[3]))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
