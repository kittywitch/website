with (import <nixpkgs> {});
let env = bundlerEnv {
    name = "kat-site";
    inherit ruby;
    gemfile = ./Gemfile;
    lockfile = ./Gemfile.lock;
    gemset = ./gemset.nix;
  };
in stdenv.mkDerivation {
  name = "kat-site";
  buildInputs = [env bundler ruby];
}