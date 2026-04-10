{
  services.smartdns = {
    enable = true;
    bindPort = 60;
    settings = {
      bind-tcp = "[::]:60";
      mdns-lookup = true;
      cache-size = 32768;
      cache-persist = true;
      cache-file = "/tmp/smartdns.cache";
      prefetch-domain = true;
      serve-expired-prefetch-time = 21600;
      serve-expired = true;
      serve-expired-ttl = 86400;
      serve-expired-reply-ttl = 3;
      force-qtype-SOA = 65;
      max-reply-ip-num = 16;
      speed-check-mode = "ping tcp:80 tcp:443";
      log-level = "info";
      proxy-server = "socks5://127.0.0.1:7890 -name socks5";
      server = [
        "240e:58:c000:1600:180:168:255:18"
        "240e:58:c000:1000:116:228:111:118"
        "116.228.111.118"
        "180.168.255.18"
        "223.5.5.5"
        "119.29.29.29"
        "1.1.1.1 -proxy socks5"
        "9.9.9.9 -proxy socks5"
      ];
      server-https = "https://dns.alidns.com/dns-query";
      server-tls = "dns.alidns.com";
      dualstack-ip-selection = true;
      dualstack-ip-selection-threshold = 10;
    };
  };
}
