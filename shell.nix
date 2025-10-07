with import <nixpkgs> {};

stdenv.mkDerivation {
    name = "node";
    buildInputs = [
      nodejs_24
      deno
    ];
    shellHook = ''
        export PATH="$PWD/node_modules/.bin/:$PATH"
    '';
}
