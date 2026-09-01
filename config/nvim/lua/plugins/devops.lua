-- DevOps-tuned additions to stock LazyVim: theme match for the rest of the
-- Omarchy stack, smart-splits for tmux pane nav (tmux prefix is
-- C-a, unrelated to these <C-hjkl> which move the cursor across split
-- boundaries), and yaml/terraform/helm language support.
--
-- Kubernetes/Helm/Bicep LSP work already lives in the separate `ide`
-- profile (NVIM_APPNAME=ide, see the TUI IDE setup) -- this file is for
-- plain `nvim`, kept lighter on purpose.
return {
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, opts = { flavour = "mocha" } },
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },

  {
    "mrjones2014/smart-splits.nvim",
    opts = { at_edge = "wrap" },
    keys = {
      { "<C-h>", function() require("smart-splits").move_cursor_left() end },
      { "<C-j>", function() require("smart-splits").move_cursor_down() end },
      { "<C-k>", function() require("smart-splits").move_cursor_up() end },
      { "<C-l>", function() require("smart-splits").move_cursor_right() end },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "yaml", "hcl", "terraform", "dockerfile", "bash", "json", "toml", "helm",
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        yamlls = {
          settings = {
            yaml = { schemaStore = { enable = true } },
          },
        },
        terraformls = {},
        dockerls = {},
      },
    },
  },

  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    keys = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
  },

  { "folke/trouble.nvim", opts = {} },
  { "folke/todo-comments.nvim", opts = {} },
}
