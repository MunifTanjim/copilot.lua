local M = {}

local id = 0
function M.get_next_id()
  id = id + 1
  return id
end

-- keep for debugging reasons
M.get_editor_info = function ()
  local info = vim.empty_dict()
  info.editorInfo = vim.empty_dict()
  info.editorInfo.name = 'Neovim'
  info.editorInfo.version = '0.8.0-dev-809-g7dde6d4fd'
  info.editorPluginInfo = vim.empty_dict()
  info.editorPluginInfo.name = 'copilot.vim'
  info.editorPluginInfo.version = '1.5.3'
  return info
end

-- keep for debugging reasons
local get_capabilities = function ()
  return {
    capabilities = {
      textDocumentSync = {
        change = 2,
        openClose = true
      },
      workspace = {
        workspaceFolders = {
          changeNotifications = true,
          supported = true
        }
      }
    }
  }
end

local format_pos = function()
  local pos = vim.api.nvim_win_get_cursor(0)
  return { character = pos[2], line = pos[1] - 1 }
end

local get_relfile = function()
  local file, _ = string.gsub(vim.api.nvim_buf_get_name(0), vim.loop.cwd() .. "/", "")
  return file
end

M.get_copilot_client = function()
 --  vim.lsp.get_active_clients({name="copilot"}) -- not in 0.7
  for _, client in pairs(vim.lsp.get_active_clients()) do
    if client.name == "copilot" then return client end
  end
end

local eol_by_fileformat = {
  unix = "\n",
  dos = "\r\n",
  mac = "\r",
}

local language_normalization_map = {
  text = "plaintext",
  javascriptreact = "javascript",
  jsx = "javascript",
  typescriptreact = "typescript",
}

local function language_for_file_type(filetype)
  local ft = string.gsub(filetype, "%..*", "")
  if not ft or ft == "" then
    ft = "text"
  end
  return language_normalization_map[ft] or ft
end

local function relative_path(absolute)
  local relative = vim.fn.fnamemodify(absolute, ":.")
  if string.sub(relative, 0, 1) == "/" then
    return vim.fn.fnamemodify(absolute, ":t")
  end
  return relative
end

function M.get_doc()
  local absolute = vim.api.nvim_buf_get_name(0)
  local params = vim.lsp.util.make_position_params(0, "utf-16")
  local doc = {
    languageId = language_for_file_type(vim.bo.filetype),
    path = absolute,
    uri = params.textDocument.uri,
    relativePath = relative_path(absolute),
    insertSpaces = vim.o.expandtab,
    tabSize = vim.fn.shiftwidth(),
    indentSize = vim.fn.shiftwidth(),
    position = params.position,
  }

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  if vim.bo.endofline and vim.bo.fixendofline then
    table.insert(lines, "")
  end
  doc.source = table.concat(lines, eol_by_fileformat[vim.bo.fileformat] or "\n")

  return doc
end

function M.get_doc_params(params)
  params = params or {}
  local doc_params = vim.tbl_extend("keep", {
    doc = vim.tbl_extend("force", M.get_doc(), params.doc or {}),
  }, params)

  doc_params.textDocument = {
    uri = doc_params.doc.uri,
    languageId = doc_params.doc.languageId,
    relativePath = doc_params.doc.relativePath,
    position = doc_params.doc.position,
  }

  return doc_params
end

M.get_completion_params = function(opts)
  local rel_path = get_relfile()
  local uri = vim.uri_from_bufnr(0)
  local params = {
    doc = {
      source = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"),
      relativePath = rel_path,
      languageId = normalize_ft(vim.api.nvim_buf_get_option(0, 'filetype')),
      insertSpaces = vim.o.expandtab,
      tabsize = vim.bo.shiftwidth,
      indentsize = vim.bo.shiftwidth,
      position = format_pos(),
      path = vim.api.nvim_buf_get_name(0),
      uri = uri,
    },
    textDocument = {
      languageId = vim.bo.filetype,
      relativePath = rel_path,
      uri = uri,
    }
  }
  params.position = params.doc.position
  if opts then params.doc = vim.tbl_deep_extend('keep', params.doc, opts) end
  return params
end

M.get_copilot_path = function(plugin_path)
  for _, loc in ipairs({ "/opt", "/start", "" }) do
    local copilot_path = plugin_path .. loc .. "/copilot.lua/copilot/index.js"
    if vim.fn.filereadable(copilot_path) ~= 0 then
      return copilot_path
    end
  end
end

M.auth = function ()
  local c = M.get_copilot_client()
  if not c then
    print("[Copilot] not running yet!")
    return
  end
  require("copilot.auth").setup(c)
end


return M
