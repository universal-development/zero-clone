# zero-clone

Portable Bash CLI to automatically sync from remote servers to local directories using rclone, with a simple convention-based layout per project.

Directory convention (per base directory)
- clone: synchronized files go here
- .zero-clone/rclone.conf: rclone configuration used for that base
- .zero-clone/list.txt: sources to sync, one per line
- .zero-clone/env.sh: optional environment overrides (e.g., JOBS, RCLONE_OPTS)
- .zero-clone/logs/: per-job rclone logs

Quick start
- Install rclone and ensure it’s in PATH.
- Create a base directory and add the structure above.
- Put sync sources in `.zero-clone/list.txt` (format below).
- Run: `bash bin/zero-clone` (or add `bin/` to PATH and run `zero-clone`).

CLI usage
- `zero-clone [options] [PATH ...]`
- Options:
  - `-y, --yes`: skip confirmation prompt
  - `-j, --jobs N`: default parallel jobs when env.sh doesn’t set JOBS
  - `--from-file FILE`: file listing base directories to process (falls back to `zero-clone.txt` if present)
  - `--dry-run`: pass `--dry-run` to rclone
  - `--no-progress`: hide rclone progress
  - `--version`, `-h/--help`
- PATH arguments: search roots that are scanned recursively for `.zero-clone` directories. Defaults to current directory when not using `--from-file`.

Discovery of bases (.zero-clone)
- If `--from-file` provided: read base directories from it (one per line, `#` comments allowed).
- Else if `zero-clone.txt` exists in current working directory: read from it.
- Else: recursively find `.zero-clone` directories under provided PATH(s) (or `.`) and use their parents as bases.

list.txt format
- One job per non-empty, non-comment line: `SRC [DEST]`
  - `SRC`: rclone source (e.g., `remote:path/to/data` or a URL supported by rclone)
  - `DEST` (optional): relative path under `clone/`. If omitted, it is derived from `basename(SRC path)`.
- Examples:
  - `myremote:projects/repo         repos/repo` → syncs to `clone/repos/repo`
  - `myremote:datasets/cats` → syncs to `clone/cats`

env.sh (optional)
- Sourced before running jobs for the base; you may export:
  - `JOBS`: number of parallel rclone sync processes (default 2, or `--jobs` CLI)
  - `RCLONE_OPTS`: extra flags passed to rclone (e.g., `"--checksum --transfers 8"`)

Logs
- Per-job logs are written to `<base>/.zero-clone/logs/<timestamp>_<dest>_<src>.log`.
- On failures, the script exits non-zero and points to the relevant log files.

Examples
- `examples/sample-project/`: minimal layout with placeholder files.
- `examples/local-to-local/`: end-to-end local-to-local sync with a runnable `run.sh`.

**Testing**
- Run all tests: `bash test/run.sh`
- Requires `rclone` installed from your OS package manager and available in PATH.
- Tests use local filesystem paths (no network) by copying `examples/sample-project` to a temp dir, generating local sources, and verifying:
  - discovery, confirmation bypass, logging, and per-base concurrency wiring
  - creation of per-job logs in `<base>/.zero-clone/logs/`
  - local file sync results under `<base>/clone/`

Notes
- rclone is executed with `--config <base>/.zero-clone/rclone.conf` so each base can have isolated configs, remotes, and keys.
- The script groups jobs per base and applies the per-base `JOBS` limit concurrently.
