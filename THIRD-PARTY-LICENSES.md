# Third-Party Licenses

This project incorporates code and assets from the following open-source projects.

---

## SwiftBar

- **Project:** SwiftBar — Powerful macOS menu bar customization tool
- **Repository:** https://github.com/swiftbar/SwiftBar
- **Version:** v2.0.1
- **License:** MIT

```
MIT License

Copyright (c) 2020 Ameba Labs

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

**Usage in this project:**
- `scripts/install-swiftbar.sh` downloads and installs SwiftBar from the official GitHub Releases
- `swiftbar/zfs-monitor.30s.sh` and `swiftbar/zfs-advanced.30s.sh` are SwiftBar plugins
  that use the SwiftBar plugin API (metadata headers, `bash=` actions, SF Symbol support)

---

## OpenZFS on macOS

- **Project:** OpenZFS on OS X / macOS
- **Repository:** https://github.com/openzfsonosx/openzfs
- **License:** CDDL-1.0 (Common Development and Distribution License)

This project's scripts invoke the `zpool` and `zfs` binaries provided by OpenZFS.
The OpenZFS binaries are not bundled with this repository; they must be installed
separately from https://openzfsonosx.github.io/.

---

## Acknowledgments

See also the [Acknowledgments section in README.md](README.md#acknowledgments).
