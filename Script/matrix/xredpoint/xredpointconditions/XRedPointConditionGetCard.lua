----------------------------------------------------------------
-- 月卡奖励领取
local XRedPointConditionGetCard = {}
local Events = nil
function XRedPointConditionGetCard.GetSubEvents()
    Events = Events or {
        XRedPointEventElement.New(XEventId.EVENT_YK_UPDATE),
    }
    return Events
end

function XRedPointConditionGetCard.Check()
    return not XDataCenter.PayManager.IsGotCard()
end

return XRedPointConditionGetCard