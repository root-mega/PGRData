local XUiSelectCharacterBase = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterBase")
---@class XUiSelectCharacterPlayerSupport:XUiSelectCharacterBase
local XUiSelectCharacterPlayerSupport = XLuaUiManager.Register(XUiSelectCharacterBase, "UiSelectCharacterPlayerSupport")

function XUiSelectCharacterPlayerSupport:OnStartCb()
    self.BtnJoin.gameObject:SetActiveEx(true)
    self.BtnQuit.gameObject:SetActiveEx(false)
end

function XUiSelectCharacterPlayerSupport:OnBtnJoinClick()
    XDataCenter.AssistManager.ChangeAssistCharacterId(self.CurCharacter.Id, function(code)
        if (code == XCode.Success) then
            self:Close()
        end
    end)
end

function XUiSelectCharacterPlayerSupport:GetGridProxy()
    local XUiSelectCharacterPlayerSupportGrid = require("XUi/XUiSelectCharacterBase/XUiSelectCharacterPlayerSupportGrid")
    return XUiSelectCharacterPlayerSupportGrid
end

function XUiSelectCharacterPlayerSupport:GetOverrideSortTable()
    local sortOverride = {
        CheckFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                if idA ~= idB then
                    return true
                end
                return false
            end
        },
        SortFunList = {
            [CharacterSortFunType.Custom1] = function(idA, idB)
                local assistId = XDataCenter.AssistManager.GetAssistCharacterId()
                if assistId == idA then
                    return true
                end
                if assistId == idB then
                    return false
                end
                return false
            end
        }
    }
    return sortOverride
end

return XUiSelectCharacterPlayerSupport
