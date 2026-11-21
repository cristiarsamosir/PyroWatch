#!/usr/bin/env python3
"""
Download the split archive <dataset>_chunks.tar.gz.aa, .ab, ... from the
ChaosBench Hugging Face repo into a folder. Resumable: re-running continues
unfinished parts and skips finished ones.

Usage: python3 download_parts.py <dataset> <dest_dir>
"""
import http.client
import os
import string
import sys
import time
import urllib.error
import urllib.request

# Set CHAOSBENCH_REVISION to a Hugging Face commit hash to pin the exact data version.
REVISION = os.environ.get("CHAOSBENCH_REVISION", "main")
BASE = os.environ.get("CHAOSBENCH_BASE",
                      f"https://huggingface.co/datasets/LEAP/ChaosBench/resolve/{REVISION}")
UA = {"User-Agent": "chaosbench-download/1.0"}
MAX_TRIES = 50
CHUNK = 4 << 20


def suffixes():
    for a in string.ascii_lowercase:
        for b in string.ascii_lowercase:
            yield a + b


def fetch(url, final):
    """Download one part. Returns False if it does not exist (404), True when complete."""
    part = final + ".part"
    for attempt in range(MAX_TRIES):
        have = os.path.getsize(part) if os.path.exists(part) else 0
        headers = dict(UA)
        if have:
            headers["Range"] = f"bytes={have}-"
        try:
            resp = urllib.request.urlopen(urllib.request.Request(url, headers=headers), timeout=60)
            if have and resp.status != 206:
                have = 0  # server ignored Range: restart this part from scratch
            cr = resp.headers.get("Content-Range")
            cl = resp.headers.get("Content-Length")
            total = int(cr.split("/")[-1]) if cr else (int(cl) + have if cl else None)
            t0 = last = time.time()
            got = 0
            with open(part, "ab" if have else "wb") as f:
                while True:
                    b = resp.read(CHUNK)
                    if not b:
                        break
                    f.write(b)
                    got += len(b)
                    now = time.time()
                    if now - last >= 30:
                        done = have + got
                        of = f" of {total / 1e9:.2f}" if total else ""
                        print(f"  {os.path.basename(final)}: {done / 1e9:.2f}{of} GB "
                              f"({got / 1e6 / (now - t0):.1f} MB/s)", flush=True)
                        last = now
            size = os.path.getsize(part)
            if total is not None and size < total:
                raise IOError(f"truncated at {size:,} of {total:,} bytes")
            os.replace(part, final)
            return True
        except urllib.error.HTTPError as e:
            if e.code == 404:
                return False
            if e.code == 416 and os.path.exists(part):  # we already hold every byte
                os.replace(part, final)
                return True
            err = e
        except (OSError, http.client.HTTPException) as e:
            err = e
        wait = min(60, 2 ** min(attempt, 6))
        print(f"  [retry {attempt + 1}] {os.path.basename(final)} @ {have:,} bytes: "
              f"{err!r}; waiting {wait}s", flush=True)
        time.sleep(wait)
    raise RuntimeError(f"giving up on {url}")


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    dataset, dest = sys.argv[1], sys.argv[2]
    os.makedirs(dest, exist_ok=True)
    n = 0
    for suf in suffixes():
        name = f"{dataset}_chunks.tar.gz.{suf}"
        final = os.path.join(dest, name)
        if os.path.exists(final):
            print(f"have {name}", flush=True)
            n += 1
            continue
        print(f"downloading {name}", flush=True)
        if not fetch(f"{BASE}/{dataset}/{name}", final):
            break
        n += 1
    if n == 0:
        sys.exit(f"no parts found for '{dataset}' (404 on the first part)")
    print(f"download complete: {n} part(s) in {dest}", flush=True)


if __name__ == "__main__":
    main()
