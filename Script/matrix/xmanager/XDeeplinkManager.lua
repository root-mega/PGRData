XDeeplinkManager = XDeeplinkManager or {}

local this = XDeeplinkManager

function this.InvokeDeeplink()
    if CS.XRemoteConfig.AFDeepLinkEnabled == false then
        return false
    end

    local isMainUi = XLuaUiManager.IsUiShow("UiMain")
    if not isMainUi then
        return false
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return false
    end

    local aGent
    if CS.XHgSdkAgent.LoginType ~= CS.XHgSdkAgent.LoginType_KURO or XDataCenter.UiPcManager.IsPc() then
        aGent = CS.XAppsflyerEvent
    else
        aGent = CS.XHgSdkAgent
    end
    local deepLinkValue = aGent.GetDeepLinkValue()
    CS.XAppsflyerEvent.ResetDeepLinkValue()
    XHgSdkManager.ClearDeepLinkValue() -- 不论如何，拿到就清空
    CS.XLog.Debug("afdeeplink")
    CS.XLog.Debug(deepLinkValue)
    local NewGuidePass = CS.XGame.ClientConfig:GetInt("DeepLinkCondition")
    if CS.XRemoteConfig.AFDeepLinkEnabled and not string.IsNilOrEmpty(deepLinkValue) and XConditionManager.CheckCondition(NewGuidePass) then
        local endValuePos = deepLinkValue:find("?af_qr=true", 1) or 0
        if endValuePos-1 > 1 then
            deepLinkValue = deepLinkValue:sub(1,endValuePos-1)
        end
        local afdeepInfo = string.Split(deepLinkValue, "_")
        XLog.Debug("afdeepInfo:", afdeepInfo);
        if afdeepInfo[1] == "i" then
            local skipId = tonumber(afdeepInfo[2])
            if XFunctionManager.IsAFDeepLinkCanSkipByShowTips(skipId) then
                XFunctionManager.SkipInterface(skipId)
                return true
            end
        end
    end
    return false
end

function this.TryInvokeDeeplink()
    if CS.XRemoteConfig.DeeplinkEnabled == false then
        return
    end

    if not XLoginManager.IsLogin() then
        return
    end

    if XDataCenter.GuideManager.CheckIsInGuide() then
        return
    end

    if not CS.XFight.IsOutFight then
        return
    end

    if XHomeDormManager.InDormScene() then
        return
    end

    if XDataCenter.FunctionEventManager.IsPlaying() then
        return
    end

    local deepMgr = CS.XDeeplinkManager;
    if deepMgr.HasDeeplink == false then
        return
    end
    XFunctionManager.SkipInterface(deepMgr.DeeplinkValue)
    deepMgr.Reset()
end