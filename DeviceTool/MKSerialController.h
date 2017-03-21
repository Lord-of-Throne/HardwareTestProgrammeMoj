//
//  MKSerialController.h
//  DeviceTool
//
//  Created by Monky on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface MKSerialController : UIViewController<CBCentralManagerDelegate,CBPeripheralDelegate>
@property (nonatomic,strong)NSString *codeNum;
@end

bool serialWritten = false;

bool confirmState = false;
bool serialResponse = false;

NSData *responsedFirstSegment;
bool firstSegmentReceived = false;
NSData *responsedSecondSegment;
