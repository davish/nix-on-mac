{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
        url = "github:LnL7/nix-darwin";
        inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs }:
  let
    configuration = {pkgs, ... }: {
        
        services.nix-daemon.enable = true;
        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";
        
        system.configurationRevision = self.rev or self.dirtyRev or null;
        
        # Used for backwards compatibility. please read the changelog 
        # before changing: `darwin-rebuild changelog`.
        system.stateVersion = 4;
        
        # The platform the configuration will be used on.
        # If you're on an older system, replace with "x86_64-darwin"
        nixpkgs.hostPlatform = "aarch64-darwin"; 
        
        # Declare the user that will be running `nix-darwin`.
        users.users.$USER = {
            name = "$USER";
            home = "/Users/$USER";
        };

        security.pam.enableSudoTouchIdAuth = true;
        
        # Create /etc/zshrc that loads the nix-darwin environment. 
        programs.zsh.enable = true;
        environment.systemPackages = [ pkgs.neofetch ];

        homebrew = {
            enable = true;
            # onActivation.cleanup = "uninstall";

            taps = [];
            brews = [ "cowsay" ];
            casks = [];
        };
    };
  in
  {
    darwinConfigurations."$HOSTNAME" = nix-darwin.lib.darwinSystem {
      modules = [ 
         configuration
      ];
    };
  };
}