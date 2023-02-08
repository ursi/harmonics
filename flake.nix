{ inputs =
    { nix-css.url = "github:ursi/nix-css";
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      ps-tools.follows = "purs-nix/ps-tools";
      purs-nix.url = "github:purs-nix/purs-nix/ps-0.15";
      utils.url = "github:ursi/flake-utils/8";
    };

  outputs = { ... }@inputs:
    inputs.utils.apply-systems { inherit inputs; }
      ({ nix-css, pkgs, purs-nix, ps-tools, ... }:
         let
           ps =
             purs-nix.purs
               { dependencies =
                   let inherit (purs-nix.ps-pkgs-ns) ursi; in
                   with purs-nix.ps-pkgs;
                   [ aff
                     datetime
                     halogen
                     integers
                     nullable
                     numbers
                     record
                     transformers
                     ursi.prelude
                     web-events
                     web-html
                   ];

                 dir = ./.;
               };
           css = (nix-css ./css.nix).bundle;
         in
         { packages.default = ps.bundle {};

           devShells.default =
             pkgs.mkShell
               { packages =
                   with pkgs;
                   [ entr
                     nodejs
                     (ps.command { bundle.esbuild.format = "iife"; })
                     ps-tools.for-0_15.purescript-language-server
                     purs-nix.esbuild
                     purs-nix.purescript
                   ];

                 shellHook =
                   ''
                   alias watch="find src | entr -s 'echo bundling; purs-nix bundle; ln -fs ${css}/main.css .'"
                   '';
               };
         }
      );
}
