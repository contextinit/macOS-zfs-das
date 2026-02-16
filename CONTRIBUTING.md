# Contributing to macOS ZFS DAS

Thank you for considering contributing! Here's how you can help:

## How to Contribute

### Reporting Bugs

Use GitHub Issues and include:
- macOS version (run: `sw_vers`)
- OpenZFS version (run: `zpool version`)
- Hardware setup (DAS model, drive types)
- Steps to reproduce
- Expected vs actual behavior
- Relevant logs from `/var/log/zfs-automount.log`

### Suggesting Features

Open a GitHub Issue with:
- Clear description of the feature
- Why it would be useful
- Examples of how it would work

### Contributing Code

1. **Fork** the repository
2. **Clone** your fork:
```bash
   git clone https://github.com/YOUR_USERNAME/macos-zfs-das.git
   cd macos-zfs-das
```
3. **Create a branch:**
```bash
   git checkout -b feature/amazing-feature
```
4. **Make your changes**
5. **Test thoroughly** on a clean macOS installation
6. **Commit:**
```bash
   git add .
   git commit -m "Add amazing feature"
```
7. **Push:**
```bash
   git push origin feature/amazing-feature
```
8. **Open a Pull Request** on GitHub

### Code Standards

- **Shell scripts:** Use `shellcheck` for linting
- **Documentation:** Use Markdown, check spelling
- **Comments:** Explain WHY, not just WHAT
- **Testing:** Test on different hardware/macOS versions if possible

### Documentation

Documentation improvements are always welcome:
- Fix typos or unclear instructions
- Add missing steps
- Improve examples
- Add troubleshooting tips

## Development Setup
```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/macos-zfs-das.git
cd macos-zfs-das

# Add upstream remote
git remote add upstream https://github.com/contextinit/macos-zfs-das.git

# Stay updated
git fetch upstream
git merge upstream/main
```

## Questions?

Open a GitHub Discussion or Issue!
