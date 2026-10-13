---
name: Release
about: Prepare a CTBase release
title: "[RELEASE] v"
labels: release
---

## Checklist

- [ ] Version bumped in `Project.toml`
- [ ] `CHANGELOG.md` / `BREAKING.md` up to date
- [ ] CI, documentation and breakage checks are green
- [ ] Release branch merged
- [ ] GitHub release created
- [ ] Comment below posted (with the release's "What's Changed")
- [ ] Tag created by TagBot

## Comment to post

```text
@JuliaRegistrator register

Release notes:

<paste the "What's Changed" of the GitHub release here>
```
