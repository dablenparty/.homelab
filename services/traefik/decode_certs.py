#!/usr/bin/env python3

import base64
import json
import os

from pathlib import Path

if __name__ == "__main__":
    if os.geteuid() != 0:
        raise PermissionError("Please re-run this script as root!")
    base_dir = Path(__file__).parent
    acme_path = base_dir / "config" / "acme.json"
    out_path = base_dir / "certs"
    out_path.mkdir()
    with acme_path.open("r") as fd:
        acme_json = json.load(fd)
    for key in acme_json:
        certs = acme_json[key].get("Certificates")
        if certs is None:
            print(f"no certificates found for provider '{key}'")
            continue
        for cert_info in certs:
            domain = cert_info["domain"]["main"]
            decoded_cert = base64.b64decode(cert_info["certificate"])
            decoded_key = base64.b64decode(cert_info["key"])
            cert_path = out_path / f"{domain}.cert"
            key_path = out_path / f"{domain}.key"
            bytes_written = cert_path.write_bytes(decoded_cert)
            print(f"wrote {bytes_written}B to {cert_path}")
            bytes_written = key_path.write_bytes(decoded_key)
            print(f"wrote {bytes_written}B to {key_path}")

