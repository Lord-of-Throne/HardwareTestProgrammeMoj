//
//  MojoyBluetoothMgr.m
//  DeviceTool
//
//  Created by xxl on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "MojoyBluetoothMgr.h"

@interface MojoyBluetoothMgr()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property(nonatomic,strong)CBCentralManager* centralManager;
@property(nonatomic,strong)NSMutableArray* dicoveredPeripherals;

@end


@implementation MojoyBluetoothMgr
#pragma mark - Init method

+ (instancetype)shareBlueTooth{
    static dispatch_once_t once;
    static MojoyBluetoothMgr* blueTooth;
    dispatch_once(&once, ^{
        blueTooth = [[self alloc] init];
    });
    return blueTooth;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], CBCentralManagerOptionShowPowerAlertKey, nil];
        
        self.dicoveredPeripherals = [NSMutableArray new];
        
        CBCentralManager *central = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
        self.centralManager = central;

        
    }
    return self;
}

@end
