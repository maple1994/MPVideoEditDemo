//
//  ViewController.m
//  MPVideoEditDemo
//
//  Created by Maple on 2020/3/23.
//  Copyright © 2020 Maple. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import <TZImagePickerController.h>
#import <GPUImage.h>
#import <AVFoundation/AVFoundation.h>
#import "MPVideoEdit.h"
#import "MPVideoCompostionManager.h"

@interface ViewController ()
{
    dispatch_semaphore_t _videoExportSemap;
    MPVideoOrientation orientationSplice;
}

@property (nonatomic, strong) NSMutableArray *selectedAsset;
@property (nonatomic, strong) NSMutableArray *phAssets;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) GPUImageView *preview;
@property (nonatomic, strong) GPUImageMovie *source;
@property (nonatomic, strong) AVPlayer *avPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UIButton *btn = [[UIButton alloc] init];
    btn.frame = CGRectMake(30, kScreenHeight - 100, 60, 35);
    [btn setTitle:@"相册" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(showPicker) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *btn1 = [[UIButton alloc] init];
    btn1.frame = CGRectMake(100, kScreenHeight - 100, 60, 35);
    [btn1 setTitle:@"预览" forState:UIControlStateNormal];
    [btn1 setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(getAVAsset) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
    
    self.preview = [[GPUImageView alloc] init];
    self.preview.backgroundColor = [UIColor blackColor];
    CGFloat w = kScreenWidth - 30;
    self.preview.frame = CGRectMake(15, 50, w, w);
    self.preview.fillMode = kGPUImageFillModePreserveAspectRatio;
    [self.view addSubview:self.preview];
}

- (void)showPicker
{
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    imagePickerVc.allowPreview = NO;
    [imagePickerVc setDidFinishPickingVideoHandle:^(UIImage *coverImage, PHAsset *asset) {
        [self.phAssets addObject:asset];
    }];
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

- (void)getAVAsset
{
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    _videoExportSemap = sema;
    for (PHAsset *phasset in self.phAssets) {
        [MPVideoCompostionManager getVideo:phasset resultHandler:^(AVAsset * _Nullable asset) {
            if (![asset isKindOfClass:[AVAsset class]]) {
                dispatch_semaphore_signal(sema);
                return;
            }
            [self.selectedAsset addObject:asset];
            dispatch_semaphore_signal(sema);
        }];
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    MPVideoCompostionManager *mgr = [[MPVideoCompostionManager alloc] init];
    mgr.selectedAsset = self.selectedAsset;
    self.playerItem = [mgr getPreviewPlayerItem];
    
    self.source = [[GPUImageMovie alloc] initWithPlayerItem:self.playerItem];
    self.source.runBenchmark = YES;
    self.source.playAtActualSpeed = YES;
    GPUImageFilter *filter = [[GPUImageFilter alloc] init];
    [self.source addTarget:filter];
    [filter addTarget:self.preview];
    [self.source startProcessing];
    self.avPlayer = [[AVPlayer alloc] initWithPlayerItem:self.playerItem];
    [self.avPlayer play];

    // 播放结束时，重播
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [self.avPlayer seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
               [self.avPlayer play];
           }];
    }];
}

#pragma mark - Getter
- (NSMutableArray *)selectedAsset
{
    if (!_selectedAsset) {
        _selectedAsset = [NSMutableArray array];
    }
    return _selectedAsset;
}

- (NSMutableArray *)phAssets
{
    if (!_phAssets) {
        _phAssets = [NSMutableArray array];
    }
    return _phAssets;
}

@end
