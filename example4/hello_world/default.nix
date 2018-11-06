{ pkgs ? import <nixpkgs> { } }:

pkgs.stdenv.mkDerivation rec {
  name = "my-hello-world-${version}";
  version = "unstable-foobarbaz";

  src = ./.;

  installPhase = ''
    make install PREFIX=$out
  '';
}
