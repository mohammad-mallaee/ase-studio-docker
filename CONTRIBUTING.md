# Contributing

## How versions work

The exact versions of gem5, the simulator and ASE Studio are pinned at the top of the [`Dockerfile`](Dockerfile), so nothing changes until you change it. The compiled gem5 is cached in the registry and is only rebuilt when `GEM5_COMMIT` changes.

To find the latest gem5 commit:

```bash
git ls-remote https://github.com/cad-polito-it/gem5.git refs/heads/stable
```

## Releasing a new version

1. Change the commit in the `Dockerfile` and push to `main`. This builds the image and publishes it as `candidate`. Students don't get it yet.
2. Test it:

   ```bash
   docker pull ghcr.io/mohammad-mallaee/ase-studio-docker:candidate
   ASE_STUDIO_IMAGE=ghcr.io/mohammad-mallaee/ase-studio-docker:candidate ./ase-studio.sh
   ```

3. Compare a few programs against the official environment, with both CPU models.
4. In the **Actions** tab, run **Release to students**. This moves `latest` to the candidate and adds a dated tag, such as `release-2026-11-05-2`. New students get it on their first start. Existing students see a notice when they next start ASE Studio, and get it if they choose to update.

### Rolling back

1. Find the last good release tag on the [package page](https://github.com/mohammad-mallaee/ase-studio-docker/pkgs/container/ase-studio-docker).
2. Run **Release to students** again, and enter that tag as the image to release.

New students get the old version straight away. Students who already updated see the notice next time they start ASE Studio, and go back by running `ase-studio update`, so tell them to do that.

Changes to the launchers, the installers or the docs don't build an image. Students only get a changed launcher when they run the install command again.

## How it works

| File | Purpose |
|---|---|
| `Dockerfile` | Compiles gem5 and packages it with ASE Studio and the compiler |
| `start.sh` | Runs inside the container and starts the ASE Studio backend |
| `ase-studio.sh`, `ase-studio.bat` | The `ase-studio` command on the student's computer |
| `install.sh`, `install.ps1` | Put the `ase-studio` command on the student's `PATH` |
| `.github/workflows/build-image.yml` | Builds both architectures and publishes `candidate` |
| `.github/workflows/release.yml` | Moves `latest` to the tested candidate |

The backend has no login, so the port is only published on `127.0.0.1` and other computers can't reach it.
