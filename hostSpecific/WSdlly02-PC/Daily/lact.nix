{ lib, ... }:
{
  services.lact.enable = true;
  environment.etc."lact/config.yaml".text = lib.mkForce ''
    apply_settings_timer: 5
    auto_switch_profiles: false
    current_profile: null
    daemon:
      admin_group: wheel
      disable_clocks_cleanup: false
      log_level: info
    gpus:
      1002:13C0-1458:D000-0000:13:00.0:
        fan_control_enabled: false
        performance_level: auto
      1002:73DF-1002:0E36-0000:03:00.0:
        fan_control_enabled: true
        fan_control_settings:
          change_threshold: 1
          curve:
            40: 0.2
            50: 0.4
            60: 0.85
            70: 1.0
          interval_ms: 500
          mode: curve
          spindown_delay_ms: 1000
          static_speed: 0.5
          temperature_key: edge
        max_core_clock: 2640
        performance_level: manual
        power_cap: 213.0
        power_profile_mode_index: 1
        power_states:
          core_clock:
          - 0
          - 1
          memory_clock:
          - 0
          - 1
          - 2
          - 3
        voltage_offset: -10
    version: 5
  '';
}
