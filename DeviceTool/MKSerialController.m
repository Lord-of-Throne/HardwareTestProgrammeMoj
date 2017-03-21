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
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    blue.deviceName = @"mjm-";
    //连接成功获取特征值的通知
     [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectSuccess) name:@"blueConnectSuccess" object:nil];
    //接收到数据的通知
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(getReciveData:) name:@"blueReciveSuccess" object:nil];
}

- (void)getReciveData:(NSNotification *)notification{
    NSDictionary * infoDic = [notification object];
    NSLog(@"getRecive:%@",infoDic[@"reciveData"]);
}

- (void)connectSuccess{
    // 写入新的序列号
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    NSData *newSerial = [self newBluetoothSerialNum];
    [blue writeChar:newSerial];
    // 重新连接新的codeNum蓝牙
    
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
}
- (NSData *)newBluetoothSerialNum{
    // 生成新序列号
    unsigned char data[1]= {};
    NSString *name = _codeNum;
    data[0] = (char)name;
    NSData *dataB =[NSData dataWithBytes:data length:4];
    return dataB;
}

- (bool)reconfirmSerialNum{
    // 查询序列号
    NSData *dataA = [self toHexConfrimSerialNumCommandline];
    
    // 生成写入前序列号
    unsigned char data[1]= {};
    NSString *name = _codeNum;
    data[0] = (char)name;
    NSData *dataB =[NSData dataWithBytes:data length:4];
    // 比对序列号
    if(dataA != dataB){
        return false;
    }else{
        return true;
    }
}
#pragma mark 生成16进制命令
- (NSData *)toHexConfrimSerialNumCommandline{
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
