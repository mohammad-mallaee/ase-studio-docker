# ASE Studio in Docker

Run [ASE Studio](https://github.com/cad-polito-it/ase-studio) on your own computer, in your normal browser, without setting up a Linux virtual machine or compiling anything.

The image contains ASE Studio, the course's version of [gem5](https://github.com/cad-polito-it/gem5) and a RISC-V compiler. It works on Apple Silicon and Intel/AMD computers.

> This is an unofficial community project, not an official release from Politecnico di Torino or the CAD group. If your course requires the official environment, check your results there before you submit.
>
> So far it has only been tested on an Apple Silicon Mac. Windows, Linux and Intel/AMD computers are untested, so please [report any problems](https://github.com/mohammad-mallaee/ase-studio-docker/issues).

## Before you start

Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and open it. Mac users can use [OrbStack](https://orbstack.dev/) instead.

## Start ASE Studio

Docker has to be running first. ASE Studio then opens in your browser by itself, or you can go to <http://127.0.0.1:8765>.

### Windows

Paste this into PowerShell:

```powershell
curl.exe -fsSL -o "$env:TEMP\ase-studio.bat" https://raw.githubusercontent.com/mohammad-mallaee/ase-studio-docker/main/ase-studio.bat; & "$env:TEMP\ase-studio.bat"
```

Or download [`ase-studio.bat`](https://github.com/mohammad-mallaee/ase-studio-docker/raw/main/ase-studio.bat) and double-click it. If Windows warns you about the file, choose **More info**, then **Run anyway**.

### Mac and Linux

Paste this into a terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/mohammad-mallaee/ase-studio-docker/main/ase-studio.sh | bash
```

## Stop ASE Studio

Press **Ctrl+C** in the window where it is running. On Windows, answer `Y` if it asks whether to terminate the batch job.

## Your files

Projects and submission ZIPs are saved in the `ASE-Studio` folder in your home folder, and they stay there when ASE Studio stops or updates.

Simulation results aren't kept when ASE Studio stops, so run the simulation again to see them. Export anything you want to keep.

## Updates

ASE Studio never updates by itself. When a new tested version is released, you'll see a notice in the terminal window when you start it, and you can keep using your current version for as long as you like. To update, stop ASE Studio, run this command, and start it again:

```bash
docker pull ghcr.io/mohammad-mallaee/ase-studio-docker:latest
```

**Don't use the update option inside the app:** those updates haven't been tested for this image, and they are lost when ASE Studio stops.

## Known limitations

- **Open With** and **Open Folder** don't work, because they need a Linux desktop. You can open your files from the `ASE-Studio` folder instead.
- Projects copied from an older setup may fail to build if their `Makefile` contains `include ../demo.mk`. Replace that line with `include $(ASE_STUDIO_DEMO_MK)`.

## Troubleshooting

**"Docker isn't running"**: open Docker Desktop, wait until it is ready, and try again.

**"port is already allocated"**: another program is using port 8765, or another copy of ASE Studio is running. Close it and try again.

**"The container name is already in use"**: an earlier copy is still running, often because its window was closed. To stop it, run:

```bash
docker rm -f ase-studio
```

**The page doesn't load**: wait a few seconds and refresh. If it still doesn't load, check the ASE Studio window for errors.

**`BrokenPipeError` in the log**: this is harmless. It means the browser left or reloaded the page before a request finished.

## Contribution

### How versions work

The exact versions of gem5, the simulator and ASE Studio are pinned at the top of the [`Dockerfile`](Dockerfile), so nothing changes until you change it. The compiled gem5 is cached in the registry and is only rebuilt when `GEM5_COMMIT` changes.

To find the latest gem5 commit:

```bash
git ls-remote https://github.com/cad-polito-it/gem5.git refs/heads/stable
```

### Releasing a new version

1. Change the commit in the `Dockerfile` and push to `main`. This builds the image and publishes it as `candidate`. Students don't get it yet.
2. Test it:

   ```bash
   docker pull ghcr.io/mohammad-mallaee/ase-studio-docker:candidate
   ASE_STUDIO_IMAGE=ghcr.io/mohammad-mallaee/ase-studio-docker:candidate ./ase-studio.sh
   ```

3. Compare a few programs against the official environment, with both CPU models.
4. In the **Actions** tab, run **Release to students**. This moves `latest` to the candidate. New students get it on their first start. Existing students see a notice when they next start ASE Studio, and get it if they choose to update.

Changes to `ase-studio.sh`, `ase-studio.bat` or this README take effect without building an image.

### How it works

| File | Purpose |
|---|---|
| `Dockerfile` | Compiles gem5 and packages it with ASE Studio and the compiler |
| `start.sh` | Runs inside the container and starts the ASE Studio backend |
| `ase-studio.sh`, `ase-studio.bat` | Start the container from the student's computer |
| `.github/workflows/build-image.yml` | Builds both architectures and publishes `candidate` |
| `.github/workflows/release.yml` | Moves `latest` to the tested candidate |

The backend has no login, so the port is only published on `127.0.0.1` and other computers can't reach it.

## Credits

ASE Studio, gem5 and the simulator are developed by their own authors and keep their own licences. See [ase-studio](https://github.com/cad-polito-it/ase-studio), [ase_riscv_gem5_sim](https://github.com/cad-polito-it/ase_riscv_gem5_sim) and [gem5](https://github.com/cad-polito-it/gem5).
