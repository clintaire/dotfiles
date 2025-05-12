-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- You can also add or configure plugins by creating files in this `plugins/` folder
-- PLEASE REMOVE THE EXAMPLES YOU HAVE NO INTEREST IN BEFORE ENABLING THIS FILE
-- Here are some examples:

---@type LazySpec
return {

  -- == Examples of Adding Plugins ==

  "andweeb/presence.nvim",
  {
    "ray-x/lsp_signature.nvim",
    event = "BufRead",
    config = function() require("lsp_signature").setup() end,
  },

  -- Add Ollama integration for local Mistral model
  {
    "nomnivore/ollama.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      model = "mistral", -- specify the model you want to use
      url = "http://127.0.0.1:11434", -- your Ollama server URL
      prompts = {
        -- Customize as needed
        Completion = {
          prompt = "Complete this code: $sel",
          model = "mistral:latest", -- use specific version
        },
      }
    },
    -- Add keybindings for completion
    keys = {
      {
        "<leader>oc",
        function()
          require("ollama").completion()
        end,
        desc = "Ollama Completion",
      },
      {
        "<leader>op",
        function()
          require("ollama").prompt()
        end,
        desc = "Ollama Prompt",
      },
    },
  },

  -- Add custom commands to run code in terminal
  {
    "toggleterm.nvim",
    keys = {
      -- Run current file based on filetype
      { "<F5>", function()
        local file = vim.fn.expand("%:p")
        local cmd = ""

        local ft = vim.bo.filetype
        if ft == "python" then
          cmd = "python " .. file
        elseif ft == "rust" then
          cmd = "cd $(dirname " .. file .. ") && cargo run"
        elseif ft == "javascript" or ft == "typescript" then
          cmd = "node " .. file
        elseif ft == "sh" or ft == "bash" then
          cmd = "bash " .. file
        end

        if cmd ~= "" then
          require("toggleterm").exec(cmd)
        else
          vim.notify("No run command for filetype: " .. ft)
        end
      end, desc = "Run current file" },
    },
  },

  -- == Examples of Overriding Plugins ==

  -- customize dashboard options
  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = table.concat({
            " █████  ███████ ████████ ██████   ██████ ",
            "██   ██ ██         ██    ██   ██ ██    ██",
            "███████ ███████    ██    ██████  ██    ██",
            "██   ██      ██    ██    ██   ██ ██    ██",
            "██   ██ ███████    ██    ██   ██  ██████ ",
            "",
            "███    ██ ██    ██ ██ ███    ███",
            "████   ██ ██    ██ ██ ████  ████",
            "██ ██  ██ ██    ██ ██ ██ ████ ██",
            "██  ██ ██  ██  ██  ██ ██  ██  ██",
            "██   ████   ████   ██ ██      ██",
          }, "\n"),
        },
      },
    },
  },

  -- You can disable default plugins as follows:
  { "max397574/better-escape.nvim", enabled = false },

  -- You can also easily customize additional setup of plugins that is outside of the plugin's setup call
  {
    "L3MON4D3/LuaSnip",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.luasnip"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom luasnip configuration such as filetype extend or custom snippets
      local luasnip = require "luasnip"
      luasnip.filetype_extend("javascript", { "javascriptreact" })
    end,
  },

  {
    "windwp/nvim-autopairs",
    config = function(plugin, opts)
      require "astronvim.plugins.configs.nvim-autopairs"(plugin, opts) -- include the default astronvim config that calls the setup call
      -- add more custom autopairs configuration such as custom rules
      local npairs = require "nvim-autopairs"
      local Rule = require "nvim-autopairs.rule"
      local cond = require "nvim-autopairs.conds"
      npairs.add_rules(
        {
          Rule("$", "$", { "tex", "latex" })
            -- don't add a pair if the next character is %
            :with_pair(cond.not_after_regex "%%")
            -- don't add a pair if  the previous character is xxx
            :with_pair(
              cond.not_before_regex("xxx", 3)
            )
            -- don't move right when repeat character
            :with_move(cond.none())
            -- don't delete if the next character is xx
            :with_del(cond.not_after_regex "xx")
            -- disable adding a newline when you press <cr>
            :with_cr(cond.none()),
        },
        -- disable for .vim files, but it work for another filetypes
        Rule("a", "a", "-vim")
      )
    end,
  },
}
