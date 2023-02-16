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
                     enums
                     halogen
                     integers
                     nullable
                     numbers
                     ordered-collections
                     record
                     safe-coerce
                     transformers
                     partial
                     ursi.prelude
                     web-events
                     web-html
                     web-uievents
                   ];

                 dir = ./.;
               };
           css = (nix-css ./css.nix).bundle;
         in
         { packages =
             { inherit css;
               default = ps.bundle {};
             };

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
                   alias watch="ls **/*.{purs,js,nix} | entr -s 'echo bundling; purs-nix bundle; nix build .#css; ln -fs result/main.css .'"
                   '';
               };
         }
      );
}
