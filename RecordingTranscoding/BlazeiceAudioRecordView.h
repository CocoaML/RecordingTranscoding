//
//  BlazeiceAudioRecordView.h
//  RecordingTranscoding
//
//  Created by 白冰 on 15/12/1.
//  Copyright (c) 2015年 lezhixing. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlazeiceAudioRecordAndTransCoding.h"

@protocol audioRecordDelegate <NSObject>
-(void)recodeComplete:(NSString *)vedioPathString;

/*
 增加原因：在 BlazeiceAudioRecordView 视图内控制语音的录制、试听和删除。
 */

@optional
// ml 增加开始
- (void)deleteVoice;
- (void)playVoice;
// ml 增加结束

@end

@interface BlazeiceAudioRecordView : UIView<BlazeiceAudioRecordAndTransCodingDelegate,AVAudioPlayerDelegate,AVAudioRecorderDelegate>{}

// ml 修改开始

//@property (nonatomic,strong)id<audioRecordDelegate>delegate;

/* 
    修改原因：delegate 一般用weak ,不知此处为何用strong 。。。希望大神指点
*/
@property (nonatomic, weak)  id<audioRecordDelegate>delegate;
// ml 修改结束

-(void)loadView;

@end
