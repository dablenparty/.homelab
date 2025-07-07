#!/usr/bin/env python3

import base64
import json
import os

from pathlib import Path

def decode_to_pem(b64_key: str, out_path: Path):
    decoded = base64.b64decode(b64_key)
    if out_path.exists():
        print(f"removing existing {out_path.name}")
        out_path.unlink()
    bytes_written = out_path.write_bytes(decoded)
    print(f"wrote {bytes_written}B to {out_path}")


if __name__ == "__main__":
    if os.geteuid() != 0:
        raise PermissionError("Please re-run this script as root!")
    base_dir = Path(__file__).parent
    acme_path = base_dir / "config" / "acme.json"
    out_path = base_dir / "certs"
    out_path.mkdir(exist_ok=True)
    with acme_path.open("r") as fd:
        acme_json = json.load(fd)
    for key in acme_json:
        certs = acme_json[key].get("Certificates")
        if certs is None:
            print(f"no certificates found for provider '{key}'")
            continue
        for cert_info in certs:
            domain = cert_info["domain"]["main"]
            cert_path = out_path / f"{domain}-cert.pem"
            decode_to_pem(cert_info["certificate"], cert_path)
            key_path = out_path / f"{domain}-key.pem"
            decode_to_pem(cert_info["key"], key_path)

