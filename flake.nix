{ inputs =
    { nix-css.url = "github:ursi/nix-css";
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      ps-tools.follows = "purs-nix/ps-tools";
      purs-nix.url = "github:purs-nix/purs-nix/ps-0.15";
      shelpers.url = "gitlab:platonic/shelpers";
      utils.url = "github:ursi/flake-utils/8";
    };

  outputs = { ... }@inputs:
    inputs.utils.apply-systems { inherit inputs; }
      ({ nix-css, pkgs, purs-nix, ps-tools, system, ... }:
         let
           p = pkgs;
           packages = inputs.self.packages.${system};

           ps =
             purs-nix.purs
               { dependencies =
                   [ "aff"
                     "datetime"
                     "enums"
                     "halogen"
                     "integers"
                     "nullable"
                     "numbers"
                     "ordered-collections"
                     "record"
                     "safe-coerce"
                     "transformers"
                     "partial"
                     "ursi.prelude"
                     "web-events"
                     "web-html"
                     "web-uievents"
                   ];

                 dir = ./.;
               };

           css = (nix-css ./css.nix).bundle;
           inherit (inputs.shelpers.lib p) eval-shelpers shelp;

           shelpers =
             eval-shelpers
               [ ({ config, ... }:
                    { shelpers.".".General =
                        { deploy =
                            { description = "deploy to github pages";
                              cache = false;
                              script =
                                ''
                                git checkout -B pages
                                rm docs -rf

                                # the only custom directory gh pages allows you to deploy from
                                mkdir docs

                                echo '!docs/*' >> .gitignore
                                cp -Lr --no-preserve=mode ${packages.default}/. docs
                                git add .gitignore docs
                                git commit -m "github pages"
                                git push -fu origin pages
                                git co master
                                '';
                            };

                          watch =
                            { description = "build the app and watch for changes";
                              script =
                                ''
                                ls **/*.{purs,js,nix} | entr -s '
                                  echo bundling
                                  purs-nix bundle
                                  nix build .#css
                                  ln -fs result/main.css .
                                  '
                                '';
                            };

                          shelp = shelp config;
                        };
                    })
               ];
         in
         { packages =
             { default =
                 p.runCommand "harmonics" {}
                   ''
                   mkdir $out; cd $_
                   ln -s ${./index.html} index.html
                   ln -s ${packages.bundle} main.js
                   ln -s ${packages.css}/main.css .
                   '';

               inherit css;
               bundle = ps.bundle { esbuild.format = "iife"; };
             };

           devShells.default =
             p.mkShell
               { packages =
                   with p;
                   [ entr
                     nodejs
                     (ps.command { bundle.esbuild.format = "iife"; })
                     ps-tools.for-0_15.purescript-language-server
                     purs-nix.esbuild
                     purs-nix.purescript
                   ];

                 shellHook =
                   ''
                   ${shelpers.functions}
                   shelp
                   '';
               };

           inherit (shelpers) apps;
           shelpers = shelpers.files;
         }
      );
}
