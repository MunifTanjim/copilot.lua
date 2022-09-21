local panel = {
  callback = {
    PanelSolution = {},
    PanelSolutionsDone = {},
  },
}

local mod = {}
mod.panel = panel

mod.handlers = {
  ---@param result { panelId: string, completionText: string, displayText: string, range: { ['end']: { character: integer, line: integer }, start: { character: integer, line: integer } }, score: number, solutionId: string }
  PanelSolution = function (_, result)
    if panel.callback.PanelSolution[result.panelId] then
      panel.callback.PanelSolution[result.panelId](result)
    end
  end,

  ---@param result { panelId: string, status: 'OK'|'Error', message?: string }
  PanelSolutionsDone = function (_, result)
    if panel.callback.PanelSolutionsDone[result.panelId] then
      panel.callback.PanelSolutionsDone[result.panelId](result)
    end
  end,

  ---@param result { status: string, message: string }
  ---@param ctx { client_id: integer, method: string }
  statusNotification = function (_, result, ctx)
  end
}

function panel.on_solution(panelId, fn_name, fn)
  panel.callback[method][fn_name] = fn
end

mod.remove_handler_callback = function (method, fn_name)
  panel.callback[method][fn_name] = nil
end

mod.remove_all_name = function (fn_name)
  for handler, _ in pairs(panel.callback) do
    mod.remove_handler_callback(handler, fn_name)
  end
end

return mod
