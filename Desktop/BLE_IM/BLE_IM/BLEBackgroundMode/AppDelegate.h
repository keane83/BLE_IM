//
//  AppDelegate.h
//  BLEBackgroundMode
//
//  Created by Mario Zhang on 13-12-30.
//  Copyright (c) 2013年 Mario Zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic,strong)AVAudioPlayer* player;
@end
