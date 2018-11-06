{ pkgs ? import <nixpkgs> { }, pythonPackages ? pkgs.python36Packages }:

pythonPackages.buildPythonPackage rec {
  pname = "spinsfast";
  version = "unstable-528606f06d0dcd06c78de77cd2eeef404136f0ca";

  src = pkgs.fetchFromGitHub {
    owner = "moble";
    repo = "spinsfast";
    rev = "528606f06d0dcd06c78de77cd2eeef404136f0ca";
    sha256 = "15hzrk2rji4v4qm26q8swyj4aqh8nsichybj6n12fwh067i8jzgf";
  };

  propagatedBuildInputs = [ pythonPackages.numpy pkgs.gsl pkgs.fftw ];

  FFTW3_HOME = pkgs.fftw;
  GSL_HOME = pkgs.gsl;

}
