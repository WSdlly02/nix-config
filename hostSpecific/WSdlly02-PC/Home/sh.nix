{
  programs = {
    fish = {
      enable = true;
      shellAliases = {
        dl = "aria2c -x 16 -s 16 -k 1M -d ~/Downloads --allow-overwrite=true --file-allocation=none --continue=true";
        rsync-debian-config = "rsync -avH --delete ~/Documents/debian-config wsdlly02-srv:~/Documents/";
        rsync-findtrueme-gateway = "rsync -avH --delete --exclude-from=$HOME/Documents/Life-Planning-Project/Project-A_Cash-Flow-Engine/findtrue.me-gateway/exclude.txt ~/Documents/Life-Planning-Project/Project-A_Cash-Flow-Engine/findtrue.me-gateway wsdlly02-srv:~/Documents/";
        rsync-findtrueme-tests = "rsync -avH --delete --exclude-from=$HOME/Documents/Life-Planning-Project/Project-A_Cash-Flow-Engine/findtrue.me-tests/exclude.txt ~/Documents/Life-Planning-Project/Project-A_Cash-Flow-Engine/findtrue.me-tests wsdlly02-srv:~/Documents/";
      };
    };
  };
}
