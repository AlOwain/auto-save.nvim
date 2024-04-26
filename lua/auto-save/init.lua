local M = {}

local config = require("auto-save.config")

---@param filetype string
---@return boolean
local function excluded_ft(filetype)
  for _, v in ipairs(config.exclude_ft) do
    if filetype == v then
      return true
    end
  end
  return false
end

---@param filetype string
---@return boolean
local function included_ft(filetype)
  if next(config.include_ft) == nil then
    return true
  end
  for _, v in ipairs(config.include_ft) do
    if filetype == v then
      return true
    end
  end
  return false
end

---@param bufnr integer
---@return boolean
local function can_save(bufnr)
  local is_modifiable = vim.fn.getbufvar(bufnr, "&modifiable") == 1
  local is_readonly = vim.fn.getbufvar(bufnr, "&readonly") == 1
  local buftype = vim.api.nvim_buf_get_option(bufnr, "buftype")
  local is_modified = vim.api.nvim_buf_get_option(bufnr, "modified")
  local excluded = excluded_ft(vim.api.nvim_buf_get_option(bufnr, "filetype"))
  local included = included_ft(vim.api.nvim_buf_get_option(bufnr, "filetype"))
  local is_named = vim.fn.bufname() ~= ""

  return is_modifiable
    and not is_readonly
    and buftype == ""
    and is_modified
    and included
    and not excluded
    and is_named
end

local function create_autocmd()
  -- Write buffer when leaving Insert mode
  vim.api.nvim_create_autocmd(config.events, {
    group = vim.api.nvim_create_augroup(config.augroup_name, { clear = true }),
    pattern = "*",
    callback = function(args)
      if can_save(args.buf or vim.api.nvim_get_current_buf()) then
        if config.timeout ~= nil then
          if M.save_timer ~= nil then
            M.save_timer:stop()
            ---@diagnostic disable-next-line: param-type-mismatch
            M.save_timer = vim.defer_fn(config.save_fn, config.timeout)
          else
            M.save_timer = vim.defer_fn(config.save_fn, config.timeout)
          end
        else
          config.save_fn()
        end
      end
    end,
  })
end

function M.setup(opts)
  if opts then
    config.augroup_name = opts.augroup_name or config.augroup_name
    config.events = opts.events or config.events
    config.silent = opts.silent
    config.save_cmd = opts.save_cmd or config.save_cmd
    config.save_fn = opts.save_fn or config.save_fn
    config.timeout = opts.timeout or config.timeout
    config.exclude_ft = opts.exclude_ft or config.exclude_ft
    config.include_ft = opts.include_ft or config.include_ft
  end

  create_autocmd()
end

return M
