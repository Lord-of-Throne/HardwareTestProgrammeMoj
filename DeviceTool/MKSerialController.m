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
@property (weak, nonatomic) IBOutlet UITextField *bluetoothNameInput;

@property (weak, nonatomic) IBOutlet UILabel *connectOrign;
@property (weak, nonatomic) IBOutlet UILabel *originalDeivceIsOk;
@property (weak, nonatomic) IBOutlet UILabel *uiNewNameSent;
@property (weak, nonatomic) IBOutlet UILabel *uiNewNameSentSuccessfully;
@property (weak, nonatomic) IBOutlet UILabel *reconnectNewNamedDevice;
@property (weak, nonatomic) IBOutlet UILabel *confirmNewNamedDeviceOk;
@property (weak, nonatomic) IBOutlet UILabel *nameComparedSuccessfully;

@end

@implementation MKSerialController

// 蓝牙名
// todo: 取消第一个注释
//NSString *sourceBluetoothName = @"BT05";
//NSString *targetBluetoothName = @"mjm";
NSString *sourceBluetoothName = @"mjm";
NSString *targetBluetoothName = @"mjm-";

bool isConnectedBT = false;
bool isConnectedMjm = false;

bool serialWritten = false;

bool confirmState = false;
bool serialResponse = false;

NSData *responsedFirstSegment;
bool firstSegmentReceived = false;
NSData *responsedSecondSegment;

NSNumber *intNumber;

bool reconfirmResult = false;
- (IBAction)connectButton:(id)sender {
    if([_bluetoothNameInput.text  isEqual: @""]){
        sourceBluetoothName = _bluetoothNameInput.placeholder;
    }else{
        sourceBluetoothName = _bluetoothNameInput.text;
    }
    // 重新连接指定蓝牙
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    isConnectedBT = false;
    isConnectedMjm = false;
    blue.deviceName = sourceBluetoothName;
    
    // 开启线程进行逻辑处理，主线程负责ui、状态位及蓝牙数据的接收
    NSThread* myThread = [[NSThread alloc] initWithTarget:self selector:@selector(rewriteSerialNum) object:nil];
    [myThread start];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
     self.view.backgroundColor = [UIColor colorWithWhite:0.858 alpha:1.000];
    // LOG条形码信息
    NSLog(@"codeNum:%@",self.codeNum);
    targetBluetoothName = [NSString stringWithFormat:@"%@%@",targetBluetoothName,[_codeNum substringWithRange:NSMakeRange(0, 8)]];
    
    _bluetoothNameInput.placeholder = @"BT05";

    // 接收到连接成功的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectSuccess) name:@"blueConnectSuccess" object:nil];
    // 接收到数据的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getReciveData:) name:@"blueReciveSuccess" object:nil];
    
    // 流程ui
    _connectOrign.textColor              = [UIColor redColor];
    _originalDeivceIsOk.textColor        = [UIColor redColor];
    _uiNewNameSent.textColor             = [UIColor redColor];
    _uiNewNameSentSuccessfully.textColor = [UIColor redColor];
    _reconnectNewNamedDevice.textColor   = [UIColor redColor];
    _confirmNewNamedDeviceOk.textColor   = [UIColor redColor];
    _nameComparedSuccessfully.textColor  = [UIColor redColor];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

    // 通知：接收到蓝牙数据的回调
- (void)getReciveData:(NSNotification *)notification{
    NSDictionary *infoDic = [notification object];
    NSLog(@"App layer received:%@",infoDic[@"reciveData"]);
    NSData *midiData = infoDic[@"reciveData"];
    
    // 数据解析，只解析魔棒状态反馈和命令反馈，其他midi信息被丢弃
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
            unsigned char data[5]= {};
            printf("%X-%X-%X-%X-%X\n",firstNum,secondNum,thirdNum,forthNum,fifthNum);
            
            data[0] = (char)firstNum;
            data[1] = (char)secondNum;
            data[2] = (char)thirdNum;
            data[3] = (char)forthNum;
            data[4] = (char)fifthNum;
            NSData *dataB =[NSData dataWithBytes:data length:5];
            
            responsedFirstSegment = dataB;
            firstSegmentReceived = true;
        }else if(firstNum == 0x11 && firstSegmentReceived == true){
            unsigned char data[5]= {};
            printf("%X-%X-%X-%X-%X\n",firstNum,secondNum,thirdNum,forthNum,fifthNum);
            
            data[0] = (char)firstNum;
            data[1] = (char)secondNum;
            data[2] = (char)thirdNum;
            data[3] = (char)forthNum;
            data[4] = (char)fifthNum;
            NSData *dataB =[NSData dataWithBytes:data length:5];
            responsedSecondSegment = dataB;
            
            firstSegmentReceived = false;
            serialResponse = true;
        }
        
        // Log输出
        NSString *reciveText = [NSString stringWithFormat:@"App layer recevie:%X %X %X %X %X",firstNum,secondNum,thirdNum,forthNum,fifthNum];
        NSLog(@"%@",reciveText);
    }
}
    // 通知：连接成功的回调
- (void)connectSuccess{
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    if([blue.deviceName  isEqual: sourceBluetoothName] && ![blue.deviceName  isEqual: targetBluetoothName]){
        isConnectedBT = true;
        isConnectedMjm = false;
    }else if([blue.deviceName  isEqual: targetBluetoothName] && ![blue.deviceName  isEqual: sourceBluetoothName]){
        isConnectedMjm = true;
        isConnectedBT = false;
    }else if([blue.deviceName  isEqual: targetBluetoothName] && [blue.deviceName  isEqual: sourceBluetoothName]){
        isConnectedBT = true;
        isConnectedMjm = true;
    }else{
        isConnectedBT = false;
        isConnectedMjm = false;
    }
}

- (void)updateUILabel:(NSNumber*) processNum{
    int a = [processNum intValue];
    switch (a) {
        case 1:
            _connectOrign.textColor              = [UIColor blueColor];
            break;
        case 2:
            _originalDeivceIsOk.textColor        = [UIColor blueColor];
            break;
        case 3:
            _uiNewNameSent.textColor             = [UIColor blueColor];
            break;
        case 4:
            _uiNewNameSentSuccessfully.textColor = [UIColor blueColor];
            break;
        case 5:
            _reconnectNewNamedDevice.textColor   = [UIColor blueColor];
            break;
        case 6:
            _confirmNewNamedDeviceOk.textColor   = [UIColor blueColor];
            break;
        case 7:
            _nameComparedSuccessfully.textColor  = [UIColor blueColor];
            break;
        default:
            break;
    }
}

    // 重写序列号的函数，在线程中运行
- (bool)rewriteSerialNum{
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    
    while(1){
        if(isConnectedBT == true)
            break;
    }
    intNumber = [NSNumber numberWithInt:1];
    [self performSelectorOnMainThread:@selector(updateUILabel:) withObject:intNumber waitUntilDone:YES];
    
    if(isConnectedBT == false)
        return false;
    
    if(isConnectedBT == true && serialWritten == false && isConnectedMjm == false){
        // 确认魔棒状
        NSData *enterQuery = [self toHexEnterQueryStatusCommandline];
        [blue writeChar:enterQuery];
        while(1){
            if(confirmState == true){
                break;
            }
        }
        intNumber = [NSNumber numberWithInt:2];
        [self performSelectorOnMainThread:@selector(updateUILabel:) withObject:intNumber waitUntilDone:YES];
        confirmState = false;
        
        // 写入新的序列号
        NSData *newSerial_first = [self newBluetoothSerialNumFirstSegment];
        [blue writeChar:newSerial_first];
        NSData *newSerial_sencond = [self newBluetoothSerialNumSecondSegment];
        [blue writeChar:newSerial_sencond];
        intNumber = [NSNumber numberWithInt:3];
        [self performSelectorOnMainThread:@selector(updateUILabel:) withObject:intNumber waitUntilDone:YES];
        
        while(1){
            if(confirmState == true){
                break;
            }
        }
        intNumber = [NSNumber numberWithInt:4];
        [self performSelectorOnMainThread:@selector(updateUILabel:) withObject:intNumber waitUntilDone:YES];
        confirmState = false;
        
        // 写入序列号后状态管理
        serialWritten = true;
        
        // 重新连接新的codeNum蓝牙
        isConnectedBT = false;
        isConnectedMjm = false;
        [blue stopScan];
        blue.deviceName = targetBluetoothName;
        [blue startScan];
        // todo: 把isConnectedBT改为false
        while(1){
            if(isConnectedBT == false && isConnectedMjm == true){
                break;
            }
        }
        intNumber = [NSNumber numberWithInt:5];
        [self performSelectorOnMainThread:@selector(updateUILabel:) withObject:intNumber waitUntilDone:YES];
    }
    
    // 连接上新的序列号之后
    // todo: 把isConnectedBT改为false
    if(isConnectedBT == false && serialWritten == true && isConnectedMjm == true){
        // 再次确认魔棒状态
        NSData *enterQuery_second = [self toHexEnterQueryStatusCommandline];
        [blue writeChar:enterQuery_second];
        while(1){
            if(confirmState == true){
                break;
            }
        }
        intNumber = [NSNumber numberWithInt:6];
        [self performSelectorOnMainThread:@selector(updateUILabel:) withObject:intNumber waitUntilDone:YES];
        confirmState = false;
        
        // 比对确认新的序列号是否成功，由于再确认逻辑中有等待阻塞，故开启线程
        NSThread* myThread = [[NSThread alloc] initWithTarget:self selector:@selector(reconfirmSerialNum) object:nil];
        [myThread start];
        while(1){
            if(reconfirmResult == true){
                break;
            }
        }
        intNumber = [NSNumber numberWithInt:7];
        [self performSelectorOnMainThread:@selector(updateUILabel:) withObject:intNumber waitUntilDone:YES];
        // 结果反馈
        if(reconfirmResult){
            // 序列号比对成功
            NSString *str = @"序列号写入成功\n";
            
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
            NSString *str = @"序列号写入失败\n";
            
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
        reconfirmResult = false;
        return true;
    }
    return false;
}

- (bool)confirmHandshake:(NSData* ) midiData{
    NSUInteger len = [midiData length];
    NSUInteger loopCount = len / 5;
    const unsigned char *nsdata_bytes = (unsigned char*)[midiData bytes];
    
    unsigned int firstNum   = 0;//标志头字节
    unsigned int secondNum = 0;//按下抬起标志
    unsigned int thirdNum  = 0;//按键位置
    unsigned int forthNum   = 0;//红外传感器读取到的高位值
    unsigned int fifthNum    = 0;//红外传感器读取到的低位值
    for (int i = 0; i < loopCount; i++) {
        // Debug模式下，Midi报文的数据意义
        firstNum  = nsdata_bytes[i*5 + 0];//标志头字节
        secondNum = nsdata_bytes[i*5 + 1];//按下抬起标志
        thirdNum  = nsdata_bytes[i*5 + 2];//按键位置
        forthNum  = nsdata_bytes[i*5 + 3];//红外传感器读取到的高位值
        fifthNum  = nsdata_bytes[i*5 + 4];//红外传感器读取到的低位值
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

- (void)reconfirmSerialNum{
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
            break;
        }
    }
    serialResponse = false;
    
    // 生成写入前序列号
    NSData *data_previousA = [self newBluetoothSerialNumFirstSegment];
    NSData *data_previousB = [self newBluetoothSerialNumSecondSegment];
    
    // log
    NSLog(@"Serial num: data_currentA:%@",data_currentA);
    NSLog(@"Serial num: data_currentB:%@",data_currentB);
    NSLog(@"Serial num: data_previousA:%@",data_previousA);
    NSLog(@"Serial num: data_previousB:%@",data_previousB);
    
    // 比对序列号
    if(![data_previousA isEqual: data_currentA]){
        reconfirmResult = false;
    }
    else if(![data_previousB isEqual: data_currentB]){
        reconfirmResult = false;
    }
    else{
        reconfirmResult = true;
    }
    responsedFirstSegment = nil;
    responsedSecondSegment = nil;
}

- (NSData *)newBluetoothSerialNumFirstSegment{
    // 生成新序列号
    unsigned char data[5]= {};
    
    NSString *serialFirstNum  = [_codeNum substringWithRange:NSMakeRange(0, 1)];
    NSString *serialSecondNum = [_codeNum substringWithRange:NSMakeRange(1, 1)];
    NSString *serialThirdNum  = [_codeNum substringWithRange:NSMakeRange(2, 1)];
    NSString *serialFourthNum = [_codeNum substringWithRange:NSMakeRange(3, 1)];
    

    int serialFirstNum_asciiCode  = [serialFirstNum  characterAtIndex : 0];
    int serialSecondNum_asciiCode = [serialSecondNum characterAtIndex : 0];
    int serialThirdNum_asciiCode  = [serialThirdNum  characterAtIndex : 0];
    int serialFourthNum_asciiCode = [serialFourthNum characterAtIndex : 0];
    
    int firstNum  = (int)strtol("11", NULL, 16);
    int secondNum = serialFirstNum_asciiCode;
    int thirdNum  = serialSecondNum_asciiCode;
    int forthNum  = serialThirdNum_asciiCode;
    int fifthNum  = serialFourthNum_asciiCode;
    
    printf("%X-%X-%X-%X-%X\n",firstNum,secondNum,thirdNum,forthNum,fifthNum);
    data[0] = (char)firstNum;
    data[1] = (char)secondNum;
    data[2] = (char)thirdNum;
    data[3] = (char)forthNum;
    data[4] = (char)fifthNum;
    
    NSData *dataB =[NSData dataWithBytes:data length:5];
    NSLog(@"Serial number to be write-first segment:%@",dataB);
    return dataB;
}

- (NSData *)newBluetoothSerialNumSecondSegment{
    // 生成新序列号
    unsigned char data[5]= {};
    
    NSString *serialFirstNum  = [_codeNum substringWithRange:NSMakeRange(4, 1)];
    NSString *serialSecondNum = [_codeNum substringWithRange:NSMakeRange(5, 1)];
    NSString *serialThirdNum  = [_codeNum substringWithRange:NSMakeRange(6, 1)];
    NSString *serialFourthNum = [_codeNum substringWithRange:NSMakeRange(7, 1)];
    
    int serialFirstNum_asciiCode  = [serialFirstNum  characterAtIndex : 0];
    int serialSecondNum_asciiCode = [serialSecondNum characterAtIndex : 0];
    int serialThirdNum_asciiCode  = [serialThirdNum  characterAtIndex : 0];
    int serialFourthNum_asciiCode = [serialFourthNum characterAtIndex : 0];
    
    int firstNum  = (int)strtol("11", NULL, 16);
    int secondNum = serialFirstNum_asciiCode;
    int thirdNum  = serialSecondNum_asciiCode;
    int forthNum  = serialThirdNum_asciiCode;
    int fifthNum  = serialFourthNum_asciiCode;
    
    printf("%X-%X-%X-%X-%X\n",firstNum,secondNum,thirdNum,forthNum,fifthNum);
    data[0] = (char)firstNum;
    data[1] = (char)secondNum;
    data[2] = (char)thirdNum;
    data[3] = (char)forthNum;
    data[4] = (char)fifthNum;
    
    NSData *dataB =[NSData dataWithBytes:data length:5];
    NSLog(@"Serial number to be write-second segment:%@",dataB);
    return dataB;
}


#pragma mark 生成16进制命令-查询序列号
- (NSData *)toHexQuerySerialNumCommandline{
    unsigned char data[5]= {};
    
    int firstNum = (int)strtol("10", NULL, 16);
    int secondNum = (int)strtol("00", NULL, 16);
    int thirdNum = (int)strtol("00", NULL, 16);
    int forthNum = (int)strtol("00", NULL, 16);
    int fifthNum = (int)strtol("02", NULL, 16);
    
    printf("%X-%X-%X-%X-%X\n",firstNum,secondNum,thirdNum,forthNum,fifthNum);
    data[0] = (char)firstNum;
    data[1] = (char)secondNum;
    data[2] = (char)thirdNum;
    data[3] = (char)forthNum;
    data[4] = (char)fifthNum;
    
    NSData *dataB =[NSData dataWithBytes:data length:5];
    // log
    NSLog(@"Serial query command line:%@",dataB);
    return dataB;
}

#pragma mark 生成16进制命令-查询魔棒状态
- (NSData *)toHexEnterQueryStatusCommandline{
    unsigned char data[5]= {};
    
    int firstNum = (int)strtol("10", NULL, 16);
    int secondNum = (int)strtol("00", NULL, 16);
    int thirdNum = (int)strtol("00", NULL, 16);
    int forthNum = (int)strtol("00", NULL, 16);
    int fifthNum = (int)strtol("01", NULL, 16);
    
    printf("%X-%X-%X-%X-%X\n",firstNum,secondNum,thirdNum,forthNum,fifthNum);
    data[0] = (char)firstNum;
    data[1] = (char)secondNum;
    data[2] = (char)thirdNum;
    data[3] = (char)forthNum;
    data[4] = (char)fifthNum;
    
    NSData *dataB =[NSData dataWithBytes:data length:5];
    // log
    NSLog(@"Enter query command line:%@",dataB);
    return dataB;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc{
     [[NSNotificationCenter defaultCenter] removeObserver:self name:@"blueConnectSuccess" object:nil];
     [[NSNotificationCenter defaultCenter] removeObserver:self name:@"blueReciveSuccess" object:nil];
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
