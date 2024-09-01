local pairs = pairs
local stringUtf8Len = string.Utf8Len
local MAX_SPEAKER_ACTOR_NUM = 14
local SPINE_INDEX_OFFSET = 100 -- spineλ�õ�ƫ��ֵ

local XMovieActionDialog = XClass(XMovieActionBase, "XMovieActionDialog")

local DoNextInterval = CS.XGame.ClientConfig:GetFloat("PcMovieDoNext")
local LastDonextTime = 0

function XMovieActionDialog:Ctor(actionData)
    local params = actionData.Params
    local paramToNumber = XDataCenter.MovieManager.ParamToNumber
    self.CueId = paramToNumber(params[18])
    self.SpineActorIndex = paramToNumber(params[19])
    self.SpineActorKouSpeed = paramToNumber(params[20])
    self.SkipRoleAnim = paramToNumber(params[1]) ~= 0
    self.RoleName = XUiHelper.ConvertLineBreakSymbol(XDataCenter.MovieManager.ReplacePlayerName(params[2]))
    local dialogContent = XDataCenter.MovieManager.ReplacePlayerName(params[3])
    if not dialogContent or dialogContent == "" then
        XLog.Error("XMovieActionDialog:OnRunning error:DialogContent is empty, actionId is: " .. self.ActionId)
    end
    self.DialogContent = XUiHelper.ConvertLineBreakSymbol(dialogContent)
    self.SpeakerIndexDic = {}
    self.SpeakerSpineIndexDic = {}
    for i = 1, MAX_SPEAKER_ACTOR_NUM do
        local actorIndex = paramToNumber(params[i + 3])
        if actorIndex ~= 0 then
            -- ����1����Ϊ�����1��λ�ã�����(SPINE_INDEX_OFFSET+1)��Ϊspine��1��λ��
            if actorIndex < SPINE_INDEX_OFFSET then
                self.SpeakerIndexDic[actorIndex] = true
            else
                actorIndex = actorIndex - SPINE_INDEX_OFFSET
                self.SpeakerSpineIndexDic[actorIndex] = true
            end
        end
    end
   
end

function XMovieActionDialog:GetEndDelay()
    if self.IsAutoPlay then
        local speed = XDataCenter.MovieManager.GetSpeed()
        local delayTime = XMovieConfigs.AutoPlayDelay + stringUtf8Len(self.DialogContent) * XMovieConfigs.PerWordDelay / speed
        delayTime = math.floor(delayTime)
        return delayTime
    else
        return 0
    end
end

function XMovieActionDialog:IsBlock()
    return true
end

function XMovieActionDialog:OnInit()
    self.IsAutoPlay = XDataCenter.MovieManager.IsAutoPlay()
    self.UiRoot.BtnSkipDialog.CallBack = function() self:OnClickBtnSkipDialog() end
    XDataCenter.InputManagerPc.RegisterFunc(CS.XUiPc.XUiPcCustomKeyEnum.UiMovieNext, self.UiRoot.BtnSkipDialog.CallBack, 0);
    -- XDataCenter.InputManagerPc.RegisterFunc(CS.XUiPc.XUiPcCustomKeyEnum.UiMovieNext, function() 
    --     local time = CS.UnityEngine.Time.time
    --     if time - LastDonextTime < DoNextInterval then
    --         return
    --     end
    --     LastDonextTime = CS.UnityEngine.Time.time
    --     self.UiRoot.BtnSkipDialog.CallBack()
    -- end, 0);
    self.UiRoot.DialogTypeWriter.CompletedHandle = function() self:OnTypeWriterComplete() end
    self.UiRoot.PanelDialog.gameObject:SetActiveEx(true)
    self.Record = {
        DialogContent = self.UiRoot.TxtWords.text,
        IsActive = self.UiRoot.PanelDialog.gameObject.activeSelf
    }
    local roleName = self.RoleName
    local dialogContent = self.DialogContent
    self.UiRoot.TxtName.text = roleName
    self.UiRoot.TxtWords.text = dialogContent
    self.UiRoot.TxtName.gameObject:SetActiveEx(roleName ~= "")

    self.IsTyping = true
    local typeWriter = self.UiRoot.DialogTypeWriter
    local speed = XDataCenter.MovieManager.GetSpeed()
    typeWriter.Duration = stringUtf8Len(dialogContent) * XMovieConfigs.TYPE_WRITER_SPEED / speed
    typeWriter:Play()
    -- ���ٲ���ʱ��������Ч
    if self.CueId ~= 0 and not XDataCenter.MovieManager.IsSpeedUp() then
        if self.AudioInfo then
            self.AudioInfo:Stop()
            self.AudioInfo = nil
        end
        self.IsAudioing = true
        self.AudioInfo = CS.XAudioManager.PlayCv(self.CueId, function()
            self:OnAudioComplete()
            self:StopSpineActorTalk()
        end, true)
        self:PlaySpineActorTalk()
    end
    self:PlaySpeakerAnim()
    XDataCenter.MovieManager.PushInReviewDialogList(roleName, dialogContent,self.CueId)
end

function XMovieActionDialog:OnDestroy()
    self.IsTyping = nil
    self.IsAutoPlay = nil
    self.IsAudioing = nil
    if self.AudioInfo then
        self.AudioInfo:Stop()
    end
    self:StopSpineActorTalk()
    XDataCenter.InputManagerPc.UnregisterFunc(CS.XUiPc.XUiPcCustomKeyEnum.UiMovieNext)
    self:ClearDelayId() 
end

function XMovieActionDialog:OnClickBtnSkipDialog()
    local time = CS.UnityEngine.Time.time
    if time - LastDonextTime < DoNextInterval then
        return
    end
    LastDonextTime = CS.UnityEngine.Time.time
    if self.IsTyping then
        -- �����У�ֱ����ʾ����������
        self.IsTyping = false
        if self.UiRoot.DialogTypeWriter then
            self.UiRoot.DialogTypeWriter:Stop()
        end
    else
        -- ������ȫ��ʾ�������Ļ������һ��MovieAction
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, false)
    end
end

function XMovieActionDialog:CanContinue()
    return not self.IsTyping
end

function XMovieActionDialog:OnTypeWriterComplete()
    self.IsTyping = false

    -- �Զ�����״̬�������ꡢ���������꣬������һ��MovieAction
    if self.IsAutoPlay and not self.IsAudioing then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    end
end

function XMovieActionDialog:OnAudioComplete()
    self.IsAudioing = false

    -- �Զ�����״̬�������ꡢ���������꣬������һ��MovieAction
    if self.IsAutoPlay and not self.IsTyping then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    end
end

function XMovieActionDialog:OnSwitchAutoPlay(autoPlay)
    self.IsAutoPlay = autoPlay
    self:ClearDelayId() -- ������ʱ��
    
    -- self.IsTyping == false ֻ������ǰdialog��ӡ���������
    -- �����¼�����MovieManager.DoAction()��ִ��action��Exit()������������������ʱ��
    if autoPlay and self.IsTyping == false and not self.IsAudioing then
        XEventManager.DispatchEvent(XEventId.EVENT_MOVIE_BREAK_BLOCK, true)
    end
end

function XMovieActionDialog:PlaySpeakerAnim()
    local skipAnim = self.SkipRoleAnim

    local speakerIndexDic = self.SpeakerIndexDic
    local actors = self.UiRoot.Actors
    for index, actor in pairs(actors) do
        if not speakerIndexDic[index] then
            actor:PlayAnimBack(skipAnim)
        else
            actor:PlayAnimFront(skipAnim)
        end
    end

    local spineActors = self.UiRoot.SpineActors
    for index, spineActor in pairs(spineActors) do
        if self.SpeakerSpineIndexDic[index] then
            spineActor:PlayAnimFront(skipAnim)
        else
            spineActor:PlayAnimBack(skipAnim)
        end
    end
end


function XMovieActionDialog:OnUndo()
    self.UiRoot.TxtWords.text = self.Record.DialogContent
    self.UiRoot.PanelDialog.gameObject:SetActiveEx(self.Record.IsActive)
    self.UiRoot.DialogTypeWriter.CompletedHandle = nil
    self:OnDestroy()
    XDataCenter.MovieManager.RemoveFromReviewDialogList(self.ActionId)
end

-- ��������ʱ�л�spine��������
function XMovieActionDialog:PlaySpineActorTalk()
    if self.SpineActorIndex ~= 0 then
        local actor = self.UiRoot:GetSpineActor(self.SpineActorIndex)
        actor:PlayKouTalkAnim(self.SpineActorKouSpeed)
    end
end

-- ֹͣspine�����������л�֮ǰ�Ķ���
function XMovieActionDialog:StopSpineActorTalk()
    if self.SpineActorIndex ~= 0 then
        local actor = self.UiRoot:GetSpineActor(self.SpineActorIndex)
        actor:PlayKouIdleAnim()
    end
end

return XMovieActionDialog