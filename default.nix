let
  # Pinning nixpkgs to specific release
  # To get sha256 use "nix-prefetch-git <url> --rev <commit>"
  commitRev="5574b6a152b1b3ae5f93ba37c4ffd1981f62bf5a";
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${commitRev}.tar.gz";
    sha256 = "1pqdddp4aiz726c7qs1dwyfzixi14shp0mbzi1jhapl9hrajfsjg";
  };
  pkgs = import nixpkgs { config = { allowUnfree = true; }; };
  pythonPackages = pkgs.python36Packages;

  python-spinsfast = import example4/spinsfast.nix { pythonPackages = pythonPackages; };
  my-local-hello-world = import example4/hello_world { };
in
pkgs.mkShell {
  buildInputs = [
    pythonPackages.numpy
    pythonPackages.scipy
    pythonPackages.jupyterlab
    python-spinsfast
    my-local-hello-world
  ];

  shellHook = ''
    if [ ! -f $HOME/.dockerbuildphase ]; then
      touch $HOME/.dockerbuildphase
      export DOCKER_BUILD_PHASE=true
    fi

    if [ "$DOCKER_BUILD_PHASE" = true ]; then
      echo "Do some action in build phase"
    fi

    if [ "$DOCKER_BUILD_PHASE" = false ]; then
      echo "Do some action in run phase like start db"
    fi

    echo "Do some action in both phases"
  '';
}
