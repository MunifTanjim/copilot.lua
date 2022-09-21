local util = require("copilot.util")

local panel = {
  usecmp = false,
  client = {},
  buf = "",
  uri = "copilot:///placeholder",
  requests = {},
}

panel.send_request = function (opts)
  opts = opts or {}
  local client = opts.client or not vim.tbl_isempty(panel.client) and panel.client or util.get_copilot_client()
  if not panel.client then return end
  local params = util.get_doc_params()
  params.panelId = opts.uri or panel.uri
  local callback = opts.callback or function () end
  return client.rpc.request("getPanelCompletions", params, callback)
end

function panel.create (client, max_results)
  panel.client = client or util.get_copilot_client()
  if not panel.client then print("Error, copilot not running") end
  panel.max_results = max_results or 10
  panel.buf = type(panel.uri) == "number" or vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(panel.buf, "pb" .. tostring(panel.buf))
  panel.uri = vim.uri_from_bufnr(panel.buf)
  return panel
end

return panel
