local XUiTheatreRecruitMemberGrid = require("XUi/XUiTheatre/Recruit/XUiTheatreRecruitMemberGrid")

--招募界面：底下的成员列表控件
local XUiTheatreRecruitMemberPanel = XClass(nil, "XUiTheatreRecruitMemberPanel")

function XUiTheatreRecruitMemberPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    self.GridSample = rootUi.GridCharacter
    self.GridSample.gameObject:SetActiveEx(false)
    self.AlreadyPlayEffects = {}
    self:InitDynamicTable()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE_RECRUIT_COMPLETE, self.UpdateData, self)
end

function XUiTheatreRecruitMemberPanel:RemoveEventListeners()
    XEventManager.RemoveEventListener(XEventId.EVENT_LOGIN_DATA_LOAD_COMPLETE, self.UpdateData, self)
end

function XUiTheatreRecruitMemberPanel:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.GameObject)
    self.DynamicTable:SetProxy(XUiTheatreRecruitMemberGrid)
    self.DynamicTable:SetDelegate(self)
end

--动态列表事件
function XUiTheatreRecruitMemberPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(grid.DynamicGrid.gameObject, self.RootUi)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local adventureRole = self.TotalRoles and self.TotalRoles[index]
        
        if adventureRole then
            grid:RefreshDatas(adventureRole, index)
        end

        local theatreRoleId = not XTool.IsTableEmpty(adventureRole) and adventureRole:GetId()
        if theatreRoleId and not self.AlreadyPlayEffects[theatreRoleId] then
            self.AlreadyPlayEffects[theatreRoleId] = true
            grid:PlayEffect()
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        local adventureRole = self.TotalRoles[index]
        if XTool.IsTableEmpty(adventureRole) then
            return
        end

        grid:SetPanelSelectedActive(true)
        self.CurSelectGrid = grid
        XLuaUiManager.Open("UiTheatreRoleDetails", adventureRole, true, function()
            self.CurSelectGrid:SetPanelSelectedActive(false)
        end)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_RECYCLE then
        grid:InitEffect()
    end
end

function XUiTheatreRecruitMemberPanel:UpdateData()
    if XTool.UObjIsNil(self.GameObject) then
        return
    end

    local adventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    self.TotalRoles = adventureManager:GetRecruitTotalRoles()
    self.DynamicTable:SetDataSource(self.TotalRoles)
    self.DynamicTable:ReloadDataASync(1)
end

return XUiTheatreRecruitMemberPanel