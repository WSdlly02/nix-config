{
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        rsync-debian-config = "rsync -avH --delete ~/Documents/debian-config wsdlly02-srv:~/Documents/";
        rsync-findtrueme-gateway = "rsync -avH --delete --exclude-from=$HOME/Documents/Life-Planning-Project/Project-A_Cash-Flow-Engine/findtrue.me-gateway/exclude.txt ~/Documents/Life-Planning-Project/Project-A_Cash-Flow-Engine/findtrue.me-gateway wsdlly02-srv:~/Documents/";
        rsync-findtrueme-tests = "rsync -avH --delete --exclude-from=$HOME/Documents/Life-Planning-Project/Project-A_Cash-Flow-Engine/findtrue.me-tests/exclude.txt ~/Documents/Life-Planning-Project/Project-A_Cash-Flow-Engine/findtrue.me-tests wsdlly02-srv:~/Documents/";
        whisper = "$MY_CODES_PATH/SOPs/audio-process/whisper.sh";
      };
    };
  };
}
