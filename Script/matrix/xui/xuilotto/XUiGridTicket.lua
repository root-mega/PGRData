local XUiGridTicket = XClass(nil, "XUiGridTicket")

local CostColor = {
    [true] = "444C52",
    [false] = "FF3F3F",
}

function XUiGridTicket:Ctor(ui, data, buyCb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.TicketData = data
    self.BuyCb = buyCb
    XTool.InitUiObject(self)
    self:SetButtonCallBack()
    self:ShowPanel()
    XDataCenter.ItemManager.AddCountUpdateListener(self.TicketData.ItemId, function()
        if self.CurNum then
            self.CurNum.text = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId).Count
        end
    end, self.GameObject)
end

function XUiGridTicket:SetButtonCallBack()
    if self.BtnBuy then
        self.BtnBuy.CallBack = function()
            self:OnBtnBuyClick()
        end
    end
    if self.ImgBtn then
        self.ImgBtn.CallBack = function()
            self:OnImgBtnClick()
        end
    end
end

function XUiGridTicket:ShowPanel()
    if self.Sale then
        self.Sale.gameObject:SetActiveEx(self.TicketData.Sale)
    end
    
    if self.SaleText then
        self.SaleText.text = self.TicketData.Sale
    end
    
    if self.CostNum then
        self.CostNum.text = self.TicketData.ItemCount
        if self.BuyCb then
            local currentCount = XDataCenter.ItemManager.GetCount(self.TicketData.ItemId)
            local needCount = self.TicketData.ItemCount
            self.CostNum.color = XUiHelper.Hexcolor2Color(CostColor[currentCount >= needCount])
        end
    end
    
    if self.CurNum then
        self.CurNum.text = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId).Count
    end
    
    if self.CardImg then
        local goods = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.TicketData.ItemId)
            local icon = self.TicketData.ItemImg or goods.BigIcon or goods.Icon
        self.CardImg:SetRawImage(icon)
    end

    if self.TicketData.ItemId and self.TicketData.ItemId == 3 then --这里的3是指黑卡
        self:ShowSpecialRegulationForJP() --日服特定商吸引法弹窗链接显示
    end
end

function XUiGridTicket:ShowSpecialRegulationForJP() --海外修改
    local isShow = CS.XGame.ClientConfig:GetInt("ShowRegulationEnable")
    if isShow and isShow == 1 then
        local url = CS.XGame.ClientConfig:GetString("RegulationPrefabUrl")
        if url then
            local obj = self.CardImg.transform:LoadPrefab(url)
            local data = {type = 1,consumeId = 3}
            self.ShowSpecialRegBtn = obj.transform:GetComponent("XHtmlText")
            self.ShowSpecialRegBtn.text = CSXTextManagerGetText("JPBusinessLawsDetailsEnter")
            self.ShowSpecialRegBtn.HrefUnderLineColor = CS.UnityEngine.Color(1, 45 / 255, 45 / 255, 1)
            self.ShowSpecialRegBtn.transform.localPosition = CS.UnityEngine.Vector3(132, -86, 0)
            self.ShowSpecialRegBtn.fontSize = 30
            self.ShowSpecialRegBtn.HrefListener = function(link)
                XLuaUiManager.Open("UiSpecialRegulationShow",data)
            end
        end
    end
end

function XUiGridTicket:OnBtnBuyClick()
    -- 检查物品数量是够足够，不够弹出购买
    local itemId = self.TicketData.ItemId
    local currentCount = XDataCenter.ItemManager.GetCount(itemId)
    local needCount = self.TicketData.ItemCount
    if currentCount < needCount then
        if itemId == XDataCenter.ItemManager.ItemId.FreeGem or itemId == XDataCenter.ItemManager.ItemId.PaidGem then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.HK)
        elseif itemId == XDataCenter.ItemManager.ItemId.HongKa then
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.Pay)
        elseif XItemConfigs.GetBuyAssetTemplateById(itemId) then
            XLuaUiManager.Open("UiBuyAsset", itemId, function()
                if self.CurNum then
                    self.CurNum.text = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId).Count
                end
            end, nil, needCount - currentCount)
        else
            --XUiManager.TipError(XUiHelper.GetText("AssetsBuyConsumeNotEnough", XDataCenter.ItemManager.GetItemName(itemId)))
            XLuaUiManager.Open("UiPurchase", XPurchaseConfigs.TabsConfig.LB, nil, 1)
        end
        return
    end
    if self.BuyCb then
        self.BuyCb() 
    end
end

function XUiGridTicket:OnImgBtnClick()
    local data = XDataCenter.ItemManager.GetItem(self.TicketData.ItemId)
    XLuaUiManager.Open("UiTip", data)
end

return XUiGridTicket