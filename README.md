# mishaboar.org

Hugo site using the bundled LoveIt theme. Local builds and GitHub Pages use
**Hugo Extended 0.126.2**. The Extended edition is required for the theme's SCSS.

## Build on Windows

From the repository directory, run:

```powershell
.\site.cmd Build
```

The first run downloads the pinned Windows x64 release from the official
[Hugo release](https://github.com/gohugoio/hugo/releases/tag/v0.126.2), verifies
its SHA-256 checksum against the release's checksum list, and extracts it under
`.tools/hugo/0.126.2/`. Later runs reuse that copy. No administrator access,
machine-wide installation, or PATH change is needed.

The launcher uses the Windows PowerShell already installed on this machine and
permits the repository's helper script for that process only. It does not change
the saved execution policy. PowerShell 7 users can also run
`.\scripts\site.ps1 Build` directly when their script policy permits it.

Build output goes to `.build/public/`; caches and generated resources stay in
`.build/`. These folders and `.tools/` are ignored by Git. The older, tracked
`public/` directory is left untouched and is not the local build destination.

## Preview

```powershell
.\site.cmd Serve
```

Open <http://localhost:1313/> or the article at
<http://localhost:1313/gaza-donations/>. Edits rebuild automatically; press
Ctrl+C to stop. Preview output uses `.build/preview/`, separate from production
builds. If the port is busy, choose another one:

```powershell
.\site.cmd Serve -Port 1314
```

To download and verify Hugo without building, run `.\site.cmd Setup`.

## Other Platforms

Install Hugo **Extended 0.126.2** from the official release above, then run
`hugo --minify --destination .build/public` from the repository directory.
Use `hugo server` for a local preview. Generated root-level `resources/` are
also ignored by Git.

## Publish

Local builds and previews never publish anything. Publishing starts only when
source changes reach `main` on `MishaBoar/mishaboar.org`. That branch is protected;
follow its review requirements, normally by merging a pull request.

The `github pages` workflow builds with the pinned Hugo version and publishes
the generated site to `gh-pages`. GitHub Pages serves that branch at
<https://mishaboar.org/>. Confirm that both the workflow and Pages deployment
succeed before considering the live site updated. Do not commit `.tools/` or
`.build/`, or manually update the older tracked `public/` output.

Use the repository's MishaBoar commit identity and Git credential when publishing.
The following checks the Git connection without pushing any commits:

```powershell
git -c credential.https://github.com.username=MishaBoar push --dry-run origin HEAD:main
```

A dry-run is only a connection check; it does not prove that a new commit will
pass branch protection or that a future deployment will succeed.

When upgrading Hugo, update both `scripts/site.ps1` and
`.github/workflows/gh-pages.yml`, then test the theme locally before pushing.
