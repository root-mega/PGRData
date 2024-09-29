XUserManager = XUserManager or {}

local Application = CS.UnityEngine.Application
local Platform = Application.platform
local RuntimePlatform = CS.UnityEngine.RuntimePlatform

XUserManager.CHANNEL = {
    HARU = 1,
    HERO = 2,
    Android = 3,
    IOS = 4,
    KURO_SDK = 15,
    KuroPC = 15
}

XUserManager.PLATFORM = {
    Win = 0,
    Android = 1,
    IOS = 2
}

XUserManager.UserId = nil
XUserManager.UserName = nil
XUserManager.Token = nil
XUserManager.ReconnectedToken = nil
XUserManager.Channel = nil
XUserManager.Platform = nil
-- 登录渠道，PC端用
XUserManager.LoginChannel = nil

local UserType = XHgSdkManager.UserType

local InitPlatform = function()
    if Platform == RuntimePlatform.Android then
        XUserManager.Platform = XUserManager.PLATFORM.Android
        if CS.XHgSdkAgent.LoginType ~= CS.XHgSdkAgent.LoginType_KURO then
            XHgSdkManager.SetCallBackUrl(CS.XRemoteConfig.AndroidPayCallbackUrl)
        else
            XHgSdkManager.SetCallBackUrl(CS.XRemoteConfig.KuroPayCallbackUrl)
        end
    elseif Platform == RuntimePlatform.IPhonePlayer then
        XUserManager.Platform = XUserManager.PLATFORM.IOS
        if CS.XHgSdkAgent.LoginType ~= CS.XHgSdkAgent.LoginType_KURO then
            XHgSdkManager.SetCallBackUrl(CS.XRemoteConfig.IosPayCallbackUrl)
        else
            XHgSdkManager.SetCallBackUrl(CS.XRemoteConfig.KuroPayCallbackUrl)
        end
    else
        XUserManager.Platform = XUserManager.PLATFORM.Win
        XHgSdkManager.SetCallBackUrl(CS.XRemoteConfig.PcPayCallbackUrl)
    end
end

function XUserManager.IsUseSdk()
    return XUserManager.Channel == XUserManager.CHANNEL.HERO or XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK
end

function XUserManager.IsKuroSdk()
    return XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK
end

function XUserManager.IsHeroSdk()
    return XUserManager.Channel == XUserManager.CHANNEL.HERO
end

function XUserManager.Init()
    XUserManager.Channel = CS.XHgSdkAgent.LoginType or XUserManager.CHANNEL.HARU
    XUserManager.UserId = XLoginManager.GetUserId()
    XUserManager.UserType = XLoginManager.GetUserType() or UserType.Vistor
    XUserManager.PasswordStatus = tonumber(XLoginManager.GetPasswordStatus() or "0") or 0
    if XUserManager.Channel ~= XUserManager.CHANNEL.Android and  XUserManager.Channel ~= XUserManager.CHANNEL.IOS then
        XUserManager.Token = XLoginManager.GetToken()
        XUserManager.SetPasswordStatus(0)
    end
    InitPlatform()
end

function XUserManager.IsNeedLogin()
    if (XUserManager.Channel == XUserManager.CHANNEL.Android) or (XUserManager.Channel == XUserManager.CHANNEL.IOS) or
        XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK or XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        return XHgSdkManager.IsNeedLogin()
    else
        return XHaruUserManager.IsNeedLogin()
    end
end

function XUserManager.HasLoginError()
    if XUserManager.IsUseSdk() then
        return XHeroSdkManager.HasLoginError()
    else
        return false
    end
end

function XUserManager.ShowLogin()
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS or
        XUserManager.Channel == XUserManager.CHANNEL.KuroPC or XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK then
        XHgSdkManager.Login(XHgSdkManager.UserType.Quickly) -- 默认快速登录逻辑
    else
        XHaruUserManager.Login()
    end
end

function XUserManager.ShowLogout()
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS then
        XHgSdkManager.BackToLogin()
    elseif XUserManager.Channel == XUserManager.CHANNEL.KuroPC or XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK then
        -- #105485 PC端使用的登出逻辑和移动端保持一致，都使用切换账号逻辑来登出
        XHgSdkManager.BackToLogin()
    else
        XHaruUserManager.Logout()
    end
end

function XUserManager.Logout(cb)
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS or
    XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK or XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        XHgSdkManager.Logout(cb)
    else
        XHaruUserManager.Logout(cb)
    end
end

function XUserManager.ClearLoginData()
    if XUserManager.Channel == XUserManager.CHANNEL.Android or XUserManager.Channel == XUserManager.CHANNEL.IOS or
    XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK or XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        XHgSdkManager.Logout()
    else
        XUserManager.SignOut()
    end
end

function XUserManager.SetUserId(userId)
    XLog.Debug("userId:" .. tostring(userId))
    XUserManager.UserId = userId
    CS.XHeroBdcAgent.UserId = "HeroEn#" .. (userId or "")
    XLoginManager.SetUserId(userId)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USERID_CHANGE, userId)
    XEventManager.DispatchEvent(XEventId.EVENT_USERID_CHANGE, userId)
end

function XUserManager.CleanUserId()
    XUserManager.UserId = nil
    XLoginManager.CleanUserId()
    XEventManager.DispatchEvent(XEventId.EVENT_USERID_CHANGE, nil)
end

function XUserManager.SetUserType(userType)
    XUserManager.UserType = userType
    XLoginManager.SetUserType(userType)
end

function XUserManager.CleanUserType()
    XUserManager.UserType = nil
    XLoginManager.CleanUserType()
end

function XUserManager.SetPasswordStatus(status)
    XUserManager.PasswordStatus = status
    XLoginManager.SetPasswordStatus(status)
end

function XUserManager.SetUserName(userName)
    XUserManager.UserName = userName

    if not XUserManager.IsUseSdk() then
        CS.UnityEngine.PlayerPrefs.SetString(XPrefs.UserName, XUserManager.UserName)
        CS.UnityEngine.PlayerPrefs.Save()
    end
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USERNAME_CHANGE, userName)
end

function XUserManager.SetToken(token)
    XUserManager.Token = token
    if XUserManager.Channel ~= XUserManager.CHANNEL.Android and XUserManager.Channel ~= XUserManager.CHANNEL.IOS or
    XUserManager.Channel == XUserManager.CHANNEL.KURO_SDK or XUserManager.Channel == XUserManager.CHANNEL.KuroPC then
        XLoginManager.SetToken(token)
    end
end

function XUserManager.SetLoginChannel(channel)
    XUserManager.LoginChannel = channel
    if XUserManager.LoginChannel then 
        CS.XLog.Debug(string.format("XUserManager.SetLoginChannel: type: %s , value: %s", type(XUserManager.LoginChannel), tostring(XUserManager.LoginChannel)))
        --pc版的要在获取到登录渠道后才设置选择服务器
        XServerManager.SelectChannelServer()
    end
end

function XUserManager.CleanToken()
    XUserManager.Token = nil
    XLoginManager.CleanToken()
end

local DoRunLogin = function()
    XEventManager.DispatchEvent(XEventId.EVENT_LOGIN_UI_OPEN)
    XFightUtil.ClearFight()
    if XDataCenter.MovieManager then
        XDataCenter.MovieManager.StopMovie()
    end
    CS.Movie.XMovieManager.Instance:Clear()
    CsXUiManager.Instance:Clear()
    XHomeSceneManager.LeaveScene()

    XDataCenter.Init()
    XMVCA:Init()

    XLuaUiManager.Open("UiLogin")
end

function XUserManager.SignOut()
    XLoginManager.Disconnect()

    if XUserManager.Channel ~= XUserManager.CHANNEL.Android and XUserManager.Channel ~= XUserManager.CHANNEL.IOS and
        XUserManager.Channel ~= XUserManager.CHANNEL.KuroPC and XUserManager.Channel ~= XUserManager.CHANNEL.KURO_SDK then
        XUserManager.SetUserId(nil)
        XUserManager.SetUserName(nil)
        XUserManager.SetToken(nil)
        XUserManager.SetPasswordStatus(0)
    end

    XEventManager.DispatchEvent(XEventId.EVENT_USER_LOGOUT)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USER_LOGOUT)

    DoRunLogin()
end

function XUserManager.OnSwitchAccountSuccess(uid, token, userType)
    XLoginManager.Disconnect()

    XUserManager.SetUserId(uid)
    XUserManager.SetUserType(userType)
    XUserManager.SetToken(token)

    XEventManager.DispatchEvent(XEventId.EVENT_USER_LOGOUT)
    CsXGameEventManager.Instance:Notify(XEventId.EVENT_USER_LOGOUT)
    
    DoRunLogin()
end

function XUserManager.GetLoginType()
    return XUserManager.LoginType[XUserManager.Channel]
end

-- 对应服务端Server文件Define.cs中Channel规则
function XUserManager.GetUniqueUserId()
    local prefix = ""
    if XUserManager.Channel == XUserManager.CHANNEL.HARU then   --dev（母包和win包）、
        prefix = "dev"
    elseif XUserManager.Channel == XUserManager.CHANNEL.HERO then
        local channelId = CS.XHeroSdkAgent.GetChannelId()
        if channelId == 18 or channelId == 56 then          --Hero（国服官服渠道18、56）
            prefix = "Hero"
        else                                                --国内其他安卓渠道使用英雄提供的渠道Id
            prefix = tostring(channelId)
        end
    end
    return string.format("%s#%s", prefix, XUserManager.UserId)
end

XRpc.LoginResponse = function(response)
    if response.Token then
        XUserManager.ReconnectedToken = response.Token
        --BDC
        CS.XHeroBdcAgent.UserId = "HeroEn#" .. XUserManager.UserId
        if XUserManager.Channel ~= XUserManager.CHANNEL.Android and 
            XUserManager.Channel ~= XUserManager.CHANNEL.IOS and 
            XUserManager.Channel ~= XUserManager.CHANNEL.KURO_SDK then
            XLoginManager.SetUserId(XUserManager.UserId)
            XLoginManager.SetToken(XUserManager.Token)
            XLoginManager.SetUserType(XUserManager.UserType)
            XLoginManager.SetPasswordStatus(XUserManager.PasswordStatus)
        end
    end
end