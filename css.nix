{ config, css-lib, ...}:
  let
    inherit (css-lib) merge;
    vars = css-lib.make-var-values config;
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
      rec
      { center =
          { width = "100%";
            height = "100%";
            display = "flex";
            align-items = "center";
            justify-content = "center";
          };

        c1c =
          { display = "grid";
            grid-template-columns = "repeat(8, min-content)";
            user-select = "none";
            white-space = "pre";
          };

        c2c =
          { "--size" = "112px";
            color = "black";
            width = "var(--size)";
            height = "var(--size)";
            background = vars.gray1;
            margin = "15px";
            text-align = "center";
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

            extra-rules = c:
              { "${c} > *".margin-bottom = "1em"; };
          };

        c5c =
          { display = "flex";
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
      };
  }
