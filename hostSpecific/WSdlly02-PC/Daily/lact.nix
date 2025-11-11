{ pkgs, ... }:
{
  environment.etc."lact/config.yaml".text = ''
    version: 5
    daemon:
      log_level: info
      admin_group: wheel
      disable_clocks_cleanup: false
    apply_settings_timer: 5
    gpus:
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
        performance_level: manual
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
    current_profile: null
    auto_switch_profiles: false
  ''; # source = (pkgs.formats.yaml {}).generate "lact-config" {}; Insolubility encountered
  systemd.services.lactd = {
    unitConfig = {
      Description = "AMDGPU Control Daemon";
      After = [ "multi-user.target" ];
    };
    serviceConfig = {
      ExecStart = "${pkgs.lact}/bin/lact daemon";
      Nice = -10;
      Restart = "on-failure";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
