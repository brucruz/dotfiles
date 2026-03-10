-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

function NvimTreeTrash()
  local lib = require 'nvim-tree.lib'
  local node = lib.get_node_at_cursor()
  local trash_cmd = 'trash '

  local function get_user_input_char()
    local c = vim.fn.getchar()
    return vim.fn.nr2char(c)
  end

  print('Trash ' .. node.name .. ' ? y/n')

  if get_user_input_char():match '^y' and node then
    vim.fn.jobstart(trash_cmd .. node.absolute_path, {
      detach = true,
      on_exit = function()
        lib.refresh_tree()
      end,
    })
  end

  vim.api.nvim_command 'normal :esc<CR>'
end

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
