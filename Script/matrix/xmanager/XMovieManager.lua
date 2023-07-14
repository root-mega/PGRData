local tonumber = tonumber
local tostring = tostring
local mathFloor = math.floor
local tableInsert = table.insert
local tableRemove = table.remove
local next = next
local CSMovieXMovieManagerInstance = CS.Movie.XMovieManager.Instance

local UI_MOVIE = "UiMovie"
local RESOLUTION_RATIO = CS.XResolutionManager.OriginWidth / CS.XResolutionManager.OriginHeight / CS.XUiManager.DefaultScreenRatio
local TIMELINE_SECONDS_TRANS = 1 / 60
local DisableFunction = false     --功能屏蔽标记（调试模式时使用）
local CurrentAction = nil

local ActionClass = {
    [101] = require("XMovieActions/XMovieActionBgSwitch"), --背景切换
    [102] = require("XMovieActions/XMovieActionTheme"), --章节主题
    [103] = require("XMovieActions/XMovieActionBgScale"), --背景缩放位置调整
    [104] = require("XMovieActions/XMovieActionBgMoveAnimation"), --背景位移动画

    [201] = require("XMovieActions/XMovieActionActorAppear"), --演员出现
    [202] = require("XMovieActions/XMovieActionActorDisappear"), --演员消失
    [203] = require("XMovieActions/XMovieActionActorShift"), --演员位移
    [204] = require("XMovieActions/XMovieActionActorChangeFace"), --演员表情
    [205] = require("XMovieActions/XMovieActionActorAlphaChange"), --演员背景

    [301] = require("XMovieActions/XMovieActionDialog"), --普通对话
    [302] = require("XMovieActions/XMovieActionSelection"), --选择分支对话
    [303] = require("XMovieActions/XMovieActionDelaySkip"), --延迟跳转
    [304] = require("XMovieActions/XMovieActionFullScreenDialog"), --全屏字幕
    [305] = require("XMovieActions/XMovieActionYieldResume"), --挂起/恢复

    [401] = require("XMovieActions/XMovieActionSoundPlay"), --BGM/CV/音效 播放
    [402] = require("XMovieActions/XMovieActionAudioInterrupt"), --BGM/CV/音效 打断

    [501] = require("XMovieActions/XMovieActionEffectPlay"), --特效播放
    [502] = require("XMovieActions/XMovieActionAnimationPlay"), --UI动画播放
    [503] = require("XMovieActions/XMovieActionVideoPlay"), --视频播放
    [504] = require("XMovieActions/XMovieActionSetGray"), --灰度设置
    [505] = require("XMovieActions/XMovieActionUnLoad"), --动效卸载
    [506] = require("XMovieActions/XMovieActionPrefabAnimation"), --预制体动画
    [507] = require("XMovieActions/XMovieActionInsertTipAppear"), --中间插入横幅
    [508] = require("XMovieActions/XMovieActionInsertTipDisappear"), --中间横幅消失
    [509] = require("XMovieActions/XMovieActionShowInsertPanel"), --显示两边插入分屏
    [510] = require("XMovieActions/XMovieActionHideInsertPanel"), --隐藏插入分屏

    [601] = require("XMovieActions/XMovieActionStaff"), --staff职员表

    --3D剧情相关
    [701] = require("XMovieActions/XMovieActionSceneLoad"), --场景加载
    [702] = require("XMovieActions/XMovieActionCameraLoad"), --摄像头加载
    [703] = require("XMovieActions/XMovieActionCameraPlay"), --播放相机动画
    [704] = require("XMovieActions/XMovieActionActorLoad"), --角色模型加载
    [705] = require("XMovieActions/XMovieActionModelMove"), --角色移动
    [706] = require("XMovieActions/XMovieActionSetActorTransform"), --设置角色位置
    [707] = require("XMovieActions/XMovieActionModelAnimationPlay"), --角色动画播放
    [708] = require("XMovieActions/XMovieActionDialog3D"), --3D剧情对话框
    [709] = require("XMovieActions/XMovieActionTimelineLoad"), --Timeline动画预制体加载
    [710] = require("XMovieActions/XMovieActionTimelinePlay"), --Timeline动画播放
    [711] = require("XMovieActions/XMovieActionPlayCV"), --播放角色语音
    [712] = require("XMovieActions/XMovieActionSwitchMixMode"), --切换2D与3D混合模式
    [713] = require("XMovieActions/XMovieActionSetBg"), --设置混合模式背景图片
}

--可以通过上一页返回到的节点
local MovieBackFilter = {
    [301] = true, --普通对话
}

XMovieManagerCreator = function()
    local AllMovieActions = {}
    local ActionIdToIndexDics = {}

    local CurPlayingMovieId
    local CurPlayingActionIndex
    local AutoPlay
    local WaitToPlayList = {}
    local DelaySelectionDic = {}
    local ReviewDialogList = {}
    local EndCallBack
    local IsPlaying
    local IsYield
    local IsPause = false
    local YieldCallBack
    local MovieBackStack = XStack.New()

    local function InitMovieActions(movieId)
        local movieActions = {}
        local actionIdToIndexDic = {}

        local findEnd = false
        local movieCfg = XMovieConfigs.GetMovieCfg(movieId)
        for index, actionData in ipairs(movieCfg) do
            local actionClass = ActionClass[actionData.Type]
            if not actionClass then
                XLog.Error("XMovieManager.InitMovieActions 配置节点类型错误，找不到对应的节点，Type: " .. actionData.Type)
                return
            end

            tableInsert(movieActions, actionClass.New(actionData))
            actionIdToIndexDic[actionData.ActionId] = index

            if actionData.IsEnd ~= 0 then
                findEnd = true
            end
        end

        if not findEnd then
            XLog.Error("XMovieManager.InitMovieActions error:没有配置结束标记IsEnd, movieId: ", movieId)
            return
        end

        AllMovieActions[movieId] = movieActions
        ActionIdToIndexDics[movieId] = actionIdToIndexDic

        return movieActions
    end

    local function GetMovieActions(movieId)
        if not AllMovieActions[movieId] then
            InitMovieActions(movieId)
        end

        if not AllMovieActions[movieId] then
            XLog.Error("XMovieManager GetMovieActions error:actions not exsit, movieId is: ", movieId)
            return
        end

        return AllMovieActions[movieId]
    end

    local function GetActionIndexById(movieId, actionId)
        local dic = ActionIdToIndexDics[movieId]
        if not dic then
            XLog.Error("XMovieManager GetActionIndexById error:dic not exsit, movieId is: " .. movieId .. ", actionId is: " .. actionId)
            return
        end

        local index = dic[actionId]
        if not index then
            XLog.Error("XMovieManager GetActionIndexById error:index not exsit, actionId is: " .. actionId)
        end
        return index
    end

    local function OnPlayBegin(movieId, hideSkipBtn,isRelease)
        CurPlayingMovieId = movieId
        CurPlayingActionIndex = 1
        WaitToPlayList = GetMovieActions(movieId)
        ReviewDialogList = {}
        MovieBackStack:Clear()
        IsPlaying = true
        IsPause = false
        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOVIE_BEGIN, movieId)
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BEGIN, movieId)

        if XLuaUiManager.IsUiShow(UI_MOVIE) then return end

        if (not CS.XFight.IsRunning) and isRelease then
            CsXUiManager.Instance:ReleaseAll(CsXUiType.Normal)
        end

        XLuaUiManager.Open(UI_MOVIE, hideSkipBtn)
    end

    local function OnPlayEnd()
        if not CurPlayingMovieId then return end
        local dict = {}
        dict["story_id"] = CurPlayingMovieId
        dict["role_level"] = XPlayer.GetLevel()
        CS.XRecord.Record(dict, "200002", "StorylineEnd")
        
        if not CS.XFight.IsRunning then
            CsXUiManager.Instance:RevertAll()
        end

        CurPlayingMovieId = nil
        CurPlayingActionIndex = nil
        AutoPlay = nil
        ReviewDialogList = {}
        DelaySelectionDic = {}
        WaitToPlayList = {}
        IsPlaying = nil
        IsYield = nil
        IsPause = false
        YieldCallBack = nil
        MovieBackStack:Clear()

        CsXGameEventManager.Instance:Notify(XEventId.EVENT_MOVIE_END)
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_END)

        if CurrentAction then
            CurrentAction:OnDestroy()
        end

        if XLuaUiManager.IsUiShow(UI_MOVIE) then
            XLuaUiManager.Close(UI_MOVIE)
        end
    end

    --剧情UI完全关闭，所有节点清理行为结束
    local function AfterUiClosed()
        if EndCallBack then
            local endCb = EndCallBack --可能会嵌套播放，避免新剧情打开时回调被错误清掉
            EndCallBack = nil

            -- 剧情过程中强制下线
            if not XLoginManager.IsLogin() then
                return
            end

            endCb()
        end
    end

    local function DoAction(ignoreLock)
        if not CurPlayingActionIndex or not next(WaitToPlayList) then
            OnPlayEnd()
            return
        end

        if IsYield then
            return
        end

        if IsPause then
            return
        end
        local action = WaitToPlayList[CurPlayingActionIndex]

        if not ignoreLock and action:IsWaiting() then
            return
        end

        if action:Destroy() then
            if action:IsEnding() then
                OnPlayEnd()
                return
            end
            MovieBackStack:Push(CurPlayingActionIndex)
            local indexChanged

            local selectedActionId = action:GetSelectedActionId()
            if selectedActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, selectedActionId)
                indexChanged = true
            end

            local delaySelectedActionId = action:GetDelaySelectActionId()
            if delaySelectedActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, delaySelectedActionId)
                indexChanged = true
            end

            local resumeActionId = action:GetResumeActionId()
            if resumeActionId ~= 0 then
                CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, resumeActionId)
                indexChanged = true
            end

            if not indexChanged then
                local nextActionId = action:GetNextActionId()
                if nextActionId ~= 0 then
                    CurPlayingActionIndex = GetActionIndexById(CurPlayingMovieId, nextActionId)
                    indexChanged = true
                end
            end

            if not indexChanged then
                CurPlayingActionIndex = CurPlayingActionIndex + 1
            end

            action = WaitToPlayList[CurPlayingActionIndex]
            CurrentAction = action
            if not action then
                OnPlayEnd()
                return
            end
        end

        action:ChangeStatus()
    end

    local XMovieManager = {}

    function XMovieManager.Init()
        XEventManager.AddEventListener(XEventId.EVENT_MOVIE_BREAK_BLOCK, DoAction)
        XEventManager.AddEventListener(XEventId.EVENT_MOVIE_UI_CLOSED, AfterUiClosed)

        DisableFunction = XMovieManager.CheckFuncDisable()
    end

    local function PlayOldMovie(movieId, cb)
        if not CSMovieXMovieManagerInstance:CheckMovieExist(movieId) then return end
        CSMovieXMovieManagerInstance:PlayById(movieId, function()
            if cb then cb() end
        end)
    end

    local function PlayNewMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease)
        EndCallBack = cb
        YieldCallBack = yieldCb
        OnPlayBegin(movieId, hideSkipBtn,isRelease)
    end

    function XMovieManager.PlayMovie(movieId, cb, yieldCb, hideSkipBtn,isRelease)
        if DisableFunction or XUiManager.IsHideFunc then
            XLog.Warning(string.format("已跳过剧情%s", movieId))
            if cb then cb() end
            return
        end
        local dict = {}
        if isRelease == nil then
            isRelease = true
        end
        dict["story_id"] = movieId
        dict["role_level"] = XPlayer.GetLevel()
        CS.XRecord.Record(dict, "200001", "StorylineStart")
        movieId = tostring(movieId)
        if XMovieConfigs.CheckMovieConfigExist(movieId) then
            PlayNewMovie(movieId, cb, yieldCb, hideSkipBtn, isRelease)
        else
            PlayOldMovie(movieId, cb)
        end
    end

    function XMovieManager.StopMovie()
        if not XMovieManager.IsPlayingMovie() then return end
        if not XLuaUiManager.IsUiShow(UI_MOVIE) then return end
        OnPlayEnd()
    end

    function XMovieManager.BackToLastAction()
        local curAction = WaitToPlayList[CurPlayingActionIndex]
        local lastId = MovieBackStack:Peek()
        if lastId ~= CurPlayingActionIndex then
            curAction:OnUndo()
            curAction:OnReset()
        end
        if MovieBackStack:Count() == 0 then
            CurPlayingActionIndex = 1
        end
        while (MovieBackStack:Count() ~= 0) do
            local currIndex = MovieBackStack:Pop()
            local action = WaitToPlayList[currIndex]
            action:OnUndo()
            action:OnReset()
            if MovieBackFilter[action:GetType()] then
                CurPlayingActionIndex = currIndex
                break
            end
            if MovieBackStack:Count() == 0 then
                CurPlayingActionIndex = 1
                break
            end
        end
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK)
    end

    local function IsPlayingNewMovie()
        return IsPlaying
    end

    local function IsPlayingOldMovie()
        return CSMovieXMovieManagerInstance:IsPlayingMovie()
    end

    function XMovieManager.IsPlayingMovie()
        return IsPlayingNewMovie() or IsPlayingOldMovie()
    end

    function XMovieManager.IsMovieYield()
        if not XMovieManager.IsPlayingMovie() then return false end
        return IsYield or false
    end

    function XMovieManager.YiledMovie()
        if not YieldCallBack then return end --没有恢复回调时不允许挂起

        IsYield = true

        YieldCallBack()
        YieldCallBack = nil
    end

    function XMovieManager.IsMoviePause()
        if not XMovieManager.IsPlayingMovie() then return false end
        return IsPause or false
    end

    function XMovieManager.SetMoviePause(isPause)
        IsPause = isPause
    end

    function XMovieManager.SwitchMovieState()
        IsPause = not IsPause
        local action = WaitToPlayList[CurPlayingActionIndex]
        if (not IsPause) and action:CanContinue() then
            DoAction()
        end
    end

    function XMovieManager.ResumeMovie(index)
        if not IsPlayingNewMovie() then
            if IsPlayingOldMovie() then
                XLog.Error("XMovieManager.ResumeMovie Error: 老版剧情不支持挂起恢复操作")
                return
            end

            XLog.Error("XMovieManager.ResumeMovie Error: 当前没有播放中的剧情")
            return
        end

        local action = WaitToPlayList[CurPlayingActionIndex]
        if not IsYield or not action.ResumeAtIndex then
            XLog.Error("XMovieManager.ResumeMovie Error: 当前没有挂起中的剧情, action: ", action)
            return
        end

        IsYield = nil
        action:ResumeAtIndex(index)
        DoAction()
    end

    function XMovieManager.PushInReviewDialogList(roleName, dialogContent)
        roleName = roleName and roleName ~= "" and roleName .. ":  " or ""
        dialogContent = dialogContent and dialogContent ~= "" and '"' .. dialogContent .. '"' or ""

        local data = {
            RoleName = roleName,
            Content = dialogContent,
        }
        tableInsert(ReviewDialogList, data)
    end

    function XMovieManager.RemoveFromReviewDialogList()
        if ReviewDialogList and #ReviewDialogList > 0 then
            tableRemove(ReviewDialogList)
        end
    end

    function XMovieManager.DelaySelectAction(key, actionId)
        DelaySelectionDic[key] = actionId
    end

    function XMovieManager.GetDelaySelectActionId(key)
        local actionId = DelaySelectionDic[key]
        if actionId then
            DelaySelectionDic[key] = nil
        else
            actionId = 0
        end
        return actionId
    end

    function XMovieManager.SwitchAutoPlay()
        AutoPlay = not AutoPlay
        local action = WaitToPlayList[CurPlayingActionIndex]
        if action and action:CanContinue() then
            XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_AUTO_PLAY, AutoPlay)
        end
    end

    function XMovieManager.IsAutoPlay()
        return AutoPlay
    end

    function XMovieManager.GetReviewDialogList()
        return ReviewDialogList
    end

    function XMovieManager.ReplacePlayerName(str)
        return XUiHelper.ReplaceWithPlayerName(str, XMovieConfigs.PLAYER_NAME_REPLACEMENT)
    end

    function XMovieManager.Fit(width)
        return width * RESOLUTION_RATIO
    end

    function XMovieManager.ParamToNumber(param)
        return param and param ~= "" and tonumber(param) or 0
    end

    function XMovieManager.TransTimeLineSeconds(time)
        time = time or 0
        local interger = mathFloor(time)
        local decimal = time - interger
        return interger + TIMELINE_SECONDS_TRANS * decimal
    end

    function XMovieManager.ReloadMovies()
        if not XMain.IsDebug then return end

        AllMovieActions = {}
        ActionIdToIndexDics = {}
        XMovieConfigs.DeleteMovieCfgs()
    end

    function XMovieManager.GetMovieDescription()
        return XMovieConfigs.GetMovieSkipSkipDesc(CurPlayingMovieId)
    end

    function XMovieManager.GetCurPlayingMovieId()
        return CurPlayingMovieId
    end

    --检测功能开关
    function XMovieManager.CheckFuncDisable()
        return XMain.IsDebug and XSaveTool.GetData(XPrefs.StoryTrigger)
    end

    function XMovieManager.ChangeFuncDisable(state)
        DisableFunction = state
        XSaveTool.SaveData(XPrefs.StoryTrigger, DisableFunction)
    end

    XMovieManager.Init()
    return XMovieManager
end