{
  xdg.configFile."pipewire/pipewire.conf.d/20-roc-source.conf" = {
    text = ''
      context.modules = [
        { name = libpipewire-module-roc-source
          args = {
            local.ip = 10.42.0.2
            resampler.profile = high
            fec.code = ldpc
            sess.latency.msec = 60
            local.source.port = 10001
            local.repair.port = 10002
            local.control.port = 10003
            source.name = "ROC Source"
            source.props = {
              node.name = "roc-source"
            }
          }
        }
      ]
    '';
  };
}
