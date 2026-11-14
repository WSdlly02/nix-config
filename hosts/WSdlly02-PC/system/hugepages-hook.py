"""
Allocate the Windows 11 VM's 2 MiB hugepages on demand.

This VM owns the host's default hugepage pool, as in the previous shell hook.
Do not share that pool with other VMs.
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

VM_NAME = "Windows 11"
CONFIG = Path(f"/var/lib/libvirt/qemu/{VM_NAME}.xml")
VM_SYSCTL = Path("/proc/sys/vm")


def log(message):
    print(f"hugepages: {message}", file=sys.stderr)


def required_pages(config: Path) -> int:
    memory = ET.parse(config).getroot().find("currentMemory")
    if memory is None or not memory.text:
        raise ValueError("missing currentMemory in domain XML")
    # libvirt: k/M/G are binary units, KB/MB/GB are decimal units.
    units = {
        "b": 1, "bytes": 1,
        "k": 1024, "KiB": 1024, "KB": 1000,
        "M": 1024**2, "MiB": 1024**2, "MB": 1000**2,
        "G": 1024**3, "GiB": 1024**3, "GB": 1000**3,
        "T": 1024**4, "TiB": 1024**4, "TB": 1000**4,
    }
    unit = memory.get("unit", "KiB")
    if unit not in units:
        raise ValueError(f"unsupported memory unit: {unit}")
    size = int(memory.text) * units[unit]
    if size <= 0:
        raise ValueError("currentMemory must be positive")
    page_size = 2 * 1024**2
    return (size + page_size - 1) // page_size


def write_sysctl(name: str, value: int):
    (VM_SYSCTL / name).write_text(f"{value}\n")


def allocate(pages: int) -> bool:
    write_sysctl("nr_hugepages", pages)
    actual = int((VM_SYSCTL / "nr_hugepages").read_text())
    log(f"requested {pages} x 2 MiB, allocated {actual}")
    return actual >= pages


def prepare(pages: int):
    if allocate(pages):
        return
    log("allocation short; compacting memory and retrying")
    write_sysctl("compact_memory", 1)
    if allocate(pages):
        return
    log("still short; dropping reclaimable caches, compacting and retrying")
    write_sysctl("drop_caches", 3)
    write_sysctl("compact_memory", 1)
    if not allocate(pages):
        raise RuntimeError(f"hugepage allocation failed: need {pages} pages")


def main(args: list[str]):
    if len(args) < 2:
        raise ValueError("expected libvirt guest name and hook action")
    guest, action = args[:2]
    if guest != VM_NAME:
        return
    if action == "prepare":
        prepare(required_pages(CONFIG))
    elif action == "release":
        log(f"releasing hugepages for {VM_NAME}")
        write_sysctl("nr_hugepages", 0)


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except (OSError, ValueError, RuntimeError, ET.ParseError) as error:
        log(str(error))
        sys.exit(1)
