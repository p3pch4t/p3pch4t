{ pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  packages = with pkgs; [ 
    dart
    flutter
    gnumake42
  ];
}
