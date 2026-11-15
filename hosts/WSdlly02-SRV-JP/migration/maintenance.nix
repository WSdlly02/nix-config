# Append a private cpio with /etc/dropbear/host-key and /root/.ssh/authorized_keys
# after this archive. Authentication material stays outside the Nix store.
{ host }:
let
  inherit (host) config pkgs;
  inherit (pkgs) lib;
  network = config.systemd.network.networks."10-uplink";
  modules = pkgs.makeModulesClosure {
    kernel = config.system.modulesTree;
    firmware = config.hardware.firmware;
    rootModules = [
      "virtio_pci"
      "virtio_net"
      "virtio_blk"
      "ext4"
    ];
    allowMissing = true;
  };
  init = pkgs.writeScript "maintenance-init" ''
    #!${pkgs.busybox}/bin/sh
    export PATH=/usr/bin:/bin
    mkdir -p /proc /sys /dev /run /etc /dev/pts /var/run /root
    mount -t proc proc /proc
    mount -t sysfs sysfs /sys
    mount -t devtmpfs devtmpfs /dev
    mkdir -p /dev/pts
    mount -t devpts devpts /dev/pts
    exec </dev/console >/dev/console 2>&1
    ln -sf /proc/mounts /etc/mtab
    echo 'root:x:0:0:maintenance:/root:/bin/sh' > /etc/passwd
    echo 'root:x:0:' > /etc/group
    echo /bin/sh > /etc/shells
    for module in virtio_pci virtio_blk virtio_net ext4; do
      modprobe "$module"
    done
    until test -e /sys/class/net/eth0/address; do sleep 0.1; done
    if [ "$(cat /sys/class/net/eth0/address)" = "${network.matchConfig.MACAddress}" ]; then
      echo 0 > /proc/sys/net/ipv6/conf/eth0/accept_ra
      echo 0 > /proc/sys/net/ipv6/conf/eth0/autoconf
      ip link set lo up
      ip link set eth0 up
      ${lib.concatMapStringsSep "\n" (addr: "ip address add ${addr} dev eth0") network.address}
      ${lib.concatMapStringsSep "\n" (
        route: "ip route add default via ${route.Gateway} dev eth0 onlink"
      ) network.routes}
      echo 'nameserver ${builtins.head config.networking.nameservers}' > /etc/resolv.conf
      hostname srv-jp-maintenance
      if [ -s /etc/dropbear/host-key ] && [ -s /root/.ssh/authorized_keys ]; then
        dropbear -E -s -j -k -p 10022 -r /etc/dropbear/host-key
      fi
    fi
    # PID 1 keeps the RAM root alive. Disk access is an explicit operator action.
    while :; do sleep 3600; done
  '';
in
pkgs.makeInitrdNG {
  name = "srv-jp-maintenance-initramfs";
  compressor = "gzip";
  contents = [
    {
      source = "${pkgs.dropbear}/bin/dropbear";
      target = "/usr/bin/dropbear";
    }
    {
      source = "${pkgs.iproute2}/bin/ip";
      target = "/usr/bin/ip";
    }
    {
      source = "${pkgs.kmod}/bin/modprobe";
      target = "/usr/bin/modprobe";
    }
    {
      source = "${pkgs.coreutils}/bin/dd";
      target = "/usr/bin/dd";
    }
    {
      source = "${pkgs.coreutils}/bin/sha256sum";
      target = "/usr/bin/sha256sum";
    }
    {
      source = "${pkgs.util-linux}/bin/blockdev";
      target = "/usr/bin/blockdev";
    }

    {
      source = init;
      target = "/init";
    }
    {
      source = "${pkgs.busybox}/bin";
      target = "/bin";
    }
    {
      source = "${modules}/lib/modules";
      target = "/lib/modules";
    }
    {
      source = "${pkgs.zstd}/bin/zstd";
      target = "/usr/bin/zstd";
    }
  ];
}
