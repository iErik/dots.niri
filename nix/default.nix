self: wallpapers: { pkgs, lib, config, ... }: let

  inherit (lib) mkOption mkIf types;
  inherit (lib.hm.dag) entryAfter;
  inherit (config.home) username homeDirectory;

  cfg = config.dots.niri;
  dotsDir = "${homeDirectory}/${cfg.directory}";
  xdgConfDir = "${homeDirectory}/.config/niri";
  repoUrl = "git@github.com:iErik/dots.niri.git";

  wallpapersPackage = wallpapers.packages.${pkgs.system}.wallpapers;
  awwwPackage = wallpapers.inputs.awww.packages.${pkgs.system}.awww;

  wallpaperScript = pkgs.writeShellApplication {
    name = "wallpaper-switch";
    runtimeInputs = [ pkgs.jq awwwPackage ];
    text = ''
      WALLPAPERS_DIR="${wallpapersPackage}"
    '' + builtins.readFile ./wallpaper-switch.sh;
  };

  wallpaperInitScript = pkgs.writeShellApplication {
    name = "wallpaper-init";
    runtimeInputs = [ pkgs.jq awwwPackage ];
    text = ''
      WALLPAPERS_DIR="${wallpapersPackage}"
    '' + builtins.readFile ./wallpaper-init.sh;
  };

in {
  imports = [ wallpapers.homeManagerModules.default ];

  options.dots.niri = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Niri Dotfiles module";
    };

    cloneConfig = mkOption {
      type = types.bool;
      default = true;
      description =
        "Whether or not to clone the Dotfiles" +
        "repository to the user's directory";
    };

    directory = mkOption {
      type = types.str;
      default = "Dots/Niri.dots";
      description =
        "The path of the directory in which to " +
        "store the dotfiles (relative to the " +
        "user's home directory).";
    };

    branch = mkOption {
      type = types.str;
      default = "master";
      description =
        "The branch to use as source for the dotfiles";
    };

    wallpapers = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable the Wallpapers module";
      };
    };
  };

  config = mkIf cfg.enable {
    dots.wallpapers = mkIf cfg.wallpapers.enable {
      enable = true;
      awww.enable = true;
      location = "~/Dots/Wallpapers";
    };

    home.packages = [
      pkgs.swaynotificationcenter
    ] ++ lib.optionals cfg.wallpapers.enable [
      wallpaperScript
      wallpaperInitScript
    ];

    systemd.user.services.wallpaper-init = mkIf cfg.wallpapers.enable {
      Unit = {
        Description = "Set a random wallpaper on session start";
        After = [ "awww.service" "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${wallpaperInitScript}/bin/wallpaper-init";
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    home.file."Dots/Niri.dots/wallpaper-keys.kdl".text =
      lib.optionalString cfg.wallpapers.enable ''
        binds {
          Mod+Period { spawn "${wallpaperScript}/bin/wallpaper-switch" "next" "image"; }
          Mod+Comma { spawn "${wallpaperScript}/bin/wallpaper-switch" "prev" "image"; }
          Mod+Alt+Period { spawn "${wallpaperScript}/bin/wallpaper-switch" "next" "folder"; }
          Mod+Alt+Comma { spawn "${wallpaperScript}/bin/wallpaper-switch" "prev" "folder"; }
        }
      '';

    home.activation.niriSetup = mkIf cfg.cloneConfig
      (entryAfter ["writeBoundary"] ''
        export PATH=${pkgs.openssh}/bin:$PATH
        export PATH=${pkgs.git}/bin:$PATH

        eval $(ssh-agent -s)
        ssh-add

        if [ -d "${dotsDir}/.git" ];
        then
          cd ${dotsDir} && git pull origin ${cfg.branch}
        else
          rm -rf ${dotsDir}
          rm -rf ${xdgConfDir}

          git clone -b ${cfg.branch} --single-branch ${repoUrl} ${dotsDir}

          chown -R ${username}:users ${dotsDir}
          find ${dotsDir} -type d -exec chmod 744 {} \;
          find  ${dotsDir} -type f -exec chmod 644 {} \;

          ln -s ${dotsDir} ${xdgConfDir}
        fi

        ssh-agent -k
      '');
  };
}
