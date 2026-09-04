overlay:

{ config, lib, ... }:

{
  imports = [ ./orange-pi-zero2w.nix ];

  config = lib.mkIf config.hardware.orangePiZero2W.enable {
    nixpkgs.overlays = lib.mkBefore [ overlay ];
  };
}
