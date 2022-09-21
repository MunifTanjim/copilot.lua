local util = require("copilot.util")

local panel = {
  callback = {
    PanelSolution = {},
    PanelSolutionsDone = {},
  },
}

panel._handlers = {
  ---@param result { panelId: string, completionText: string, displayText: string, range: { ['end']: { character: integer, line: integer }, start: { character: integer, line: integer } }, score: number, solutionId: string }
  PanelSolution = function(_, result)
    if panel.callback.PanelSolution[result.panelId] then
      panel.callback.PanelSolution[result.panelId](result)
    end
  end,

  ---@param result { panelId: string, status: 'OK'|'Error', message?: string }
  PanelSolutionsDone = function(_, result)
    if panel.callback.PanelSolutionsDone[result.panelId] then
      panel.callback.PanelSolutionsDone[result.panelId](result)
    end
  end,
}

function panel.get_next_id() end

function panel.register(panelId, cb)
  assert(type(panelId) == "string", "missing panelId")
  panel.callback.PanelSolution[panelId] = cb.on_solution
  panel.callback.PanelSolutionsDone[panelId] = cb.on_solutions_done
end

function panel.unregister(panelId)
  assert(type(panelId) == "string", "missing panelId")
  panel.callback.PanelSolution[panelId] = nil
  panel.callback.PanelSolutionsDone[panelId] = nil
end

function panel.get_completions(params, callback)
  local client = util.get_copilot_client()
  if client then
    return client.rpc.request("getPanelCompletions", params, callback)
  end
  return false
end

return panel
