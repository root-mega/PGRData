

local XUiRegressionTips = XLuaUiManager.Register(XLuaUi, "UiRegressionTips")

function XUiRegressionTips:OnAwake()
    self.ViewModel = XDataCenter.Regression3rdManager.GetViewModel()
    self:InitCb()
    self:InitUi()
end

function XUiRegressionTips:OnStart(rewardId, previewRewardId, title, content, subContent, confirmCb,payKeySuffix)
    self.RewardId = rewardId
    self.PreviewRewardId = previewRewardId
    self.Title = title
    self.Content = content
    self.SubContent = subContent
    self.ConfirmCb = confirmCb

    self:InitView()
    if payKeySuffix then
        self:ShowSpecialRegulationForJP()
    end
end

function XUiRegressionTips:ShowSpecialRegulationForJP() --海外修改
    local isShow = CS.XGame.ClientConfig:GetInt("ShowRegulationEnable")
    if isShow and isShow == 1 then
        local url = CS.XGame.ClientConfig:GetString("RegulationPrefabUrl")
        if url then
            local obj = self.TxtTitle.transform:LoadPrefab(url)
            local data = {type = 3,consumeId = 1}
            data.content = CS.XTextManager.GetText("JPBusinessLawsBuyLimitedText03",1)
            self.ShowSpecialRegBtn = obj.transform:GetComponent("XHtmlText")
            self.ShowSpecialRegBtn.text = CS.XTextManager.GetText("JPBusinessLawsDetailsEnter")
            self.ShowSpecialRegBtn.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
            self.ShowSpecialRegBtn.transform.localPosition = CS.UnityEngine.Vector3(150, -677, 0)
            self.ShowSpecialRegBtn.fontSize = 32
            self.ShowSpecialRegBtn.HrefListener = function(link)
                XLuaUiManager.Open("UiSpecialRegulationShow",data)
            end
        end
    end
end

function XUiRegressionTips:OnEnable()
    self.Super.OnEnable(self)
end

function XUiRegressionTips:InitView()
    if self.Title then
        self.TxtTitle.text = self.Title
    end

    if self.Content then
        self.TxtContent.text = self.Content
    end

    if self.SubContent then
        self.TxtSubContent.text = self.SubContent
    end

    self:HideAllReward()
    self:RefreshReward(self.RewardId, self.PanelDrawItemSP)
    self:RefreshReward(self.PreviewRewardId, self.PanelDrawItemNA)

    local endTime = self.ViewModel:GetProperty("_ActivityEndTime")
    self:SetAutoCloseInfo(endTime, function(isClose)
        if isClose or not XDataCenter.Regression3rdManager.IsOpen() then
            XDataCenter.Regression3rdManager.OnActivityEnd()
        end
    end)
end

function XUiRegressionTips:InitUi()
    self.GridReward = {}
end

function XUiRegressionTips:RefreshReward(rewardId, gridParent)
    if not XTool.IsNumberValid(rewardId) then
        return
    end
    local rewardList = XRewardManager.GetRewardList(rewardId)
    for _, reward in ipairs(rewardList or {}) do
        local grid = self.GridReward[reward.TemplateId]
        if not grid then
            local ui = XUiHelper.Instantiate(self.GridDrawActivity, gridParent)
            grid = XUiGridCommon.New(self, ui)
        end
        grid:Refresh(reward)
    end
end

function XUiRegressionTips:HideAllReward()
    for _, grid in pairs(self.GridReward) do
        if grid and not XTool.UObjIsNil(grid.GameObject) then
            grid.GameObject:SetActiveEx(false)
        end
    end
    self.GridDrawActivity.gameObject:SetActiveEx(false)
end

function XUiRegressionTips:InitCb()
    self.BtnTongBlack.CallBack = function()
        self:OnBtnConfirmClick()
    end

    self.BtnPreviewClose.CallBack = function()
        self:Close()
    end

    self.BtnPreviewConfirm.CallBack = function()
        self:Close()
    end
end

function XUiRegressionTips:OnBtnConfirmClick()
    if self.ConfirmCb then self.ConfirmCb() end
    self:Close()
end