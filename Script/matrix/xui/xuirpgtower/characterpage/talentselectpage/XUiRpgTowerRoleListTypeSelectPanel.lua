---@class XUiRpgTowerRoleListTypeSelectPanel
local XUiRpgTowerRoleListTypeSelectPanel = XClass(nil, "XUiRpgTowerRoleListTypeSelectPanel")

function XUiRpgTowerRoleListTypeSelectPanel:Ctor(uiGameObject, page, rootUi)
    XTool.InitUiObjectByUi(self, uiGameObject)
    self.Page = page
    self.RootUi = rootUi
    self.BtnExchange.CallBack = function() self:OnClickChangeMember() end
    --单人作战天赋按钮
    self.BtnSingle.CallBack = function() self:OnClickSingle() end
    --轮换作战天赋按钮
    self.BtnRotation.CallBack = function() self:OnClickRotation() end
end
--================
--刷新数据
--================
function XUiRpgTowerRoleListTypeSelectPanel:RefreshData(rChara)
    self.RCharacter = rChara
    self.BtnSingle:ShowTag(rChara:GetCharaTalentType() == XDataCenter.RpgTowerManager.TALENT_TYPE.SINGLE)
    self.BtnRotation:ShowTag(rChara:GetCharaTalentType() == XDataCenter.RpgTowerManager.TALENT_TYPE.TEAM)
end
--================
--点击更换队员按钮
--================
function XUiRpgTowerRoleListTypeSelectPanel:OnClickChangeMember()
    self.RootUi:OpenChildPage(XDataCenter.RpgTowerManager.PARENT_PAGE.CHANGEMEMBER)
end

function XUiRpgTowerRoleListTypeSelectPanel:ShowPanel()
    self.GameObject:SetActiveEx(true)
end

function XUiRpgTowerRoleListTypeSelectPanel:HidePanel()
    self.GameObject:SetActiveEx(false)
end
--================
--点击单人作战
--================
function XUiRpgTowerRoleListTypeSelectPanel:OnClickSingle()
    if not self.RCharacter then return end
    self.RootUi:OpenChildPage(XDataCenter.RpgTowerManager.PARENT_PAGE.ADAPT, XDataCenter.RpgTowerManager.TALENT_TYPE.SINGLE)
end
--================
--点击轮换作战
--================
function XUiRpgTowerRoleListTypeSelectPanel:OnClickRotation()
    self.RootUi:OpenChildPage(XDataCenter.RpgTowerManager.PARENT_PAGE.ADAPT, XDataCenter.RpgTowerManager.TALENT_TYPE.TEAM)
end
return XUiRpgTowerRoleListTypeSelectPanel