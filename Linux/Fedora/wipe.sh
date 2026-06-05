#!/usr/bin/env bash
set -euo pipefail

# Required packages (nwipe removed)
sudo dnf install -y \
  nvme-cli \
  hdparm \
  util-linux \
  gdisk \
  parted \
  cryptsetup \
  smartmontools \
  coreutils

LOGFILE="/run/autowipe.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== Autowipe started: $(date) ==="

# Enumerate real block devices only
for dev in $(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}'); do
  echo ""
  echo "Processing: $dev"

  TYPE=$(lsblk -dn -o TRAN "$dev" 2>/dev/null || echo "unknown")
  MODEL=$(lsblk -dn -o MODEL "$dev" 2>/dev/null || echo "unknown")

  echo "Type: $TYPE"
  echo "Model: $MODEL"

  # NVMe path
  if [[ "$dev" == /dev/nvme*n1 ]]; then
    echo "[NVMe] Attempting format erase..."
    if nvme format "$dev" --force; then
      echo "[OK] NVMe format completed"
      continue
    fi

    echo "[WARN] NVMe format failed, trying sanitize..."
    if nvme sanitize "$dev" --no-dealloc; then
      echo "[OK] NVMe sanitize completed"
      continue
    fi

    echo "[WARN] NVMe sanitize failed, falling back to overwrite"
  fi

  # SATA path
  if [[ "$dev" == /dev/sd* ]]; then
    echo "[SATA] Attempting ATA secure erase..."

    hdparm --user-master u --security-set-pass NULL "$dev" || true

    if hdparm --user-master u --security-erase NULL "$dev"; then
      echo "[OK] ATA secure erase completed"
      continue
    fi

    echo "[WARN] ATA secure erase failed, falling back to overwrite"
  fi

  # Fallback wipe
  echo "[FALLBACK] Overwriting with zeros (shred)..."
  shred -v -n 0 -z "$dev" || true

  echo "[DONE] Fallback wipe finished for $dev"
done

echo "=== Autowipe complete: $(date) ==="
