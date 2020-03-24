//
//  MPVideoCompostionManager.h
//  MPVideoEditDemo
//
//  Created by Maple on 2020/3/24.
//  Copyright © 2020 Maple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import "MPVideoEdit.h"
NS_ASSUME_NONNULL_BEGIN

/// 用于视频合成等操作的管理类
@interface MPVideoCompostionManager : NSObject

@property (nonatomic, strong) NSArray *selectedAsset;

/// 从selectedAsset中合成可预览播放的playerItem
- (AVPlayerItem *)getPreviewPlayerItem;

+ (void)getVideo: (PHAsset *)phAsset resultHandler:(void (^)(AVAsset *__nullable asset))resultHandler;

@end

NS_ASSUME_NONNULL_END
