# Example env.sh for zero-clone
# Sourced by the zero-clone script before launching rclone jobs for this base.

# Number of parallel rclone sync jobs for this base
export JOBS=2

# Extra rclone options (space-separated)
# Example: enable checksums and set transfers
# export RCLONE_OPTS="--checksum --transfers 8"

# Override the destination root for this specific base only.
# Use an absolute path for a shared data lake, or a relative name to stay under <base>/.
# For a project-wide default, set ZERO_CLONE_DIR in init.sh instead.
# export CLONE_DIR=/data/shared-lake

