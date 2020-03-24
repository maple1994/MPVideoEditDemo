//
//  MPVideoEdit.h
//  MPVideoEditDemo
//
//  Created by Maple on 2020/3/24.
//  Copyright © 2020 Maple. All rights reserved.
//

#ifndef MPVideoEdit_h
#define MPVideoEdit_h
/// iPhoneX  iPhoneXS  iPhoneXS Max  iPhoneXR 机型判断
#define iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? ((NSInteger)(([[UIScreen mainScreen] currentMode].size.height/[[UIScreen mainScreen] currentMode].size.width)*100) == 216) : NO)

#define kScreenWidth                 [[UIScreen mainScreen] bounds].size.width
#define kScreenHeight                [[UIScreen mainScreen] bounds].size.height

typedef NS_ENUM(NSUInteger, MPVideoOrientation) {
    MPVideoOrientationUnknown,
    MPVideoOrientationPortrait           ,
    MPVideoOrientationPortraitUpsideDown ,
    MPVideoOrientationLandscapeLeft      ,
    MPVideoOrientationLandscapeRight
};

#endif /* MPVideoEdit_h */
