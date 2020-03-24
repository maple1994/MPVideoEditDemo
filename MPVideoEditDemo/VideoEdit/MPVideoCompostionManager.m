//
//  MPVideoCompostionManager.m
//  MPVideoEditDemo
//
//  Created by Maple on 2020/3/24.
//  Copyright © 2020 Maple. All rights reserved.
//

#import "MPVideoCompostionManager.h"
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

CGAffineTransform makeTransform1(CGFloat yScale, CGFloat xScale, CGFloat theta, CGFloat tx, CGFloat ty) {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    transform.a = xScale * cos(theta);
    transform.b = yScale * sin(theta);
    transform.c = xScale * -sin(theta);
    transform.d = yScale * cos(theta);
    transform.tx = tx;
    transform.ty = ty;
    
    return transform;
}

@interface MPVideoCompostionManager ()
{
    MPVideoOrientation orientationSplice;
}

@end

@implementation MPVideoCompostionManager

#pragma mark - Public Method
- (AVPlayerItem *)getPreviewPlayerItem
{
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack *videoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime end = kCMTimeZero;
       
    // 用于保存videoAssetTrack的数组
    NSMutableArray *assetTrackArr = [NSMutableArray array];
    // 用于保存对应的track的timeRange的数组
    NSMutableArray *timeRangeArr = [NSMutableArray array];
    
    for (AVURLAsset *asset in self.selectedAsset) {
        AVAssetTrack *videoAssetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        AVAssetTrack *audioAssetTrack = [asset tracksWithMediaType:AVMediaTypeAudio].firstObject;
           // 这个range是videoAsset的整个区间
        CMTimeRange range = CMTimeRangeFromTimeToTime(kCMTimeZero, asset.duration);
        NSError *error = nil;
        [videoTrack insertTimeRange:CMTimeRangeFromTimeToTime(kCMTimeZero, asset.duration) ofTrack:videoAssetTrack atTime:end error:&error];
        if (audioAssetTrack) {
            [audioTrack insertTimeRange:range ofTrack:audioAssetTrack atTime:end error:&error];
        }
        if (error) {
            NSLog(@"%@", error);
        }
        // 保存track和range
        [assetTrackArr addObject:videoTrack];
        // 这个range记录的是compostion中的区间
        CMTimeRange rangeInCompostion =  CMTimeRangeFromTimeToTime(end, CMTimeAdd(end, asset.duration));
        [timeRangeArr addObject:[NSValue valueWithCMTimeRange:rangeInCompostion]];
        // 计算下一段轨道的插入时间
        end = CMTimeAdd(end, asset.duration);
    }
    AVAsset *avAsset = self.selectedAsset.firstObject;
    CGSize naturalSize1 = [self tranformSizeWithAsset:avAsset];
       
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    NSMutableArray<id <AVVideoCompositionInstruction>> *instructionArr = [NSMutableArray array];
       
    for (int i = 0; i < assetTrackArr.count; i++) {
        CMTimeRange range = [timeRangeArr[i] CMTimeRangeValue];
           
        AVMutableVideoCompositionInstruction *instuction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        instuction.timeRange = range;
           
        CGAffineTransform transform = [self videoCompositionLayerInsturctionTransformTrackSize:naturalSize1 outputSize:naturalSize1];
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        [layerInstruction setTransform:transform atTime:kCMTimeZero];
        instuction.layerInstructions = @[layerInstruction];
        [instructionArr addObject:instuction];
    }
    videoComposition.instructions = instructionArr;
    videoComposition.renderSize = naturalSize1;
    videoComposition.frameDuration  = CMTimeMake(20, 600);
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
    playerItem.videoComposition = videoComposition;
    return playerItem;
}

+ (void)getVideo: (PHAsset *)phAsset resultHandler:(void (^)(AVAsset *__nullable asset))resultHandler
{
    PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
    option.networkAccessAllowed = NO;
     [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:option resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
         resultHandler(asset);
       }];
}

#pragma mark - Private Method
- (void)createComposition
{
    
}

- (AVPlayerItem *)startPreView: (AVComposition *)composition  videoComposition: (AVVideoComposition *)videoComposition {
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:composition];
    playerItem.videoComposition = videoComposition;
    return playerItem;
}

- (CGSize)tranformSizeWithAsset:(AVAsset *)asset
{
    AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGAffineTransform t =  assetTrack.preferredTransform;
    if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
        //degress = 90
        orientationSplice = MPVideoOrientationPortrait;
    }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
        //degress = 270
        orientationSplice =  MPVideoOrientationPortraitUpsideDown;
    }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
        //degress = 180
        orientationSplice =  MPVideoOrientationLandscapeLeft;
    }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
        //degress = 0
        orientationSplice =  MPVideoOrientationLandscapeRight;
    }
    CGSize size = CGSizeZero;
    //获取视频轨道分辨率
    if (orientationSplice ==  MPVideoOrientationPortrait || orientationSplice ==  MPVideoOrientationPortraitUpsideDown) {
        size = CGSizeMake(assetTrack.naturalSize.height, assetTrack.naturalSize.width);
    } else {
        size = assetTrack.naturalSize;
    }
    return size;
}

// 这是根据轨道尺寸和输出尺寸，以及视频方向等，计算出轨道视频应该怎么适配到输出视频上
- (CGAffineTransform)videoCompositionLayerInsturctionTransformTrackSize:(CGSize)trackSize outputSize:(CGSize)outputSize {
    CGAffineTransform layerTransfrom;
    CGFloat rotate = 0.0;
    CGFloat scale = 1.0;
    trackSize = CGSizeMake(trackSize.width, trackSize.height);
    
    if (trackSize.width != outputSize.width && trackSize.height != outputSize.height) {
        scale = outputSize.width / trackSize.width;
        if (trackSize.height * scale < outputSize.height) {
            scale = outputSize.height / trackSize.height;
        }
    } else if (trackSize.width == outputSize.width || trackSize.height == outputSize.height) {
        if (trackSize.width == outputSize.width) {
            if (trackSize.height < outputSize.height) {
                scale = outputSize.height / trackSize.height;
            }
        }
        if (trackSize.height == outputSize.height) {
            if (trackSize.width < outputSize.width) {
                scale = outputSize.width / trackSize.width;
            }
        }
    }
    
    if (orientationSplice ==  MPVideoOrientationPortrait) { //竖屏
        rotate = M_PI_2;
        layerTransfrom = makeTransform1(scale, scale, rotate, (outputSize.width - trackSize.width * scale) / 2 + trackSize.width * scale , (outputSize.height - trackSize.height * scale) / 2);
    } else if (orientationSplice ==  MPVideoOrientationLandscapeRight){ //右向横屏
        rotate = M_PI;
        layerTransfrom = makeTransform1(scale, scale, rotate, (outputSize.width - trackSize.width * scale) / 2 + trackSize.width * scale , (outputSize.height - trackSize.height * scale) / 2 + trackSize.height * scale);
    } else if (orientationSplice ==  MPVideoOrientationPortraitUpsideDown) { //倒置竖屏
        rotate = -M_PI_2;
        layerTransfrom = makeTransform1(scale, scale, rotate, (outputSize.width - trackSize.width * scale) / 2, (outputSize.height - trackSize.height * scale) / 2 + trackSize.height * scale);
    } else { //left横屏
        rotate = 0.0;
        layerTransfrom = makeTransform1(scale, scale, 0, (outputSize.width - trackSize.width * scale) / 2, (outputSize.height - trackSize.height * scale) / 2);
        
    }
    
    return layerTransfrom;
}

@end
