{ pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [ 
    flutter
    gnumake42
  ];
}
