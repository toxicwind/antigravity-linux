# Verified Runs

Real-system verification runs on Arch-based distros, performed manually using `make verify`.

| Timestamp | OS | Version | Status |
|---|---|---|---|
| 2026-03-09T06:43:00Z | CachyOS Linux | 1.20.4 | ✅ |

---

To log a new verified run:

```bash
make install   # install or update
make verify    # runs tests/local/verify_install.sh
```

Then append the output row to the table above and commit.
