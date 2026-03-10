return {
  'olimorris/codecompanion.nvim',
  config = true,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  opts = {
    strategies = {
      inline = {
        adapter = 'anthropic',
      },
      chat = {
        adapter = 'anthropic',
      },
    },

    adapters = {
      anthropic = function()
        return require('codecompanion.adapters').extend('anthropic', {
          env = {
            api_key = 'cmd:echo $ANTHROPIC_API_KEY',
          },
        })
      end,
    },
  },
}
