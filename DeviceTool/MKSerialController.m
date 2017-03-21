//
//  MKSerialController.m
//  DeviceTool
//
//  Created by Monky on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "MKSerialController.h"
#import "MojoyBluetoothMgr.h"

@interface MKSerialController ()

@end

@implementation MKSerialController

- (void)viewDidLoad {
    [super viewDidLoad];
        // Do any additional setup after loading the view from its nib.
     self.view.backgroundColor = [UIColor colorWithWhite:0.858 alpha:1.000];
    NSLog(@"codeNum:%@",self.codeNum);
    // 连接默认蓝牙, 获得条形码信息
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    blue.deviceName = @"bt05";

     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectSuccess) name:@"blueConnectSuccess" object:nil];
    //接收到数据的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getReciveData:) name:@"blueReciveSuccess" object:nil];
}

- (void)getReciveData:(NSNotification *)notification{
    NSDictionary * infoDic = [notification object];
    NSLog(@"getRecive:%@",infoDic[@"reciveData"]);
    NSData *midiData = infoDic[@"reciveData"];
    
    // 数据解析，只解析魔棒状态反馈和命令反馈，midi信息被丢弃
    NSUInteger len = [midiData length];
    NSUInteger loopCount = len / 5;
    NSLog(@"Translating....");
    const unsigned char *nsdata_bytes = (unsigned char*)[midiData bytes];
    
    unsigned int firstNum   = 0;
    unsigned int secondNum = 0;
    unsigned int thirdNum  = 0;
    unsigned int forthNum   = 0;
    unsigned int fifthNum    = 0;
    // 魔棒反馈数据，正常情况下每次5个字节
    for (int i = 0; i < loopCount; i++) {
        // 数据分解
        firstNum   = nsdata_bytes[i*5 + 0];
        secondNum = nsdata_bytes[i*5 + 1];
        thirdNum  = nsdata_bytes[i*5 + 2];
        forthNum   = nsdata_bytes[i*5 + 3];
        fifthNum    = nsdata_bytes[i*5 + 4];
        // 反馈解析
        // 0x20魔棒状态反馈；0x11魔棒序列回复
        if(firstNum == 0x20){
            if([self confirmHandshake:midiData]){
            confirmState = true;
            }
        }else if(firstNum == 0x11 && firstSegmentReceived == false){
            responsedFirstSegment = midiData;
            firstSegmentReceived = true;
        }else if(firstNum == 0x11 && firstSegmentReceived == true){
            responsedSecondSegment = midiData;
            firstSegmentReceived = false;
            serialResponse = true;
        }
        // Log输出
        NSString *reciveText = [NSString stringWithFormat:@"recive!!!!%X %X %X %X %X",nsdata_bytes[0],nsdata_bytes[1],nsdata_bytes[2],nsdata_bytes[3],nsdata_bytes[4]];
        NSLog(@"%@",reciveText);
    }
    
}

- (void)connectSuccess{
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    
    if(serialWritten == false){
        // 确认魔棒状态
        NSData *enterQuery = [self toHexEnterQueryStatusCommandline];
        [blue writeChar:enterQuery];
        while(1){
            if(confirmState == true){
                break;
            }
        }
        confirmState = false;
        
        // 写入新的序列号
        NSData *newSerial_first = [self newBluetoothSerialNumFirstSegment];
        [blue writeChar:newSerial_first];
        NSData *newSerial_sencond = [self newBluetoothSerialNumFirstSegment];
        [blue writeChar:newSerial_sencond];
        while(1){
            if(confirmState == true){
                break;
            }
        }
        confirmState = false;
        
        // 写入序列号后状态管理
        serialWritten = true;
        
        // 重新连接新的codeNum蓝牙
        [blue stopScan];
        blue.deviceName = @"mjm";
        [blue startScan];
    }

    // 再次确认魔棒状态
    NSData *enterQuery_second = [self toHexEnterQueryStatusCommandline];
    [blue writeChar:enterQuery_second];
    while(1){
        if(confirmState == true){
            break;
        }
    }
    confirmState = false;
    
    // 比对确认新的序列号是否成功
    Boolean confirmResult = [self reconfirmSerialNum];
    // 结果反馈
    if(confirmResult){
        // 序列号比对成功
        NSString *str = @"序列号写入成功\n %@";
        
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:str preferredStyle:UIAlertControllerStyleAlert];
        [alertVc addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"点击取消");
        }]];
        
        [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"点击确认");
            
        }]];
        [self presentViewController:alertVc animated:YES completion:nil];
    }else{
        // 序列号比对失败
        NSString *str = @"序列号写入失败\n %@";
        
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:str preferredStyle:UIAlertControllerStyleAlert];
        [alertVc addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"点击取消");
        }]];
        
        [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSLog(@"点击确认");
            
        }]];
        [self presentViewController:alertVc animated:YES completion:nil];
    }
    serialWritten = false;
}

- (bool)confirmHandshake:(NSData* ) midiData{
    NSLog(@"---------------------------------------------");
    NSLog(@"Bluetooth raw data arreived:%@",midiData);
    NSUInteger len = [midiData length];
    NSUInteger loopCount = len / 5;
    NSLog(@"Translating....");
    const unsigned char *nsdata_bytes = (unsigned char*)[midiData bytes];
    
    unsigned int firstNum   = 0;//标志头字节
    unsigned int secondNum = 0;//按下抬起标志
    unsigned int thirdNum  = 0;//按键位置
    unsigned int forthNum   = 0;//红外传感器读取到的高位值
    unsigned int fifthNum    = 0;//红外传感器读取到的低位值
    for (int i = 0; i < loopCount; i++) {
        // Debug模式下，Midi报文的数据意义
        firstNum   = nsdata_bytes[i*5 + 0];//标志头字节
        secondNum = nsdata_bytes[i*5 + 1];//按下抬起标志
        thirdNum  = nsdata_bytes[i*5 + 2];//按键位置
        forthNum   = nsdata_bytes[i*5 + 3];//红外传感器读取到的高位值
        fifthNum    = nsdata_bytes[i*5 + 4];//红外传感器读取到的低位值
    }
    if(firstNum != 0x20)
        return false;
    if(secondNum != 0x00)
        return false;
    if(thirdNum != 0x00)
        return false;
    if(forthNum != 0x00)
        return false;
    if(fifthNum != 0xff)
        return false;
    
    return true;
    
}

- (NSData *)newBluetoothSerialNumFirstSegment{
    // 生成新序列号
    unsigned char dataFirstSegment[5]= {"11",};
    NSString *firstSegment = [_codeNum substringWithRange:NSMakeRange(0, 4)]; ;
    dataFirstSegment[1] = (char)firstSegment;
    NSData *dataB =[NSData dataWithBytes:dataFirstSegment length:4];
    return dataB;
}

- (NSData *)newBluetoothSerialNumSecondSegment{
    // 生成新序列号
    unsigned char dataFirstSegment[5]= {"11",};
    NSString *firstSegment = [_codeNum substringWithRange:NSMakeRange(4, 4)]; ;
    dataFirstSegment[1] = (char)firstSegment;
    NSData *dataB =[NSData dataWithBytes:dataFirstSegment length:4];
    return dataB;
}

- (bool)reconfirmSerialNum{
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    // 查询序列号
    NSData *dataA = [self toHexQuerySerialNumCommandline];
    [blue writeChar:dataA];
    NSData *data_currentA;
    NSData *data_currentB;
    while (1) {
        if(serialResponse == true){
            data_currentA = responsedFirstSegment;
            data_currentB = responsedSecondSegment;
        }
        break;
    }
    serialResponse = false;
    responsedFirstSegment = nil;
    responsedSecondSegment = nil;
    
    // 生成写入前序列号
    NSData *data_previousA = [self newBluetoothSerialNumFirstSegment];
    NSData *data_previousB = [self newBluetoothSerialNumSecondSegment];

    // 比对序列号
    if(data_previousA != data_currentA){
        return false;
    }
    if(data_previousB != data_currentB){
        return false;
    }
    
    return true;
}
#pragma mark 生成16进制命令-查询序列号
- (NSData *)toHexQuerySerialNumCommandline{
    unsigned char data[5]= {};
    
    int firstNum = (int)strtol("10", NULL, 16);
    int secondNum = (int)strtol("00", NULL, 16);
    int thirdNum = (int)strtol("00", NULL, 16);
    int forthNum = (int)strtol("00", NULL, 16);
    int fifthNum = (int)strtol("02", NULL, 16);
    
    printf("%X-%X-%X-%X-%X",firstNum,secondNum,thirdNum,forthNum,fifthNum);
    data[0] = (char)firstNum;
    data[1] = (char)secondNum;
    data[2] = (char)thirdNum;
    data[3] = (char)forthNum;
    data[4] = (char)fifthNum;
    
    NSData *dataB =[NSData dataWithBytes:data length:5];
    return dataB;
}

#pragma mark 生成16进制命令-进入魔棒查询状态
- (NSData *)toHexEnterQueryStatusCommandline{
    unsigned char data[5]= {};
    
    int firstNum = (int)strtol("10", NULL, 16);
    int secondNum = (int)strtol("00", NULL, 16);
    int thirdNum = (int)strtol("00", NULL, 16);
    int forthNum = (int)strtol("00", NULL, 16);
    int fifthNum = (int)strtol("01", NULL, 16);
    
    printf("%X-%X-%X-%X-%X",firstNum,secondNum,thirdNum,forthNum,fifthNum);
    data[0] = (char)firstNum;
    data[1] = (char)secondNum;
    data[2] = (char)thirdNum;
    data[3] = (char)forthNum;
    data[4] = (char)fifthNum;
    
    NSData *dataB =[NSData dataWithBytes:data length:5];
    return dataB;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc{
     [[NSNotificationCenter defaultCenter] removeObserver:self name:@"blueConnectSuccess" object:nil];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
