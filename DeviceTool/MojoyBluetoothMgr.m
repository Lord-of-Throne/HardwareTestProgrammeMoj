//
//  MojoyBluetoothMgr.m
//  DeviceTool
//
//  Created by xxl on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "MojoyBluetoothMgr.h"
#define DefaultDeviceName @"mjm"

@interface MojoyBluetoothMgr()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property(nonatomic,strong)CBCentralManager* centralMgr;
@property (nonatomic, strong) CBPeripheral *discoveredPeripheral;
@property (nonatomic, strong) CBCharacteristic *writeCharacteristic;

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
        
        CBCentralManager *central = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
        self.centralMgr = central;

        
    }
    return self;
}

//检查App的设备BLE是否可用 （ensure that Bluetooth low energy is supported and available to use on the central device）
- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBCentralManagerStatePoweredOn:
            //discover what peripheral devices are available for your app to connect to
            //第一个参数为CBUUID的数组，需要搜索特点服务的蓝牙设备，只要每搜索到一个符合条件的蓝牙设备都会调用didDiscoverPeripheral代理方法
            [self.centralMgr scanForPeripheralsWithServices:nil options:nil];
            break;
        default:
            NSLog(@"Central Manager did change state");
            break;
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    //找到需要的蓝牙设备，停止搜素，保存数据
    NSString *localName = [advertisementData objectForKey:CBAdvertisementDataLocalNameKey];
    NSLog(@"device name:%@",localName);
    if ([localName rangeOfString:self.deviceName options:NSCaseInsensitiveSearch].length > 0) {//[localName rangeOfString:@"BT05" options:NSCaseInsensitiveSearch].length > 0 ||
        
        _discoveredPeripheral = peripheral;
        [_centralMgr connectPeripheral:peripheral options:nil];
        [_centralMgr stopScan];
    }
}

//连接成功
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    //Before you begin interacting with the peripheral, you should set the peripheral’s delegate to ensure that it receives the appropriate callbacks（设置代理）
    [_discoveredPeripheral setDelegate:self];
    //discover all of the services that a peripheral offers,搜索服务,回调didDiscoverServices
    [_discoveredPeripheral discoverServices:nil];
    NSString *str = [NSString stringWithFormat:@"连接%@成功!",peripheral.name];
}

//连接失败，就会得到回调：
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{
    //此时连接发生错误
    NSLog(@"connected periphheral failed");
}

//获取服务后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (error)
    {
        NSLog(@"didDiscoverServices : %@", [error localizedDescription]);
        return;
    }
    
    for (CBService *s in peripheral.services)
    {
        NSLog(@"Service found with UUID : %@", s.UUID);
        //Discovering all of the characteristics of a service,回调didDiscoverCharacteristicsForService
        [s.peripheral discoverCharacteristics:nil forService:s];
    }
}

//获取特征后的回调
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    if (error)
    {
        NSLog(@"didDiscoverCharacteristicsForService error : %@", [error localizedDescription]);
        return;
    }
    
    for (CBCharacteristic *c in service.characteristics)
    {
        NSLog(@"c.properties:%lu",(unsigned long)c.properties) ;
        //Subscribing to a Characteristic’s Value 订阅
        [peripheral setNotifyValue:YES forCharacteristic:c];
        // read the characteristic’s value，回调didUpdateValueForCharacteristic
        [peripheral readValueForCharacteristic:c];
        _writeCharacteristic = c;
    }
    
}

//订阅的特征值有新的数据时回调
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@",
              [error localizedDescription]);
    }
    
    [peripheral readValueForCharacteristic:characteristic];
    
}

// 获取到特征的值时回调
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData* midiData = [characteristic value];
    NSLog(@"Midi data:%@",midiData);
    NSUInteger len = [midiData length];
    NSUInteger loopCount = len / 5;
    const unsigned char *nsdata_bytes = (unsigned char*)[midiData bytes];
    for (int i = 0; i < loopCount; i++) {
        unsigned int noteStatus = nsdata_bytes[i*5 + 2];//开始结束标志
        unsigned int noteValue = nsdata_bytes[i*5 + 3];//音符
        //        unsigned int noteVelocity = nsdata_bytes[4];//力度
        if(noteStatus == 128){
            //note off
            NSLog(@"Note off");
            //            BlueTool::getInstance()->receiveMidiEvent(false, noteValue, 0);
        }else if(noteStatus == 144){
            //note on
            NSLog(@"Note on");
            //            BlueTool::getInstance()->receiveMidiEvent(true, noteValue, 0);
        }
        NSLog(@"Note status:%u,note value:%u",noteStatus,noteValue);
    }
    
    NSString *reciveText = [NSString stringWithFormat:@"recive!!!!%X %X %X %X %X",nsdata_bytes[0],nsdata_bytes[1],nsdata_bytes[2],nsdata_bytes[3],nsdata_bytes[4]];
    NSLog(@"%@",reciveText);
}

#pragma mark 写数据
- (void)writeChar:(NSData *)data
{
    //回调didWriteValueForCharacteristic
    [_discoveredPeripheral writeValue:data forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
}

#pragma mark 写数据后回调
- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
        NSLog(@"Error writing characteristic value: %@",
              [error localizedDescription]);
        NSString *str = [NSString stringWithFormat:@"写入失败!"];
        return;
    }
    
}
@end
