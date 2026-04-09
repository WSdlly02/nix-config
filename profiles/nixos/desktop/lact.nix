{ lib, ... }:
{
  services.lact.enable = true;
  environment.etc."lact/config.yaml".text = lib.mkForce ''
    version: 5
    daemon:
      log_level: info
      admin_group: wheel
      disable_clocks_cleanup: false
    apply_settings_timer: 5
    gpus:
      1002:13C0-1458:D000-0000:13:00.0:
        fan_control_enabled: false
        performance_level: auto
      1002:73DF-1002:0E36-0000:03:00.0:
        fan_control_enabled: true
        fan_control_settings:
          mode: curve
          static_speed: 0.5
          temperature_key: edge
          interval_ms: 500
          curve:
            40: 0.2
            50: 0.4
            60: 0.85
            70: 1.0
          spindown_delay_ms: 1000
          change_threshold: 1
        power_cap: 186.0
        performance_level: auto
    current_profile: null
    auto_switch_profiles: false
  '';
}
