local setmetatable = setmetatable
local table = table
local math = math

local tableInsert = table.insert
local mathFloor = math.floor
local mathCeil = math.ceil

local GETTER_KEY_PREFIX = "Getter"
local OPEN_HONOR_LEVEL = "openHonorLevel"

local METHOD_NAME = {
    ChangePlayerName = "ChangePlayerNameRequest",
    ChangePlayerSign = "ChangePlayerSignRequest",
    ChangePlayerMark = "ChangePlayerMarkRequest",
    ChangePlayerBirthday = "ChangePlayerBirthdayRequest",
    ChangePlayerMedal = "SetCurrentMedalRequest",
    ChangeCommunication = "ChangeCommunicationRequest",
    ChangeAppearance = "SetAppearanceRequest",          -- 设置展示信息
    GetDormitoryList = "DormitoryListRequest",          -- 得到宿舍列表
}

local NextChangeNameTime
local TempDormitoryList             -- 宿舍列表缓存，只有登录的时候才会更新，进入宿舍系统后不再使用此数据，使用宿舍系统的数据

local PlayerData = {}               -- 玩家数据，外部只读
local Player = {}                   -- 玩家对象，公有方法
local Getter = {}                   -- 属性get

local LevelUpType = {
    Normal = 1,
    Honor = 2,
}

local function New()
    return setmetatable({}, {
            __metatable = "readonly",
            __index = function(_, k)
                if Player[k] ~= nil then
                    return Player[k]
                end

                local getterKey = GETTER_KEY_PREFIX .. k
                if Getter[getterKey] then
                    return Getter[getterKey]()
                end

                return PlayerData[k]
            end,
            __newindex = function()
                XLog.Error("attempt to update a readonly object")
            end,
        })
end

function Player.Init(playerData)
    PlayerData = playerData
    if PlayerData.Marks then
        PlayerData.MarkDic = PlayerData.MarkDic or {}
        for _, v in pairs(PlayerData.Marks) do
            PlayerData.MarkDic[v] = true
        end
    end
    XLog.Debug(string.format("PlayerId:%s, Name:%s", playerData.Id, playerData.Name))
    NextChangeNameTime = playerData.ChangeNameTime + XPlayerManager.PlayerChangeNameInterval
    CS.Movie.XMovieManager.Instance.PlayerName = PlayerData.Name
    Player.IsFirstOpenHonor = XSaveTool.GetData(OPEN_HONOR_LEVEL)
    TempDormitoryList = {}
end

function Getter.GetterExp()
    local item = XDataCenter.ItemManager.GetItem(XDataCenter.ItemManager.ItemId.TeamExp)
    if not item then
        return 0
    else
        return item:GetCount()
    end
end

function Player.GetAppearanceShowType()
    return PlayerData.AppearanceShowType ~= nil and XTool.Clone(PlayerData.AppearanceShowType) or {}
end

function Player.GetCurrentMedal()
    return PlayerData.CurrMedalId
end
---
--- 获取玩家展示设置
function Player.GetAppearanceSettingInfo()
    if PlayerData.AppearanceSettingInfo ~= nil then
        return XTool.Clone(PlayerData.AppearanceSettingInfo)
    else
        XLog.Error("Player.GetAppearanceSettingInfo函数错误，没有AppearanceSettingInfo数据")
        return { TitleType = XUiAppearanceShowType.ToAll,
            FashionType = XUiAppearanceShowType.ToAll,
            WeaponFashionType = XUiAppearanceShowType.ToAll,
            DormitoryType = XUiAppearanceShowType.ToAll,
            DormitoryId = 0,
        }
    end
end

function Player.IsNewPlayerTaskUIGroupActive(index)
    return (PlayerData.NewPlayerTaskActiveUi & (1 << index)) > 0
end

function Player.IsMark(id)
    if PlayerData.MarkDic and PlayerData.MarkDic[id] then
        return true
    end
    return false
end


--检测检测通讯系统
function Player.IsCommunicationMark(id)
    local marks = PlayerData.Communications or {}
    for _, v in pairs(marks) do
        if v == id then
            return true
        end
    end

    return false
end

function Player.IsGetDailyActivenessReward(index)
    index = index - 1
    return (PlayerData.DailyActivenessRewardStatus & (1 << index)) > 0
end

function Player.IsGetWeeklyActivenessReward(index)
    index = index - 1
    return (PlayerData.WeeklyActivenessRewardStatus & (1 << index)) > 0
end

function Player.HandlerPlayLevelUpAnimation()
    if Player.LevelUpType then
        XLuaUiManager.Open("UiPlayerUp", Player.LevelUpAnimationData.OldLevel, Player.LevelUpAnimationData.NewLevel, Player.LevelUpType)
        Player.LevelUpType = nil
        Player.LevelUpAnimationData = nil
        return true
    end
    return false
end

function Player.SetCurrMedalId(medalId)
    PlayerData.CurrMedalId = medalId
end

-----------------服务端数据同步-----------------
-- 看板娘Id
function Player.SetDisplayCharId(charId)
    PlayerData.DisplayCharId = charId
end

function Player.AddMark(id)
    if not PlayerData.MarkDic then
        PlayerData.MarkDic = {}
    end
    PlayerData.MarkDic[id] = true
end

--添加通讯系统标志
function Player.AddCommunicationMark(id)
    if not PlayerData.Communications then
        PlayerData.Communications = {}
    end

    tableInsert(PlayerData.Communications, id)
end

function Player.SetNewPlayerTaskActiveUi(result)
    PlayerData.NewPlayerTaskActiveUi = result
end

function Player.SetPlayerLikes(count)
    PlayerData.Likes = count
end

function Player.GetUnlockedMedalInfoById(id)
    return PlayerData.UnlockedMedalInfos[id]
end

function Player.SetHeadPortrait(id)
    PlayerData.CurrHeadPortraitId = id
end

function Player.SetHeadFrame(id)
    PlayerData.CurrHeadFrameId = id
end

--荣耀勋阶是否开放
function Player.IsHonorLevelOpen()
    return XFunctionManager.JudgeCanOpen(XFunctionManager.FunctionName.HonorLevel)
end

function Player.CheckIsMaxLevel(level)
    return level >= XPlayerManager.PlayerMaxLevel
end

--荣耀勋阶
function Player.GetHonorLevel()
    return PlayerData.HonorLevel or 1
end

--小队等级
function Player.GetLevel()
    return PlayerData.Level or 1
end

--如果小队等级超过指定最大值(120)，转为荣耀勋阶
function Player.GetLevelOrHonorLevel()
    if Player.IsHonorLevelOpen() then
        return Player.GetHonorLevel()
    else
        return Player.GetLevel()
    end
end

function Player.GetMaxExp()
    local level = Player.GetLevelOrHonorLevel()
    return XPlayerManager.GetMaxExp(level, Player.IsHonorLevelOpen())
end

function Player.GetMaxLevel()
    return XPlayerManager.PlayerMaxLevel
end

--是否首次打开荣誉界面
function Player.CheckIsFirstOpenHonor()
    local isFirstOpenHonor = Player.IsFirstOpenHonor
    if isFirstOpenHonor then
        Player.IsFirstOpenHonor = nil
        XSaveTool.RemoveData(OPEN_HONOR_LEVEL)
    end

    return isFirstOpenHonor
end

--是否修改过生日
function Player.IsChangedBirthday()
    return PlayerData.BirthdayInfo and PlayerData.BirthdayInfo.IsChange
end

--检查生日剧情是否解锁
function Player.CheckStoryIsUnlock(chapterId)
    return PlayerData.BirthdayInfo and PlayerData.BirthdayInfo.UnLockCg[chapterId]
end

--播放生日剧情动画
function Player.PlayBirthdayStory()
    if PlayerData.BirthdayInfo and PlayerData.BirthdayInfo.BirthdayStoryId then
        XDataCenter.MovieManager.PlayMovie(PlayerData.BirthdayInfo.BirthdayStoryId)
        PlayerData.BirthdayInfo.BirthdayStoryId = nil
        return true
    end
    return false
end

--@region XRpc

-- 功能开发标记
XRpc.NotifyPlayerMarks = function(data)
    XTool.LoopCollection(data.Ids, function(id)
            Player.AddMark(id)
        end)
end

-- 玩家名字
XRpc.NotifyPlayerName = function(data)
    PlayerData.Name = data.Name
    CS.Movie.XMovieManager.Instance.PlayerName = PlayerData.Name
end

XRpc.NotifyBirthdayPlot = function(data)
    --[[
    @desc:同步生日通讯已解锁的cg，以及下次生日时间
    @data = {
    @int NextActiveYear 下次过生日的年份
    @int IsChange  是否修改过生日
    @list<int> UnLockCg 已经解锁的生日id
    ]]--
    PlayerData.BirthdayInfo = PlayerData.BirthdayInfo or {}
    PlayerData.BirthdayInfo.NextActiveYear = data.NextActiveYear
    PlayerData.BirthdayInfo.IsChange = data.IsChange == 1
    PlayerData.BirthdayInfo.UnLockCg = {}
    for _, id in ipairs(data.UnLockCg) do
        PlayerData.BirthdayInfo.UnLockCg[id] = true
    end
    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_SET_BIRTHDAY, PlayerData.Birthday) --触发按钮更新
end

XRpc.NotifyBirthdayPlayCg = function(data)
    --[[
    @desc:上线需要同步播放的CG
    @data = {
    @int ChapterId 需要播放剧情的 chapterId
    }
    ]]--
    if data then
        local config = XArchiveConfigs.GetBirthdayPlotConfigById(data.ActivityId)
        if config and config.StoryChapterId then
            local chapterId = config.StoryChapterId
            local detailEntityList =  XDataCenter.ArchiveManager.GetArchiveStoryDetailList(chapterId)
            local detailEntity = detailEntityList and detailEntityList[1] or nil
            if detailEntity then
                local storyId= detailEntity:GetStoryId(1) -- 找到需要播放的第一个storyId
                PlayerData.BirthdayInfo = PlayerData.BirthdayInfo or {}
                PlayerData.BirthdayInfo.BirthdayStoryId = storyId
                XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_UNLOCK_BIRTHDAY_STORY)
            else
                XLog.Error("XRpc.NotifyBirthdayPlayCg Recv Error", data)
            end
        end
    end
end

-- 玩家签名
XRpc.NotifySign = function(data)
    PlayerData.Sign = data.Sign
end

-- 新手目标相关
XRpc.NotifyNewPlayerTaskStatus = function(data)
    PlayerData.NewPlayerTaskActiveDay = data.NewPlayerTaskActiveDay
    Player.SetNewPlayerTaskActiveUi(data.NewPlayerTaskActiveUi)
    XEventManager.DispatchEvent(XEventId.EVENT_NEWBIETASK_DAYCHANGED)
    local maxTab = #XTaskConfig.GetNewPlayerTaskGroupTemplate()
    local activeDay = (data.NewPlayerTaskActiveDay > maxTab) and maxTab or data.NewPlayerTaskActiveDay
    XDataCenter.TaskManager.SaveNewPlayerHint(XDataCenter.TaskManager.NewPlayerLastSelectTab, activeDay)
end

XRpc.NotifyActivenessStatus = function(data)
    PlayerData.DailyActivenessRewardStatus = data.DailyActivenessRewardStatus
    PlayerData.WeeklyActivenessRewardStatus = data.WeeklyActivenessRewardStatus
end

--@region 玩家升级

local function LevelUpAnimation(oldLevel, newLevel, levelUpType)
    Player.LevelUpAnimationData = {
        OldLevel = oldLevel,
        NewLevel = newLevel
    }
    Player.LevelUpType = levelUpType
    XEventManager.DispatchEvent(XEventId.EVENT_PLAYER_LEVEL_CHANGE, newLevel)
end

XRpc.NotifyPlayerLevel = function(data)
    if PlayerData.Level >= data.Level then
        return
    end

    local oldLevel = PlayerData.Level
    PlayerData.Level = data.Level
    LevelUpAnimation(oldLevel, data.Level, LevelUpType.Normal)

    --荣耀勋阶开放，用于打开个人信息界面时候播放一下特效
    if PlayerData.Level == XPlayerManager.PlayerMaxLevel then
        Player.IsFirstOpenHonor = true
        XSaveTool.SaveData(OPEN_HONOR_LEVEL, true)
    end
    --CheckPoint: APPEVENT_LEVEL
    XAppEventManager.LevelAppLogEvent(data.Level)
end

XRpc.NotifyHonorLevel = function(data)
    if PlayerData.HonorLevel >= data.HonorLevel then
        return
    end
    local oldLevel = PlayerData.HonorLevel
    PlayerData.HonorLevel = data.HonorLevel
    LevelUpAnimation(oldLevel, data.HonorLevel, LevelUpType.Honor)
end

--@endregion


XRpc.NotifyDailyReciveGiftCount = function(data)
    PlayerData.DailyReceiveGiftCount = data.DailyReceiveGiftCount
end

XRpc.NotifyTips = function(res)
    XUiManager.TipCode(res.Code)
end
-- 推送协议屏蔽更改
XRpc.NotifyShieldedProtocol = function(data)
    XNetwork.SetShieldedProtocolList(data.ShieldedProtocolList)
end

--@endregion

--谷歌积分奖励通知
XRpc.NotifyGooglePlayPoints = function(data)
    XUiManager.SystemDialogTip(CS.XTextManager.GetText("TipTitle"), CS.XGame.ClientConfig:GetString("GooglePlayHintText"), XUiManager.DialogType.OnlySure)
end

--@region 服务端接口方法
-----------------服务端数据同步-----------------
local DoChangeResultError = function(code, nextCanChangeTime)
    if code == XCode.PlayerDataManagerChangeNameTimeLimit then
        NextChangeNameTime = nextCanChangeTime

        local timeLimit = nextCanChangeTime - XTime.GetServerNowTimestamp()
        local hour = mathFloor(timeLimit / 3600)
        local minute = mathCeil(timeLimit % 3600 / 60)

        if minute == 60 then
            hour = hour + 1
            minute = 0
        end

        XUiManager.TipCode(code, hour, minute)
        return
    end

    XUiManager.TipCode(code)
end

function Player.ChangeName(name, cb)
    if NextChangeNameTime > XTime.GetServerNowTimestamp() then
        DoChangeResultError(XCode.PlayerDataManagerChangeNameTimeLimit, NextChangeNameTime)
        return
    end

    XNetwork.Call(METHOD_NAME.ChangePlayerName, { Name = name },
        function(response)
            if response.Code == XCode.Success then
                NextChangeNameTime = response.NextCanChangeTime
                PlayerData.ChangeNameTime = response.NextCanChangeTime - XPlayerManager.PlayerChangeNameInterval
                cb()
                return
            end

            DoChangeResultError(response.Code, response.NextCanChangeTime)
        end)
end

local CheckCanChangeBirthday = function ()
    return not PlayerData.Birthday or not PlayerData.Birthday.IsChange
end

--修改生日
function Player.ChangeBirthday(mon, day, cb)
    if not CheckCanChangeBirthday() then
        XUiManager.TipCode(XCode.PlayerDataManagerBirthdayAlreadySet)
        return
    end

    XNetwork.Call(METHOD_NAME.ChangePlayerBirthday, { Mon = mon, Day = day },
        function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end
            PlayerData.Birthday = {
                Mon = mon,
                Day = day
            }

            cb()
        end)
end

--保存展示信息
function Player.SetAppearance(charactersAppearanceType, characterIds, appearanceSettingInfo, cb)
    XNetwork.Call(METHOD_NAME.ChangeAppearance,
        { CharactersAppearanceType = charactersAppearanceType, Characters = characterIds, AppearanceSettingInfo = appearanceSettingInfo },
        function(res)
            if res.Code ~= XCode.Success then
                XUiManager.TipCode(res.Code)
                return
            end
            XUiManager.TipText("SetAppearanceSuccess")
            PlayerData.ShowCharacters = characterIds
            PlayerData.AppearanceShowType = charactersAppearanceType
            PlayerData.AppearanceSettingInfo = appearanceSettingInfo
            if cb then
                cb()
            end
        end)
end

---
--- 获取玩家的宿舍列表,结构为{ DormitoryId, DormitoryName }
function Player.GetDormitoryList(cb)
    -- 宿舍系统要进入的时候才会请求并初始化宿舍数据
    local dormData = XDataCenter.DormManager.GetDormitoryData()
    if next(dormData) then
        -- 进入过宿舍系统
        local dormitoryList = {}
        for id, dormRoomData in pairs(dormData) do
            if dormRoomData:WhetherRoomUnlock() then
                local temp = {}
                temp.DormitoryId = id
                temp.DormitoryName = dormRoomData:GetRoomName()

                table.insert(dormitoryList, temp)
            end
        end
        if cb then
            cb(dormitoryList)
        end
    else
        -- 还未进入过宿舍系统，使用请求的宿舍列表
        if next(TempDormitoryList) then
            if cb then
                cb(TempDormitoryList)
            end
        else
            XNetwork.Call(METHOD_NAME.GetDormitoryList, nil, function(res)
                    if res.Code ~= XCode.Success then
                        XUiManager.TipCode(res.Code)
                        return
                    end
                    TempDormitoryList = res.DormitoryList
                    if cb then
                        cb(res.DormitoryList)
                    end
                end)
        end
    end
end

--添加标记
function Player.ChangeMarks(id)
    Player.AddMark(id)
    XNetwork.Call(METHOD_NAME.ChangePlayerMark, { MaskId = id }, function()
            -- if res.Code == XCode.Success then
            -- Player.AddMark(id)
            -- end
        end)
end

--添加标记
function Player.ChangeCommunicationMarks(id)
    Player.AddCommunicationMark(id)
    XNetwork.Call(METHOD_NAME.ChangeCommunication, { Id = id }, function()
            -- if res.Code == XCode.Success then

            -- end
        end)
end


function Player.ChangeSign(msg, cb)
    XNetwork.Call(METHOD_NAME.ChangePlayerSign, { Msg = msg },
        function(response)
            if response.Code ~= XCode.Success then
                XUiManager.TipCode(response.Code)
                return
            end

            PlayerData.Sign = msg
            cb()
        end)
end

function Player.ChangeMedal(id, cb)
    XNetwork.Call(METHOD_NAME.ChangePlayerMedal, { Id = id },
        function(response)
            if (response.Code == XCode.Success) then
                Player.SetCurrMedalId(id)
                if cb then
                    cb()
                end
                XEventManager.DispatchEvent(XEventId.EVENT_MEDAL_USE)
            else
                XUiManager.TipCode(response.Code)
            end
        end)
end


function Player.IsMedalUnlock(medalId)
    if not PlayerData.UnlockedMedalInfos then return false end
    return PlayerData.UnlockedMedalInfos[medalId] and true or false
end

function Player.AsyncMedalIds(MedalIds, IsAddNew)
    if not PlayerData.UnlockedMedalInfos then PlayerData.UnlockedMedalInfos = {} end
    for _, v in pairs(MedalIds or {}) do
        if IsAddNew then
            XDataCenter.MedalManager.AddNewMedal(v, XMedalConfigs.MedalType.Normal)
            PlayerData.UnlockedMedalInfos[MedalIds.Id] = MedalIds
            PlayerData.NewMedalInfo = MedalIds
        else
            PlayerData.UnlockedMedalInfos[v.Id] = v
        end
    end
end
--@endregion

XPlayer = XPlayer or New()
