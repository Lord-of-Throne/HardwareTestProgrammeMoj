//
//  MojoyBluetoothMgr.h
//  DeviceTool
//
//  Created by xxl on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MojoyBluetoothMgr : NSObject

@property (nonatomic,strong)NSString *deviceName;

+ (instancetype)shareBlueTooth;
- (void)writeChar:(NSData *)data;
@end
