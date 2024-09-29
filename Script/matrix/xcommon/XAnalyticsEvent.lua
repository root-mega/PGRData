--==============================--
-- 通用数据收集事件
--==============================--
XAnalyticsEvent = XAnalyticsEvent or {}

local OnRoleCreate = function()
    if XUserManager.IsUseSdk() then
        -- XHeroSdkManager.CreateNewRole()
        XHgSdkManager.CreateNewRole();
    end
    -- en2.1 pcsdk 升级
    XHgSdkManager.CreateNewRole();
end

local OnLogin = function()
    if XUserManager.IsUseSdk() then
        -- XHeroSdkManager.EnterGame()
        XHgSdkManager.EnterGame()
    end

    CS.BuglyAgent.SetUserId(tostring(XPlayer.Id))
    -- en2.1 pcsdk 升级
    XHgSdkManager.EnterGame()
end

local OnLevelUp = function()
    if XUserManager.IsUseSdk() then
        -- XHeroSdkManager.RoleLevelUp()
        XHgSdkManager.RoleLevelUp()
    end

    -- en2.1 pcsdk 升级
    XHgSdkManager.RoleLevelUp()
end

local OnLogout = function()

end

function XAnalyticsEvent.Init()
    XEventManager.AddEventListener(XEventId.EVENT_NEW_PLAYER, OnRoleCreate)
    XEventManager.AddEventListener(XEventId.EVENT_LOGIN_SUCCESS, OnLogin)
    XEventManager.AddEventListener(XEventId.EVENT_PLAYER_LEVEL_CHANGE, OnLevelUp)
    XEventManager.AddEventListener(XEventId.EVENT_USER_LOGOUT, OnLogout)
end
