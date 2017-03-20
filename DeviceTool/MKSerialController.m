//
//  MKSerialController.m
//  DeviceTool
//
//  Created by Monky on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "MKSerialController.h"

@interface MKSerialController ()

@end

@implementation MKSerialController

- (void)viewDidLoad {
    [super viewDidLoad];
     self.view.backgroundColor = [UIColor colorWithWhite:0.858 alpha:1.000];
    NSLog(@"codeNum:%@",self.codeNum);
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark 生成16进制命令
- (NSData *)toHexCommandline:(char *)commandLine{
    unsigned char data[5]= {};
    
    int firstNum = (int)strtol(&commandLine[0], NULL, 16);
    int secondNum = (int)strtol(&commandLine[1], NULL, 16);
    int thirdNum = (int)strtol(&commandLine[2], NULL, 16);
    int forthNum = (int)strtol(&commandLine[3], NULL, 16);
    int fifthNum = (int)strtol(&commandLine[4], NULL, 16);
    
    printf("%X-%X-%X-%X-%X",firstNum,secondNum,thirdNum,forthNum,fifthNum);
    data[0] = (char)firstNum;
    data[1] = (char)secondNum;
    data[2] = (char)thirdNum;
    data[3] = (char)forthNum;
    data[4] = (char)fifthNum;
    
    NSData *dataB =[NSData dataWithBytes:data length:5];
    return dataB;
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
