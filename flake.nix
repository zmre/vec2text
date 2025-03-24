{
  # this would be better if it could build beir, but it can't for some reason
  description = "Devshell for running inversions.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    # jupyenv.url = "github:tweag/jupyenv";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    flake-compat,
    # jupyenv,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      # inherit (jupyenv.lib.${system}) mkJupyterlabNew;
      # jupyterlab = mkJupyterlabNew ({...}: {
      #   inherit nixpkgs;
      #   imports = [(import ./kernels.nix)];
      # });
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true; # for torch-bin
        # overlays = [
        #   (final: prev: {
        #     python312Packages =
        #       prev.python312Packages
        #       // {
        #         ironcore-alloy = prev.python312Packages.buildPythonPackage rec {
        #           pname = "ironcore_alloy";
        #           version = "0.11.2";
        #           src = prev.fetchPypi {
        #             inherit pname version;
        #             sha256 = "sha256-D7GctK4LLxAXQytWEh/dV8RD7v3uOU2lX3+MTFriOys=";
        #             #sha256 = prev.lib.fakeSha256;
        #           };
        #           doCheck = false;
        #           propagatedBuildInputs = [
        #             prev.cacert
        #           ];
        #         };
        #       };
        #   })
        # ];
      };

      beir = pkgs.python312Packages.buildPythonPackage rec {
        pname = "beir";
        version = "2.1.0";
        format = "wheel";
        src = pkgs.fetchPypi {
          inherit pname version;
          format = "wheel";
          #sha256 = pkgs.lib.fakeSha256;
          sha256 = "sha256-6jabehxIS48mKOEUNdKIfHXR+cT3DWcvqI/dBIrcueU=";
          python = "py3";
          platform = "any";
          dist = "py3";
        };
        doCheck = false;
        propagatedBuildInputs = [
          pkgs.cacert
        ];
      };
      bert-score = pkgs.python312Packages.buildPythonPackage rec {
        pname = "bert_score";
        version = "0.3.13";
        format = "wheel";
        src = pkgs.fetchPypi {
          inherit pname version;
          format = "wheel";
          #sha256 = pkgs.lib.fakeSha256;
          sha256 = "sha256-u7tMf82qRtdoGv9J83+W+qCe104bFQ5lm9xrWKZpibk=";
          python = "py3";
          platform = "any";
          dist = "py3";
        };
        doCheck = false;
        propagatedBuildInputs = [
          pkgs.cacert
        ];
      };
      ironcore-alloy =
        if pkgs.stdenvNoCC.isDarwin
        then
          (
            pkgs.python312Packages.buildPythonPackage rec {
              pname = "ironcore_alloy";
              version = "0.11.2";
              format = "wheel";
              src = pkgs.fetchPypi {
                inherit pname version;
                format = "wheel";
                #sha256 = pkgs.lib.fakeSha256;
                sha256 = "sha256-D7GctK4LLxAXQytWEh/dV8RD7v3uOU2lX3+MTFriOys="; #mac
                python = "py3";
                platform = "macosx_11_0_arm64";
                dist = "py3";
              };
              doCheck = false;
              propagatedBuildInputs = [
                pkgs.cacert
              ];
            }
          )
        else
          (
            pkgs.python312Packages.buildPythonPackage rec {
              pname = "ironcore_alloy";
              version = "0.11.2";
              format = "wheel";
              src = pkgs.fetchPypi {
                inherit pname version;
                format = "wheel";
                #sha256 = pkgs.lib.fakeSha256;
                #sha256 = "sha256-D7GctK4LLxAXQytWEh/dV8RD7v3uOU2lX3+MTFriOys="; #mac
                sha256 = "sha256-DQlD/x3WLQH1EsFf5pb6ai262vpleI0Y0MrYCKQfQuQ="; #linux
                python = "py3";
                #platform = "macosx_11_0_arm64";
                platform = "manylinux_2_17_x86_64.manylinux2014_x86_64";
                dist = "py3";
              };
              doCheck = false;
              propagatedBuildInputs = [
                pkgs.cacert
              ];
            }
          );

      pythonEnv = pkgs.python312.withPackages (ps:
        with ps; [
          accelerate
          beir
          bert-score
          datasets
          einops
          evaluate
          ipykernel
          ipython
          ironcore-alloy
          jupyter
          nltk
          numpy
          openai
          optimum
          pandas
          pip
          pyarrow
          python-dotenv
          pytorch
          rouge-score
          sacrebleu
          scipy
          sentence-transformers
          setuptools
          sympy
          tenacity
          tokenizers
          torch
          transformers
          wandb
        ]);
    in rec {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [];
        buildInputs = with pkgs;
          [
            pythonEnv
            libffi
            python312Packages.torch-bin
            # jupyterlab
            # ruff
          ]
          ++ (pkgs.lib.optionals pkgs.stdenvNoCC.isDarwin
            (with pkgs.darwin.apple_sdk_12_3.frameworks; [
              Accelerate
              CoreGraphics
              CoreVideo
              Foundation
              Metal
              MetalKit
              MetalPerformanceShaders
              MetalPerformanceShadersGraph
              pkgs.apple-sdk_13
            ]));
        shellHook = ''
          export PIP_PREFIX=$(pwd)/_build/pip_packages #Dir where built packages are stored
          export PYTHONPATH="$PIP_PREFIX/${pythonEnv.sitePackages}:$PYTHONPATH"
          echo "home = $PIP_PREFIX/${pythonEnv.sitePackages}" > pyvenv.cfg
          echo "include-system-site-packages = false" >> pyvenv.cfg
          export PATH="$PIP_PREFIX/bin:$PATH"
          export JUPYTER_CONFIG_DIR="$PIP_PREFIX/jupyter"
          export PYTHONPATH="$PYTHONPATH:$(pwd)"
          unset SOURCE_DATE_EPOCH
        '';
      };
      packages.python = pythonEnv;
      packages.default = packages.python;
      apps.jupyter = flake-utils.lib.mkApp {
        drv = packages.python;
        name = "jupyter";
        exePath = "/bin/jupyter";
      };

      apps.default = apps.jupyter;
      # vscode needs jupyter launched with specific parameters, but I'm not sure how to pass them
      # apps.default.program = "{pythonEnv}/bin/jupyter notebook --no-browser --NotebookApp.allow_origin='*'";
      # apps.default.type = "app";
    });
}
