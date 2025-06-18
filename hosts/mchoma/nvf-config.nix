{
  description = "Minimal Neovim config with LSP and Treesitter using NVF";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = { self, nixpkgs, flake-utils, neovim-nightly-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ neovim-nightly-overlay.overlay ];
        };

        plugins = with pkgs.vimPlugins; [
          lazy-nvim
          nvim-lspconfig
          nvim-treesitter.withAllGrammars
          mason-nvim
          mason-lspconfig-nvim
        ];

        myNeovim = pkgs.wrapNeovim pkgs.neovim-nightly {
          configure = {
            customRC = ''
              set number
              syntax on

              lua << EOF
              require("lazy").setup({
                { "neovim/nvim-lspconfig" },
                { "williamboman/mason.nvim" },
                { "williamboman/mason-lspconfig.nvim" },
                { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
              })

              require("mason").setup()
              require("mason-lspconfig").setup {
                ensure_installed = { "clangd", "lua_ls", "nil_ls" }
              }

              local lspconfig = require("lspconfig")
              lspconfig.clangd.setup {}
              lspconfig.lua_ls.setup {}
              lspconfig.nil_ls.setup {}
              EOF
            '';
            packages.myPlugins = plugins;
          };
        };
      in {
        packages.default = myNeovim;
      }
    );
}

