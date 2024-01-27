{
  description = "My system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mac-app-util.url = "github:hraban/mac-app-util";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , nix-darwin
    , home-manager
    , mac-app-util
    , nix-vscode-extensions
    }:
    let
      configuration = { pkgs, ... }: {
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
        nixpkgs.config.allowUnfree = true;

        nixpkgs.overlays = [
          nix-vscode-extensions.overlays.default
        ];

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

          taps = [ ];
          brews = [ "cowsay" ];
          casks = [ ];
        };
      };
      homeconfig = { pkgs, ... }: {
        # this is internal compatibility configuration for home-manager, 
        # don't change this!
        home.stateVersion = "23.05";
        # Let home-manager install and manage itself.
        programs.home-manager.enable = true;

        home.packages = with pkgs;[
          nixpkgs-fmt
          coreutils-full
        ];

        home.sessionVariables = {
          EDITOR = "vim";
        };

        home.file.".vimrc".source = ./vim_configuration;

        programs.zsh = {
          enable = true;
          shellAliases = {
            switch = "darwin-rebuild switch --flake ~/.config/nix";
          };
        };

        programs.git = {
          enable = true;
          userName = "$FIRSTNAME $LASTNAME";
          userEmail = "me@example.com";
          ignores = [ ".DS_Store" ];
          extraConfig = {
            init.defaultBranch = "main";
            push.autoSetupRemote = true;
          };
        };
        programs.vscode = {
          enable = true;

          userSettings = {
            # This property will be used to generate settings.json:
            # https://code.visualstudio.com/docs/getstarted/settings#_settingsjson
            "editor.formatOnSave" = true;
            "workbench.colorTheme" = "Dracula Theme";
          };
          keybindings = [
            # See https://code.visualstudio.com/docs/getstarted/keybindings#_advanced-customization
            {
              key = "shift+cmd+j";
              command = "workbench.action.focusActiveEditorGroup";
              when = "terminalFocus";
            }
          ];

          # Some extensions require you to reload vscode, but unlike installing
          # from the marketplace, no one will tell you that. So after running
          # `darwin-rebuild switch`, make sure to restart vscode!
          extensions = with pkgs.vscode-marketplace; [
            # Search for vscode-extensions on https://search.nixos.org/packages
            dracula-theme.theme-dracula
            jnoortheen.nix-ide
            vscodevim.vim
          ];
        };
      };
    in
    {
      darwinConfigurations."$HOSTNAME" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          mac-app-util.darwinModules.default
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.verbose = true;

            home-manager.sharedModules = [
              mac-app-util.homeManagerModules.default
            ];

            home-manager.users.$USER = homeconfig;
          }
        ];
      };
    };
}

