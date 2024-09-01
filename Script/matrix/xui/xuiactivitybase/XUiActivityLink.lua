local XUiGridActivityLink = require("XUi/XUiActivityBase/XUiGridActivityLink")
local XUiActivityBaseLink = XLuaUiManager.Register(XLuaUi, "UiActivityBaseLink")

function XUiActivityBaseLink:OnStart()
    self:InitDynamicTable()
    self:UpdateList()
    --local bg = self.BtnFirst.transform:Find("RImgBg"):GetComponent("RawImage")
    --bg:SetRawImage(CS.XGame.ClientConfig:GetString("ActivityLinkButtonBg"))
    self.BtnFirst:SetName(CS.XGame.ClientConfig:GetString("ActivityLinkButtonName"))
    self.BtnFirst.CallBack = function() 
        self:OnBtnClick()
    end
end

function XUiActivityBaseLink:InitDynamicTable()
    self.DynamicTable = XDynamicTableNormal.New(self.SViewLinkList)
    self.DynamicTable:SetProxy(XUiGridActivityLink)
    self.DynamicTable:SetDelegate(self)
end

function XUiActivityBaseLink:UpdateList()
    self.LinkDataList = {}
    local LinkDataList = XActivityConfigs.GetActivityLinkTemplate()
    for i = 1, 3 do
        if LinkDataList[i] then
            table.insert(self.LinkDataList,LinkDataList[i])
        end
    end
    self.DynamicTable:SetDataSource(self.LinkDataList)
    self.DynamicTable:ReloadDataASync()
end

function XUiActivityBaseLink:OnBtnClick()
    self.BtnFirst:SetButtonState(CS.UiButtonState.Select)
end

function XUiActivityBaseLink:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        grid:UpdateGrid(self.LinkDataList[index])
    end
end
