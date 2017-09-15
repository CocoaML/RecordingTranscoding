//
//  BlazeiceAudioRecordView.m
//  RecordingTranscoding
//
//  Created by 白冰 on 15/12/1.
//  Copyright (c) 2015年 lezhixing. All rights reserved.

#import "BlazeiceAudioRecordView.h"
#import "BlazeicePublicMethod.h"
@interface BlazeiceAudioRecordView (){
    NSString *vedioPath;
    NSString *lastVedio;
    BlazeiceAudioRecordAndTransCoding *audioRecord;
    
    BOOL vedioing;//正在录音
    BOOL waitMixAmr;
    NSTimer *timer;
    
    UIImageView *recordVoiceImageView;
    UIButton *recordButton;
    UIButton *actionButton;
    UILabel *timeLabel;
    UIView *recordViewBG;
    long long totalSeconds;
    BOOL isWantOut;
    
// ml 增加开始
    UIButton *playVoiceButton;
    UIButton *deleteVoiceButton;
    NSTimer  *_playerTimer;
    AVAudioPlayer *_tempPlayer;
// ml 增加结束
}

@end

@implementation BlazeiceAudioRecordView

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)loadView {
    [self setBackgroundColor:RGB(0, 0, 0, 0.3f)];
    
    recordViewBG = [[UIView alloc] initWithFrame:CGRectMake(0,V_S_H-240,V_S_W,240)];
    [recordViewBG setBackgroundColor:[UIColor whiteColor]];
    [self addSubview:recordViewBG];
    
    recordVoiceImageView = [[UIImageView alloc]initWithFrame:CGRectMake((V_S_W-117)/2, 24, 117, 15.5)];
    recordVoiceImageView.image =[UIImage imageNamed:@"recordAudio_voice1"];
    recordVoiceImageView.animationImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"recordAudio_voice1"],[UIImage imageNamed:@"recordAudio_voice2"],[UIImage imageNamed:@"recordAudio_voice3"],[UIImage imageNamed:@"recordAudio_voice5"],[UIImage imageNamed:@"recordAudio_voice5"],[UIImage imageNamed:@"recordAudio_voice1"], nil];
    [recordViewBG addSubview:recordVoiceImageView];
    recordVoiceImageView.tag=1;
    recordVoiceImageView.animationDuration =0.5;
    
    recordButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [recordButton setFrame:CGRectMake((V_S_W-130)/2, 62, 130, 130)];
    
    [recordButton setImage:[UIImage imageNamed:@"recordAudio_recording"] forState:UIControlStateNormal];
    [recordButton addTarget:self action:@selector(recordButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [recordViewBG addSubview:recordButton];
    
    // ml 增加开始
    /* 删除录音按钮 */
    deleteVoiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [deleteVoiceButton setFrame:CGRectMake(0, 0, 44, 44)];
    deleteVoiceButton.center = CGPointMake(CGRectGetMinX(recordButton.frame)/2, CGRectGetHeight(recordViewBG.frame)/2);
    [deleteVoiceButton setImage:[UIImage imageNamed:@"delete_audio.png"] forState:UIControlStateNormal];
    [deleteVoiceButton addTarget:self action:@selector(deleteVoiceButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [recordViewBG addSubview:deleteVoiceButton];
    
    /* 播放录音按钮 */
    playVoiceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [playVoiceButton setFrame:CGRectMake(0, 0, 44, 44)];
    playVoiceButton.center = CGPointMake(V_S_W - (V_S_W - CGRectGetMaxX(recordButton.frame))/2, CGRectGetHeight(recordViewBG.frame)/2);
    [playVoiceButton addTarget:self action:@selector(playVoiceButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [recordViewBG addSubview:playVoiceButton];
    // ml 增加结束

    UIImageView *animationView = [[UIImageView alloc]initWithFrame:CGRectMake(10, 12, 20, 20)];
    animationView.image =[UIImage imageNamed:@"audio_Green_4"];
    animationView.animationImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"audio_Green_2"],[UIImage imageNamed:@"audio_Green_3"],[UIImage imageNamed:@"audio_Green_5"],[UIImage imageNamed:@"audio_Green_1"], nil];
    animationView.animationDuration = 2.0;
    animationView.tag = 101;
    [playVoiceButton addSubview:animationView];
    
    timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 24, 40, 20)];
    [timeLabel setBackgroundColor:[UIColor clearColor]];
    timeLabel.center = CGPointMake(59.5, 15.5/2);
    timeLabel.text = @"00:00";
    [timeLabel setTextColor:CHAR_GRAY_COLOR];
    timeLabel.textAlignment = NSTextAlignmentCenter;
    [timeLabel setFont:AFFILIATED_CONTENT_FONT];
    [recordVoiceImageView addSubview:timeLabel];
    
    actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [actionButton setBackgroundImage:[UIImage imageNamed:@"recordComplete"] forState:UIControlStateNormal];
    [actionButton setBackgroundImage:[UIImage imageNamed:@"recordComplete_press"] forState:UIControlStateHighlighted];
    [actionButton setFrame:CGRectMake(0, 200, V_S_W, 40)];
    [actionButton setTitle:@"取消" forState:UIControlStateNormal];
    [actionButton setTitleColor:CHAR_GRAY_COLOR forState:UIControlStateNormal];
    [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [actionButton addTarget:self action:@selector(actionButtonClick) forControlEvents:UIControlEventTouchUpInside];
    actionButton.userInteractionEnabled = YES;
    [recordViewBG addSubview:actionButton];
    
    totalSeconds = 0;
    [self beginToRecordAudio];
}

// ml 增加开始
//删除整个语音
- (void)deleteVoiceButtonClick {
    if ([self.delegate respondsToSelector:@selector(deleteVoice)]) {
        [self.delegate deleteVoice];
    }
    
    [self stopPlay];
    
    timeLabel.text = @"00:00";
    totalSeconds = 0;
    // 音频删除时，按钮隐藏
    playVoiceButton.hidden = YES;
    deleteVoiceButton.hidden = YES;
    if (_tempPlayer.isPlaying) {
        [_tempPlayer stop];
    }
    
    //也要将本地这条语音删除
    [self deleteVedio];
}

//删除音频
-(void)deleteVedio
{
    NSString *pathString=[BlazeicePublicMethod getPathByFileName:lastVedio ofType:@"wav"];
    NSString *vedioAmr=[BlazeicePublicMethod getPathByFileName:[lastVedio stringByAppendingString:@"wavToAmr"] ofType:@"amr"];
    [BlazeicePublicMethod deleteFileAtPath:pathString];
    [BlazeicePublicMethod deleteFileAtPath:vedioAmr];
    lastVedio=nil;
}

- (void)playVoiceButtonClick {
    if ([self.delegate respondsToSelector:@selector(playVoice)]) {
        [self.delegate playVoice];
    }
  
    if (_tempPlayer.isPlaying) {
        [_tempPlayer stop];
        
        UIImageView *animationView = (UIImageView*)[playVoiceButton viewWithTag:101];
        [animationView stopAnimating];
        
        if (_playerTimer) {
            [_playerTimer invalidate];
            _playerTimer=nil;
        }
        return;
    }
    
    if (lastVedio!=nil) {

        UIImageView *animationView = (UIImageView*)[playVoiceButton viewWithTag:101];
        [animationView startAnimating];
        
        if (_playerTimer) {
            [_playerTimer invalidate];
            _playerTimer=nil;
        }
        
        NSURL *tempUrl = [NSURL URLWithString:[[BlazeicePublicMethod getPathByFileName:lastVedio ofType:@"wav"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        _tempPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:tempUrl error:nil];
        
        [_tempPlayer play];
        NSTimeInterval vedioTime = _tempPlayer.duration+0.1;
        
        //播放完成时 停止
        _playerTimer=[NSTimer scheduledTimerWithTimeInterval:vedioTime target:self selector:@selector(stopPlay) userInfo:nil repeats:NO];
        [animationView startAnimating];
        UInt32 overried=kAudioSessionOverrideAudioRoute_Speaker;
        if ([[UIDevice currentDevice] proximityState]==YES) {
            overried=kAudioSessionOverrideAudioRoute_None;
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
        }else{
            [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        }
        AudioSessionSetProperty(kAudioSessionProperty_OverrideAudioRoute, sizeof(overried),&overried);
    }
}
//停止播放
-(void)stopPlay
{
    if (_playerTimer) {
        [_playerTimer invalidate];
        _playerTimer=nil;
    }
    
    UIImageView *animationView = (UIImageView *)[playVoiceButton viewWithTag:101];
    [animationView stopAnimating];
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
}
// ml 增加结束

- (void)recordButtonClick {
    if (vedioing) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [recordVoiceImageView stopAnimating];
            [recordButton setImage:[UIImage imageNamed:@"recordAudio_record"] forState:UIControlStateNormal];
            actionButton.userInteractionEnabled = NO;
            [actionButton setTitle:@"正在处理音频" forState:UIControlStateNormal];
            
            // 音频处理格式转换时，按钮隐藏
            playVoiceButton.hidden = YES;
            deleteVoiceButton.hidden = YES;
        });
        [self performSelector:@selector(endToRecordAudio) withObject:nil afterDelay:0.5];
    }
    else {
        [self beginToRecordAudio];
    }
}

- (void)actionButtonClick {
    if (vedioing) {
        [self cancleRecord];
        [self recordComplete];
    }
    else {
        [self recordComplete];
    }
}
// 用户录制中途取消录音处理
- (void)cancleRecord {
    if (lastVedio) {
        
        /*
         *  修改原因：用户录制中途取消录音，删除本地音频文件，文件路径调整
         */
        
//        NSString *lastAmr=[BlazeicePublicMethod getPathByFileName:[lastVedio stringByAppendingString:@"wavToAmr"] ofType:@"amr"];
        NSString *lastAmr=lastVedio;
        [self deleteVedioNamed:lastAmr];
        
//        NSString *lastWav=[BlazeicePublicMethod getPathByFileName:lastVedio ofType:@"wav"];
        NSString *lastWav=lastVedio;
        [self deleteVedioNamed:lastWav];
        lastVedio = nil;
    }
    if (vedioPath) {
//        NSString *vedioAmr=[BlazeicePublicMethod getPathByFileName:[vedioPath stringByAppendingString:@"wavToAmr"] ofType:@"amr"];
        NSString *vedioAmr=vedioPath;
        [self deleteVedioNamed:vedioAmr];
//        NSString *vedioWav=[BlazeicePublicMethod getPathByFileName:vedioPath ofType:@"wav"];
        NSString *vedioWav=vedioPath;
        [self deleteVedioNamed:vedioWav];
        lastVedio = nil;
    }
}

//录音结束，返回最终音频地址
- (void)recordComplete {
    if (self.delegate) {
        [audioRecord endRecord];
        audioRecord.delegate = nil;
        audioRecord = nil;
        [self.delegate recodeComplete:lastVedio];
    }
}

//混合音频
- (void)mixAmr {
    NSString *newName=[NSString stringWithFormat:@"%@_new",vedioPath];
    //两个amr的位置
    NSString *vedioAmr=[BlazeicePublicMethod getPathByFileName:[vedioPath stringByAppendingString:@"wavToAmr"] ofType:@"amr"];
    NSString *lastAmr=[BlazeicePublicMethod getPathByFileName:[lastVedio stringByAppendingString:@"wavToAmr"] ofType:@"amr"];
    
    [audioRecord mixAmr:lastAmr andPath:vedioAmr];
    NSString *newPath=[BlazeicePublicMethod getPathByFileName:[newName stringByAppendingString:@"wavToAmr"] ofType:@"amr"];
    [[NSFileManager defaultManager] copyItemAtPath:lastAmr toPath:newPath error:nil];
    //将拼接的两个录音的音频和转码后amr文件都删除
    [self deleteVedioNamed:lastVedio];
    [self deleteVedioNamed:vedioPath];
    lastVedio = newName;
    waitMixAmr = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        actionButton.userInteractionEnabled = YES;
        [actionButton setTitle:@"完成" forState:UIControlStateNormal];

        // 音频处理完成时，按钮显示
        playVoiceButton.hidden = NO;
        deleteVoiceButton.hidden = NO;
    });
}

//删除音频
- (void)deleteVedioNamed:(NSString *)name {
    NSString *pathString=[BlazeicePublicMethod getPathByFileName:name ofType:@"wav"];
    NSString *vedioAmr=[BlazeicePublicMethod getPathByFileName:[name stringByAppendingString:@"wavToAmr"] ofType:@"amr"];
    [BlazeicePublicMethod deleteFileAtPath:pathString];
    [BlazeicePublicMethod deleteFileAtPath:vedioAmr];
}

- (void)beginToRecordAudio {
    
    // 录音开始时，按钮隐藏
    playVoiceButton.hidden = YES;
    deleteVoiceButton.hidden = YES;
    
    vedioing = YES;
    [recordVoiceImageView startAnimating];
    [recordButton setImage:[UIImage imageNamed:@"recordAudio_recording"] forState:UIControlStateNormal];
    [actionButton setTitle:@"取消" forState:UIControlStateNormal];
    
    vedioPath= [NSString stringWithFormat:@"%@",[BlazeicePublicMethod getCurrentTimeString]];
    if (!audioRecord) {
        audioRecord = [[BlazeiceAudioRecordAndTransCoding alloc]init];
        audioRecord.recorder.delegate=self;
        audioRecord.delegate = self;
    }
    [audioRecord beginRecordByFileName:vedioPath];
    timer=[NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(levelTimerCallBack) userInfo:nil repeats:YES];
}

- (void)endToRecordAudio {
    if (vedioing) {
        vedioing = NO;
        if (timer) {
            [timer invalidate];
        }
        
        //UIView *bg = (UIView *)[self viewWithTag:10086];
        //[bg removeFromSuperview];
        
        if (audioRecord&&[audioRecord.recorder isRecording]) {
            [audioRecord endRecord];
        }
        if (vedioPath.length>0) {
            // 显示语音长度
            int length=[BlazeicePublicMethod getVedioLength:vedioPath];
            if (length<1) {
                //                [self deleteVedioNamed:vedioPath];
                vedioPath=nil;
                UIAlertView *alert=[[UIAlertView alloc] initWithTitle:@"提示" message:@"录音时间过短,请重新录制" delegate:self cancelButtonTitle:@"知道了" otherButtonTitles:nil];
                [alert show];
                return;
            }else{
                if (lastVedio.length == 0) {
                    lastVedio = vedioPath;
                }else{
                    if (![lastVedio isEqualToString:vedioPath]) {
                        int length = [BlazeicePublicMethod getVedioLength:vedioPath];
                        if (length!=0) {
                            waitMixAmr = YES;
                            NSString *lastString = [BlazeicePublicMethod getPathByFileName:lastVedio ofType:@"wav"];
                            NSString *pathString = [BlazeicePublicMethod getPathByFileName:vedioPath ofType:@"wav"];
                            NSString *newName = [NSString stringWithFormat:@"%@_new",vedioPath];
                            [audioRecord mixAudio:pathString andPath:lastString toPath:[BlazeicePublicMethod getPathByFileName:newName ofType:@"wav"]];
                        }
                    }
                }
            }
        }
    }
}

// 通过音量更新录制界面
- (void)levelTimerCallBack {
    if (vedioing) {
        totalSeconds++;
        int seconds = totalSeconds % 60;
        int minutes = (totalSeconds / 60) % 60;
        [timeLabel setText:[NSString stringWithFormat:@"%02d:%02d", minutes, seconds]];
    }
}

- (void)wavToAmrComplete {
    if (waitMixAmr && lastVedio) {
        [self mixAmr];
    }else{
        if ([actionButton.titleLabel.text isEqualToString:@"正在处理音频"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                actionButton.userInteractionEnabled = YES;
                [actionButton setTitle:@"完成" forState:UIControlStateNormal];
                
                // 音频处理完成时，按钮显示
                playVoiceButton.hidden = NO;
                deleteVoiceButton.hidden = NO;
            });
        }
    }
}

@end
