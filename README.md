# [Nixpkgs](https://github.com/nixos/nixpkgs) BinderHub example

[![Binder](https://mybinder.org/badge.svg)](https://mybinder.org/v2/gh/costrouc/nix-binder-example/master)

# Why Nix?

[Nix](https://github.com/nixos/nixpkgs) would be a great addition to reproducible data science. It is a unique package manager. Some notable features:

 - 100% reproducible environments (pin to exact commit in repository)
 - both a source and binary package repository
 - allows customized compilation and version of every package
 - can run identical environment outside of docker (all linux distros + dawin)
 - as of now [45,000+ packages](https://repology.org/repositories/statistics/total)
 - fully declarative environments
 - packages: python, javascript, julia, R, haskell, perl, and many other languages (some better than others).

Assuming that you have [`nix`
installed](https://nixos.org/nix/download.html) (compatible with all
linux distributions and darwin (Mac OS)) you can run this repository
locally (no need for binderhub). It will be identical assuming you
have pinned repositories. Nix can coexist fine with other package
managers.

```
# <path to default.nix> is optional if in current directory
nix-shell <path to default.nix> --run "jupyter lab"
```

# Example 1

Lets start with the simplest `default.nix` I can imagine.

```nix
{ pkgs ? import <nixpkgs> { }, pythonPackages ? pkgs.python36Packages }:

pkgs.mkShell {
  buildInputs = [
    pythonPackages.numpy 
    pythonPackages.scipy
    pythonPackages.jupyterlab
  ];
}
```

This will give you `python 3.6` with `jupyterlab`, `scipy`, and
`numpy` installed. However there is one downside to this simple
expression. The [packages within the `nixpkgs` derivations are not
pinned](https://vaibhavsagar.com/blog/2018/05/27/quick-easy-nixpkgs-pinning/).
This means that you have no guarantee of reproducibility and fixed
versions. Don't worry this can be easily fixed and is why this is not
the recommended way. Also while this demonstration only shows python
packages nix has many more. For example [searching
nixpkgs](https://nixos.org/nixos/packages) you could add
`pkgs.google-cloud-sdk` and `pkgs.nodejs`.

# Example 2 (with shellHook)

```nix
{ pkgs ? import <nixpkgs> { }, pythonPackages ? pkgs.python36Packages }:

pkgs.mkShell {
  buildInputs = [
    pythonPackages.numpy 
    pythonPackages.scipy
    pythonPackages.jupyterlab
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
      echo "Do some action in run phase"
    fi
    
    echo "Do some action in both phases"
  '';
}
```

Exactly the same example one except now we are able to execute shell
commands before launching `jupyter`. This can include anything you can
imagine but it will be run as a normal user (not root). A quick caveat
with the `shellHooks` is that they are actually run twice. Once in the
build phase (so that all of the `nixpkgs` dependencies are built and
cached. And a second time to start a
[nix-shell](https://nixos.org/nix/manual/#sec-nix-shell). I highly
recommend that you do not put state into your `shellHook`. However,
sometimes this is unavoidable when you want to start a database for
instance before launching `jupyter lab`.

# Example 3 (with pinned packages)

```nix
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
in
pkgs.mkShell {
  buildInputs = [
    pythonPackages.numpy 
    pythonPackages.scipy
    pythonPackages.jupyterlab
  ];
  
  shellHook = ''
    echo "execute any bash commands before starting jupyterlab";
  '';
}
```

Like before `python 36` will be installed with `jupyterlab`, `numpy`,
and `scipy`. All this extra work guarantees that the versions of every
package and configuration are pinned and fully reproducible to a git
commit. `allowUnfree = true;` allows you to include unfree software in
your environment.

# Example 4 (Using nix for package building from source)

```nix
{ pkgs ? import <nixpkgs> { }, pythonPackages ? python36Packages }:

pythonPackages.buildPythonPackage {
  pname = "spinsfast";
  version = "unstable-528606f06d0dcd06c78de77cd2eeef404136f0ca";
  
  src = fetchFromGitHub {
    owner = "moble";
    repo = "spinsfast";
    rev = "528606f06d0dcd06c78de77cd2eeef404136f0ca";
    sha256 = "15hzrk2rji4v4qm26q8swyj4aqh8nsichybj6n12fwh067i8jzgf";
  };
  
  propagatedBuildInputs = [ pythonPackages.numpy pkgs.gsl pkgs.fftw ];
  
  FFTW3_HOME = pkgs.fftw;
  GSL_HOME = pkgs.gsl;
}
```

```nix
{ pkgs ? import <nixpkgs> { }, pythonPackages ? pkgs.python36Packages }:

let
   python-spinsfast = import example4/spinsfast.nix { };
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
}
```

Previously I have shown nix as a configuration tool for package
management but it is also a great tool for building
packages. Sometimes nixpkgs may not have the package that you want,
might not have the most recent unstable release, or you need to
package software that exists somewhere in a repository. Nixpkgs can
handle all of this. [spinsfasts](https://github.com/moble/spinsfast)
is a random project that I picked off of `pypi trending repositories`
and yet the build derivation is quite simple. I wanted to also show
that you can package local files (see `hello_world` and I set `src =
./.`). Nix will never rebuild a package if the configuration does not
change and it exists in the cache (`/nix/store/...`). Notice that this
means to nix there is no difference between a monorepo or distributed
repositories. A huge win for developers.

# Documentation and Further Reading

This README was not designed to teach you to fully understand how nix
works. Instead there is much better documentation below including blog
posts. Nix can be confusing becuase there are many pieces: `nixpkgs`
(packages), `nix` (the language), `nixos` (the operating system fully
configured with nix).

Contributions to [nixpkgs](https://github.com/nixos/nixpkgs) are
always welcome and I am proud to say that we have a welcoming
community.

  - [search for available packages](https://nixos.org/nixos/packages.html)
  - [great tutorial on nix language](http://www.binaryphile.com/nix/2018/07/22/nix-language-primer.html)
  - [nix language manual](https://nixos.org/nix/manual/)
  - [nixpkgs manual](https://nixos.org/nixpkgs/manual/)
