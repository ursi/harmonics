{ config, css-lib, ...}:
  let
    inherit (css-lib) merge;
    inherit (css-lib.media) geq;
    vars = css-lib.make-var-values config;
    desc = elem: styles: { extra-rules = c: { "${c} ${elem}" = styles; }; };
  in
  { variables =
      { font-size1 = "21px";
        gray1 = "gray";
      };

    rules =
      { ":root".font = "${vars.font-size1} sans-serif";

        body =
          { background = "black";
            color = "white";
          };

        select =
          { background = vars.gray1;
            font-size = vars.font-size1;
          };
      };

    classes."1" =
      let
        soundButtonSize = 112;
        soundButtonMargin = 15;
        soundButtonGridColumns = 8;
      in
      rec
      { center =
          { width = "100%";
            height = "100%";
            display = "flex";
            align-items = "center";
            justify-content = "center";
          };

        c1c =
          { display = "flex";
            flex-wrap = "wrap";
            max-width =
              toString
                (soundButtonGridColumns
                 * (soundButtonSize + 2 * soundButtonMargin)
                )
                + "px";
            user-select = "none";
            white-space = "pre";
          };

        c2c =
          { color = "black";
            width = toString soundButtonSize + "px";
            height = toString soundButtonSize + "px";
            background = vars.gray1;
            margin = toString soundButtonMargin + "px";
            text-align = "center";
            border-radius = "4px";
          };

        c3c =
          { background = vars.gray1;
            border = "none";
            font-size = vars.font-size1;
            width = "4.5em";
            ":focus".outline = "none";
            "::placeholder".color = "#555";
          };

        c4c =
          { display = "grid";
            width = "13em";

            extra-rules = c:
              { "${c} > *".margin-bottom = "1em"; };
          };

        c5c =
          { ${geq 707}.display = "flex";
            align-items = "start";
          };

        c6c =
          { display = "grid";
            grid-template-columns = "repeat(8, 1.4em)";
            gap = ".1em";
          };

        c7c =
          merge
            [ center
              { color = "black";
                background = "#873333";
                border-radius = ".15em";
                user-select = "none";
              }
            ];

        c8c = desc "input" { width = "2.3em"; };
        c9c = desc "input" { width = ".7em"; };
      };
  }
