local XUiGridReviewItem = XClass(nil, "XUiGridReviewItem")

function XUiGridReviewItem:Ctor(ui, data,cb)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.ReviewCallBack = cb
    self.CueId = data.CueId or 0
    XTool.InitUiObject(self)
    self.BtnReview.CallBack = function() 
        if self.ReviewCallBack then
           self.ReviewCallBack(self.CueId)
        end        
     end
    self.BtnReview.gameObject:SetActiveEx(self.CueId ~= 0)
    if not self.contentSizeFitter then
        self.contentSizeFitter = self.TxtWords:GetComponent("TextContentSizeFitter")
    end
    self:Refresh(data)
end

function XUiGridReviewItem:Refresh(data)
    self.TxtName.text = data.RoleName
    self.TxtWords.text = data.Content
    self:AutoSetTextWidth()
end

function XUiGridReviewItem:AutoSetTextWidth()
    --延迟一帧以获取Text准确宽度值
    XScheduleManager.ScheduleOnce(function()
        if self.GameObject == nil or self.GameObject:Exist() == false then
            return
        end
        --MASK的宽度应大于TxtName加TxtWords宽度值,否则会爆框
        local maskWidth = self.Transform.parent.parent:GetComponent("RectTransform").rect.width - 150
        if self.TxtName.rectTransform.rect.width + self.TxtWords.rectTransform.rect.width > maskWidth then
        local width = maskWidth - self.TxtName.rectTransform.rect.width
        self.contentSizeFitter:SetWrapWidth(width)
        CS.UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.TxtWords.rectTransform);
        end
    end, 100)
end

function XUiGridReviewItem:SetTextColor(color)
    self.TxtWords.color = color
    self.TxtName.color = color
end

function XUiGridReviewItem:GetTextColor()
    return self.TxtWords.color
end

return XUiGridReviewItem