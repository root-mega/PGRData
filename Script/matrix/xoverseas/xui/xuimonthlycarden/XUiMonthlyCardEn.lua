local TextManager = CS.XTextManager
local XUiPurchaseLBTipsListItem = require("XUi/XUiPurchase/XUiPurchaseLBTipsListItem")
local XUiMonthlyCardEn = XLuaUiManager.Register(XLuaUi, "UiMonthlyCardEn")
local LBGetTypeConfig = XPurchaseConfigs.LBGetTypeConfig
local Next = _G.next
local ColorImgSelected = XUiHelper.Hexcolor2Color("0F70BCC8")
local ColorImgNormal = XUiHelper.Hexcolor2Color("1A3650C8")
local ColorTextSelected = XUiHelper.Hexcolor2Color("0F70BCFF")
local ColorTextNormal = CS.UnityEngine.Color.black

local MonthlyCardType = {
    A = "A",
    C = "C",
}

function XUiMonthlyCardEn:OnAwake()
end

function XUiMonthlyCardEn:OnStart(cardAData, cardCData)
    self.CardAData = cardAData
    self.CardCData = cardCData

    self.DirGainData = {}
    self.DirGainData[MonthlyCardType.A] = {}
    self.DirGainData[MonthlyCardType.C] = {}

    self.DayGainData = {}
    self.DayGainData[MonthlyCardType.A] = {}
    self.DayGainData[MonthlyCardType.C] = {}

    self.CardATitlePool = {}
    self.CardAItemPool = {}
    self.CardCTitlePool = {}
    self.CardCItemPool = {}

    self.CardAEntity = {}
    self.CardCEntity = {}
    XUiHelper.InitUiClass(self.CardAEntity, self.MonthlyCardA)
    XUiHelper.InitUiClass(self.CardCEntity, self.MonthlyCardC)
    
    self.CardABought = self.CardAData:GetCurrentBuyTime() > 0
    self.CardCBought = self.CardCData:GetCurrentBuyTime() > 0

    self.SelectingCardData = nil
end

function XUiMonthlyCardEn:OnEnable()
    self:BindUiEvents()
    self:ShowCurrentCard()
    self:ChangeSelected(self.CardABought, self.CardCBought)
end

function XUiMonthlyCardEn:BindUiEvents()
    self.BtnHelp.CallBack = function() XUiManager.UiFubenDialogTip("", TextManager.GetText("PurchaseYKDes") or "") end
    self.BtnBgClick.CallBack = function() self:Close() end
    self.MonthlyCardA.CallBack = function() self:ChangeSelected(true, false) end
    self.MonthlyCardC.CallBack = function() self:ChangeSelected(false, true) end
    self.BtnBuy.CallBack = function() self:BuyPurchaseRequest() end
end

function XUiMonthlyCardEn:ShowCurrentCard()
    self.TitleIndex = 1
    self.ItemIndex = 1

    self:SetMonthlyCardContent(self.CardAEntity, self.DirGainData[MonthlyCardType.A], self.DayGainData[MonthlyCardType.A], self.CardATitlePool, self.CardAItemPool, self.CardAData)
    self:SetMonthlyCardContent(self.CardCEntity, self.DirGainData[MonthlyCardType.C], self.DayGainData[MonthlyCardType.C], self.CardCTitlePool, self.CardCItemPool, self.CardCData)
end

function XUiMonthlyCardEn:SetMonthlyCardContent(entity, dirGainData, dayGainData, titlePool, itemPool, item)

    -- 图片Icon
    entity.TxtName.text = item.Data.Name
    local path = XPurchaseConfigs.GetIconPathByIconName(item.Data.Icon)
    if path and path.AssetPath then
        entity.RawImageIcon:SetRawImage(path.AssetPath)
    end

    -- 货币&价格
    entity.CostIcon:SetRawImage(XEntityHelper.GetItemIcon(item:GetConsumeId()))
    entity.Price.text = item:GetConsumeCount()

    -- 直接获得的道具
    local rewards0 = item.Data.RewardGoodsList or {}
    for _, v in pairs(rewards0) do
        v.LBGetType = LBGetTypeConfig.Direct
        table.insert(dirGainData, v)
    end

    -- 每日获得的道具
    local rewards1 = item.Data.DailyRewardGoodsList or {}
    for _, v in pairs(rewards1) do
        v.LBGetType = LBGetTypeConfig.Day
        table.insert(dayGainData, v)
    end

    if Next(dirGainData) ~= nil then
        local obj = self:GetTitleGo(entity, titlePool, self.TitleIndex)
        self.TitleIndex = self.TitleIndex + 1
        obj.transform:Find("TxtTitle"):GetComponent("Text").text = TextManager.GetText("PurchaseDirGet")
        for _, v in pairs(dirGainData) do
            local item = self:GetItemObj(entity, itemPool, self.ItemIndex)
            item:OnRefresh(v)
            self.ItemIndex = self.ItemIndex + 1
        end
    end

    if Next(dayGainData) ~= nil then
        local obj = self:GetTitleGo(entity, titlePool, self.TitleIndex)
        self.TitleIndex = self.TitleIndex + 1
        obj.transform:Find("TxtTitle"):GetComponent("Text").text = item.Data.Desc or " "
        for _, v in pairs(dayGainData) do
            local item = self:GetItemObj(entity, itemPool, self.ItemIndex)
            item:OnRefresh(v)
            self.ItemIndex = self.ItemIndex + 1
        end
    end
end

function XUiMonthlyCardEn:GetTitleGo(entity, titlePool, index)
    if titlePool[index] then
        titlePool[index].gameObject:SetActiveEx(true)
        titlePool[index]:SetParent(entity.PanelReward)
        return titlePool[index]
    end

    local obj = CS.UnityEngine.Object.Instantiate(entity.ImgTitle, entity.PanelReward)
    obj.gameObject:SetActiveEx(true)
    obj:SetParent(entity.PanelReward)
    table.insert(titlePool, obj)
    return obj
end

function XUiMonthlyCardEn:GetItemObj(entity, itemPool, index)
    if itemPool[index] then
        itemPool[index].GameObject:SetActiveEx(true)
        itemPool[index].Transform:SetParent(entity.PanelReward)
        return itemPool[index]
    end

    local itemObj = CS.UnityEngine.Object.Instantiate(entity.PanelPropItem, entity.PanelReward)
    itemObj.gameObject:SetActiveEx(true)
    itemObj:SetParent(entity.PanelReward)
    local item = XUiPurchaseLBTipsListItem.New(itemObj)
    item:Init(self)
    table.insert(itemPool, item)
    return item
end

function XUiMonthlyCardEn:ChangeSelected(cardASelected, cardCSelected)
    if (self.CardCBought and cardASelected) or (self.CardABought and cardCSelected) then
        XUiManager.TipMsg(TextManager.GetCodeText(20053101))
        return
    end
    self:ShowSelected(self.CardAEntity, self.CardATitlePool, cardASelected)
    self:ShowSelected(self.CardCEntity, self.CardCTitlePool, cardCSelected)

    if not cardASelected and not cardCSelected then
        self.BtnBuy:SetDisable(true)
        return
    end
    self.BtnBuy:SetButtonState(CS.UiButtonState.Normal)
    self.SelectingCardData = cardASelected and self.CardAData.Data or self.CardCData.Data
end

function XUiMonthlyCardEn:ShowSelected(entity, titlePool, selected)
    entity.BgSelect.gameObject:SetActiveEx(selected)
    entity.TxtName.color = selected and ColorTextSelected or ColorTextNormal
    entity.Price.color = selected and ColorTextSelected or ColorTextNormal
    for _, title in pairs(titlePool) do
        local img = title.transform:Find("Image"):GetComponent("Image")
        img.color = selected and ColorImgSelected or ColorImgNormal
    end
end

function XUiMonthlyCardEn:BuyPurchaseRequest()
    if self.SelectingCardData and self.SelectingCardData.Id then
        if self.SelectingCardData.ConsumeCount > 0 and self.SelectingCardData.ConsumeCount > XDataCenter.ItemManager.GetCount(XDataCenter.ItemManager.ItemId.HongKa) then
            XUiHelper.OpenPurchaseBuyHongKaCountTips()
            return
        end
        XDataCenter.PurchaseManager.PurchaseRequest(self.SelectingCardData.Id)
    end
end

function XUiMonthlyCardEn:OnDisable()

end

function XUiMonthlyCardEn:OnDestroy()

end