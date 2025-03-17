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
        # overlays = [
        #   (final: prev: {
        #     python311Packages =
        #       prev.python311Packages
        #       // {
        #         ironcore-alloy = prev.python311Packages.buildPythonPackage rec {
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

      beir = pkgs.python311Packages.buildPythonPackage rec {
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
      bert-score = pkgs.python311Packages.buildPythonPackage rec {
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
      ironcore-alloy = pkgs.python311Packages.buildPythonPackage rec {
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
      };

      pythonEnv = pkgs.python311.withPackages (ps:
        with ps; [
          jupyter
          ipython
          ipykernel
          sentence-transformers
          numpy
          pip
          pandas
          scipy
          tokenizers
          sympy
          pyarrow
          python-dotenv
          ironcore-alloy
          nltk
          torch
          openai
          accelerate
          datasets
          einops
          evaluate
          optimum
          rouge-score
          sacrebleu
          tenacity
          tokenizers
          transformers
          bert-score
          beir
          wandb
        ]);
    in rec {
      devShell = pkgs.mkShell {
        nativeBuildInputs = [];
        buildInputs = with pkgs; [
          pythonEnv
          libffi
          # jupyterlab
          # ruff
        ];
        shellHook = ''
          export PIP_PREFIX=$(pwd)/_build/pip_packages #Dir where built packages are stored
          export PYTHONPATH="$PIP_PREFIX/${pythonEnv.sitePackages}:$PYTHONPATH"
          echo "home = $PIP_PREFIX/${pythonEnv.sitePackages}" > pyvenv.cfg
          echo "include-system-site-packages = false" >> pyvenv.cfg
          export PATH="$PIP_PREFIX/bin:$PATH"
          export JUPYTER_CONFIG_DIR="$PIP_PREFIX/jupyter"
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
