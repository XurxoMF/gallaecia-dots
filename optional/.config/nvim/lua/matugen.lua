 local M = {}

function M.setup()
  require('base16-colorscheme').setup({
    base00 = '#d3eaf8',
    base01 = '#c2e1f5',
    base02 = '#b9ddf3',
    base03 = '#6a889c',
    base04 = '#51565a',
    base05 = '#181a1b',
    base06 = '#181a1b',
    base07 = '#181a1b',
    base08 = '#fd4663',
    base09 = '#4b1a99',
    base0A = '#1d2eaf',
    base0B = '#2185c5',
    base0C = '#401683',
    base0D = '#165883',
    base0E = '#162283',
    base0F = '#1d2eaf',
  })

  local hi = function(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  hi('TelescopeNormal',         { fg = '#181a1b',          bg = '#d3eaf8' })
  hi('TelescopeBorder',         { fg = '#6a889c',             bg = '#d3eaf8' })
  hi('TelescopePromptNormal',   { fg = '#181a1b',          bg = '#d3eaf8' })
  hi('TelescopePromptBorder',   { fg = '#6a889c',             bg = '#d3eaf8' })
  hi('TelescopePromptPrefix',   { fg = '#2185c5',             bg = '#d3eaf8' })
  hi('TelescopePromptCounter',  { fg = '#51565a',  bg = '#d3eaf8' })
  hi('TelescopePromptTitle',    { fg = '#d3eaf8',             bg = '#2185c5' })
  hi('TelescopePreviewTitle',   { fg = '#d3eaf8',             bg = '#1d2eaf' })
  hi('TelescopeResultsTitle',   { fg = '#d3eaf8',             bg = '#4b1a99' })
  hi('TelescopeSelection',      { fg = '#181a1b',          bg = '#b9ddf3' })
  hi('TelescopeSelectionCaret', { fg = '#2185c5',             bg = '#b9ddf3' })
  hi('TelescopeMatching',       { fg = '#2185c5',             bold = true })
end

 -- Register a signal handler for SIGUSR1 (matugen updates)
 local signal = vim.uv.new_signal()
 signal:start(
   'sigusr1',
   vim.schedule_wrap(function()
     package.loaded['matugen'] = nil
     require('matugen').setup()
   end)
 )

 return M
