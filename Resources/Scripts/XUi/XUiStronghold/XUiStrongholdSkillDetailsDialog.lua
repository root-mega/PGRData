local CsXTextManagerGetText = CsXTextManagerGetText

local XUiStrongholdSkillDetailsDialog = XLuaUiManager.Register(XLuaUi, "UiStrongholdSkillDetailsDialog")

function XUiStrongholdSkillDetailsDialog:OnAwake()
    self:AutoAddListener()
end

function XUiStrongholdSkillDetailsDialog:OnStart(buffId, skipCb, closeCb)
    self.BuffId = buffId
    self.SkipCb = skipCb
    self.CloseCb = closeCb
end

function XUiStrongholdSkillDetailsDialog:OnEnable()
    self:UpdateView()
end

function XUiStrongholdSkillDetailsDialog:OnDestroy()
    if self.CloseCb then
        self.CloseCb()
    end
end

function XUiStrongholdSkillDetailsDialog:UpdateView()
    local buffId = self.BuffId

    local icon = XStrongholdConfigs.GetBuffIcon(buffId)
    self.RImgIcon:SetRawImage(icon)

    local name = XStrongholdConfigs.GetBuffName(buffId)
    self.TxtName.text = name

    local desc = XStrongholdConfigs.GetBuffDesc(buffId)
    self.TxtDesc.text = desc

    local hasCondition = XStrongholdConfigs.CheckBuffHasCondition(buffId)
    if hasCondition then
        local _, desc = XDataCenter.StrongholdManager.CheckBuffActive(buffId)
        self.TxtRequirement.text = CsXTextManagerGetText("StrongholdBuffConditionDes", desc)

        local condition = XStrongholdConfigs.GetBuffConditionId(buffId)
        local groupId = XConditionManager.GetConditionParams(condition)
        local order = XStrongholdConfigs.GetGroupOrder(groupId)
        self.TxtSkip.text = CsXTextManagerGetText("StrongholdBtnSkipDesc", order)
        self.BtnSkip.gameObject:SetActiveEx(self.SkipCb and true or false)
        
        self.PanelRequirement.gameObject:SetActiveEx(true)
    else
        self.PanelRequirement.gameObject:SetActiveEx(false)
    end
end

function XUiStrongholdSkillDetailsDialog:AutoAddListener()
    self.BtnTanchuangClose.CallBack = function() self:Close() end
    self.BtnSkip.CallBack = function() self:OnClickBtnSkip() end
end

function XUiStrongholdSkillDetailsDialog:OnClickBtnSkip()
    local buffId = self.BuffId
    local hasCondition = XStrongholdConfigs.CheckBuffHasCondition(buffId)
    if not hasCondition then
        return
    end

    if self.SkipCb then
        local condition = XStrongholdConfigs.GetBuffConditionId(buffId)
        local groupId = XConditionManager.GetConditionParams(condition)
        self:Close()
        self.SkipCb(groupId)
    end
end