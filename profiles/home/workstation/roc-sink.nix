{
  xdg.configFile."pipewire/pipewire.conf.d/20-roc-sink.conf" = {
    text = ''
      context.modules = [
        { name = libpipewire-module-roc-sink
          args = {
            remote.ip = 10.42.0.2
            fec.code = ldpc
            remote.source.port = 10001
            remote.repair.port = 10002
            remote.control.port = 10003
            sink.name = "ROC Sink"
            sink.props = {
              node.name = "roc-sink"
            }
          }
        }
      ]
    '';
  };
}
