local XUiPanelFavorabilityFile = XClass(XUiNode, "XUiPanelFavorabilityFile")
local XUiTextScrolling = require("XUi/XUiTaikoMaster/XUiTaikoMasterFlowText")

function XUiPanelFavorabilityFile:OnStart(uiRoot)
    self.UiRoot = uiRoot
    self.GridPool = {}
    self.GridItem.gameObject:SetActiveEx(false)
    self.BtnStory.CallBack=function() self:OpenPlotView()  end
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    self.RedPointPlotId = self:AddRedPointEvent(self.Red, nil, self, { XRedPointConditions.Types.CONDITION_FAVORABILITY_PLOT }, { CharacterId = characterId })
    ---@type XUiTaikoMasterFlowText
    self.RoleNameTextScrolling = XUiTextScrolling.New(self.TxtRoleName ,self.TxtRoleNameMask)
    self.RoleNameTextScrolling:Stop()
end

function XUiPanelFavorabilityFile:OnEnable()
    self:RefreshDatas()
end

function XUiPanelFavorabilityFile:OnRefresh()
    self:RefreshDatas()
end

function XUiPanelFavorabilityFile:RefreshDatas()
    local characterId = self.UiRoot:GetCurrFavorabilityCharacter()
    if not characterId then
        return
    end
    local fileData = XFavorabilityConfigs.GetCharacterBaseDataById(characterId)

    if fileData == nil then
        return
    end

    self.TxtRoleName.text = XDataCenter.FavorabilityManager.GetNameWithTitleById(characterId)
    self.TxtRoleEn.text=XCharacterConfigs.GetCharacterEnName(characterId)
    self.TxtTradeName.text = XCharacterConfigs.GetCharacterTradeName(characterId)
    --型号
    if self.TxtNameNum then
        self.TxtNameNum.text=XCharacterConfigs.GetCharacterCodeStr(characterId)
    end
    --剧情入口
    if XTool.IsTableEmpty(XFavorabilityConfigs.GetCharacterStoryById(characterId)) then
        self.BtnStory:SetNameByGroup(1,'')
        self.BtnStory:SetButtonState(CS.UiButtonState.Disable)
        self.NoneStory=true
    else
        local unlockNum,storyNum=XDataCenter.FavorabilityManager.StoryUnlockNum(characterId)
        self.BtnStory:SetNameByGroup(1,unlockNum..'/'..storyNum)
        self.BtnStory:SetButtonState(CS.UiButtonState.Normal)
        self.NoneStory=false
    end

    self.RoleNameTextScrolling:Stop()
    self.RoleNameTextScrolling:Play()
    
    self:GenerateDataGrid(fileData)
    XRedPointManager.Check(self.RedPointPlotId, { CharacterId = characterId })

end

function XUiPanelFavorabilityFile:GenerateDataGrid(fileData)
    -- 回收格子
    for i = self.DataContent.transform.childCount - 1, 0, -1 do
        local grid = self.DataContent:GetChild(i)
        local gridGO = grid.gameObject

        if gridGO.activeSelf then
            gridGO:SetActiveEx(false)
            table.insert(self.GridPool, gridGO)
        end
    end

    -- 拿出格子
    for i, dataTitle in ipairs(fileData.BaseDataTitle) do
        local grid

        if next(self.GridPool) then
            grid = table.remove(self.GridPool)
        else
            grid = CS.UnityEngine.Object.Instantiate(self.GridItem)
        end

        -- 数据赋值
        grid.transform:SetParent(self.DataContent, false)
        local txtTitle = XUiHelper.TryGetComponent(grid.transform, "TxtBaseDataTitle", "Text")
        local txtData = XUiHelper.TryGetComponent(grid.transform, "TxtBaseData", "Text")
        txtTitle.text = dataTitle
        txtData.text = fileData.BaseData[i] or ""

        grid.gameObject:SetActiveEx(true)
    end
end

function XUiPanelFavorabilityFile:SetViewActive(isActive)
    if isActive then
        self:Open()
    else
        self:Close()
    end
end

function XUiPanelFavorabilityFile:OnSelected(isSelected)
    if isSelected then
        self:Open()
    else
        self:Close()
    end
end

-- [打开剧情界面]
function XUiPanelFavorabilityFile:OpenPlotView()
    if not self.NoneStory then
        local currentCharacterId = self.UiRoot:GetCurrFavorabilityCharacter()
        XLuaUiManager.Open('UiFavorabilityStory',currentCharacterId)
    else
        XUiManager.TipText('FavorabilityStoryNoOne')
    end

end

return XUiPanelFavorabilityFile