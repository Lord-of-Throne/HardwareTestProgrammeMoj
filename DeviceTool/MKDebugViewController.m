//
//  MKDebugViewController.m
//  DeviceTool
//
//  Created by Monky on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "MKDebugViewController.h"
#import "MojoyBluetoothMgr.h"

@interface MKDebugViewController ()

@end

bool isDebugModeCommandLineWritten = false;

int _testKeyNumber = 0;
int _testKeyState = 0;
int tagButton = 10000;
int tagHighLimitLabel = 20000;
int tagCurrentLabel = 30000;
int tagLowLimitLabel = 40000;

// 高低位值数组：highLimit记录历史最大值，lowLimit记录历史最小值，currentValue记录最后一次读数值
unsigned int highLimit[255];
unsigned int lowLimit[255];
unsigned int current[255];
// 蓝牙名
NSString *bluetoothName = @"mjm";

@implementation MKDebugViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // 获得蓝牙单例
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    blue.deviceName = bluetoothName;
    // 接收到数据的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getReciveData:) name:@"blueReciveSuccess" object:nil];
    // 布局视图绘制
    for  (int i = 24; i <= 107; i++) {
        // 格式控制
        int quantity = i - 24;
        int line = quantity % 12;
        int row = quantity / 12;
        // 行间距
        int rowGap = 10;
        if(row % 2 == 0){
            rowGap = 0;
        }else{
            rowGap = 10;
        }
        // 布局控制
        // 按键布局
        int top_HighGap   = 66;
        int top_WidthGap  = 50;
        int row_HighGap   = 95;
        int line_WidthGap = 75;
        int cell_Width    = 70;
        int cell_High     = 80;
        // 标签布局
        int top_WidthGap_KeyNumLabel   =  top_WidthGap + 5;
        int top_WidthGap_LimitLabel    =  top_WidthGap_KeyNumLabel + 10;
        int top_HighGap_KeyNumLabel    =  top_HighGap - 30;
        int top_HighGap_HighLimitLabel =  top_HighGap_KeyNumLabel + 20;
        int top_HighGap_CurrentLabel   =  top_HighGap_KeyNumLabel + 40;
        int top_HighGap_LowLimitLabel  =  top_HighGap_KeyNumLabel + 60;
        
        // 高低位值的默认值
        int highLimitDefault = 0;
        int lowLimitDefault  = 65535;
        int currentDefault   = 50;
        
        highLimit[i] = 0;
        lowLimit[i]  = 65535;
        current[i]   = 0;
        
        // 代表按键的Button
        UIButton *btn1 =  [UIButton buttonWithType:UIButtonTypeCustom];
        btn1.tag = tagButton + i;
        btn1.backgroundColor = [UIColor lightGrayColor];
        btn1.frame = CGRectMake(top_WidthGap + line_WidthGap * line,
                                top_HighGap  + row_HighGap   * row + rowGap,
                                cell_Width, cell_High);
        btn1.enabled = false;
        // Black key黑键
        if(line == 1 || line == 3  || line == 6 || line == 8 || line == 10){
            btn1.backgroundColor = [UIColor blackColor];
        }
        [self.view addSubview:btn1];
        [btn1 addTarget:self action:@selector(clickMethod) forControlEvents:UIControlEventTouchUpInside];
        // Key number按键label
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(top_WidthGap_KeyNumLabel + line_WidthGap * line,
                                                                   top_HighGap_KeyNumLabel  + row_HighGap   * row + rowGap,
                                                                   cell_Width, cell_High)];
        NSString *str = [NSString stringWithFormat:@"%d",i];
        label.text = str;
        label.textColor = [UIColor cyanColor];
        [self.view addSubview:label];
        // High limit高位值label
        UILabel *labelHighLimit = [[UILabel alloc] initWithFrame:CGRectMake(top_WidthGap_LimitLabel    + line_WidthGap * line,
                                                                            top_HighGap_HighLimitLabel + row_HighGap   * row + rowGap,
                                                                            cell_Width, cell_High)];
        NSString *strHighLimit = [NSString stringWithFormat:@"%d",highLimitDefault];
        labelHighLimit.text = strHighLimit;
        labelHighLimit.textColor = [UIColor cyanColor];
        labelHighLimit.tag = tagHighLimitLabel + i;
        [self.view addSubview:labelHighLimit];
        // current当前值label
        UILabel *labelCurrent = [[UILabel alloc] initWithFrame:CGRectMake(top_WidthGap_LimitLabel   + line_WidthGap   * line,
                                                                          top_HighGap_CurrentLabel  + row_HighGap     * row  + rowGap,
                                                                          cell_Width, cell_High)];
        NSString *strCurrent = [NSString stringWithFormat:@"%d",currentDefault];
        labelCurrent.text = strCurrent;
        labelCurrent.textColor = [UIColor cyanColor];
        labelCurrent.tag = tagCurrentLabel + i;
        [self.view addSubview:labelCurrent];
        // Low limit低位值label
        UILabel *labelLowLimit = [[UILabel alloc] initWithFrame:CGRectMake(top_WidthGap_LimitLabel   + line_WidthGap   * line,
                                                                           top_HighGap_LowLimitLabel + row_HighGap     * row  + rowGap,
                                                                           cell_Width, cell_High)];
        NSString *strLowLimit = [NSString stringWithFormat:@"%d",lowLimitDefault];
        labelLowLimit.text = strLowLimit;
        labelLowLimit.textColor = [UIColor cyanColor];
        labelLowLimit.tag = tagLowLimitLabel + i;
        [self.view addSubview:labelLowLimit];
    }

}

#pragma mark 生成16进制命令-切换进入调试模式
- (NSData *)toHexEnterDebugModeCommandline{
    unsigned char data[5]= {};
    
    int firstNum = (int)strtol("10", NULL, 16);
    int secondNum = (int)strtol("00", NULL, 16);
    int thirdNum = (int)strtol("00", NULL, 16);
    int forthNum = (int)strtol("00", NULL, 16);
    int fifthNum = (int)strtol("07", NULL, 16);
    
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

#pragma mark 生成16进制命令-切换进入调试模式
- (NSData *)toHexExitDebugModeCommandline{
    unsigned char data[5]= {};
    
    int firstNum = (int)strtol("10", NULL, 16);
    int secondNum = (int)strtol("00", NULL, 16);
    int thirdNum = (int)strtol("00", NULL, 16);
    int forthNum = (int)strtol("00", NULL, 16);
    int fifthNum = (int)strtol("09", NULL, 16);
    
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

// 通知：接收到蓝牙数据的回调
- (void)getReciveData:(NSNotification *)notification{
    // 获得蓝牙单例
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    if(!isDebugModeCommandLineWritten){
        // 切换到调试模式
        NSData *switchToDebugMode = [self toHexEnterDebugModeCommandline];
        [blue writeChar:switchToDebugMode];
        isDebugModeCommandLineWritten = true;
    }
    
    NSDictionary * infoDic = [notification object];
    NSLog(@"App layer received:%@",infoDic[@"reciveData"]);
    NSData *midiData = infoDic[@"reciveData"];
    
    // 数据解析，只处理midi信息，其他信息比如魔棒状态反馈和命令反馈信息被丢弃。日志全打印
    NSUInteger len = [midiData length];
    NSUInteger loopCount = len / 5;
    NSLog(@"Translating....");
    const unsigned char *nsdata_bytes = (unsigned char*)[midiData bytes];
    
    unsigned int noteHead   = 0;
    unsigned int noteStatus = 0;
    unsigned int noteValue  = 0;
    unsigned int noteHigh   = 0;
    unsigned int noteLow    = 0;
    // 魔棒反馈数据，正常情况下每次5个字节
    for (int i = 0; i < loopCount; i++) {
        // 数据分解
        noteHead   = nsdata_bytes[i*5 + 0];
        noteStatus = nsdata_bytes[i*5 + 1];
        noteValue  = nsdata_bytes[i*5 + 2];
        noteHigh   = nsdata_bytes[i*5 + 3];
        noteLow    = nsdata_bytes[i*5 + 4];
        // 反馈解析
        // 0x81魔棒调试状态下的报文
        // 与MKSerialController不同的是，此处的逻辑是仅对接收的数据进行处理，而不需等待魔棒返回确认信息。故逻辑放在收取数据出进行处理。
        // 标志头为81，数据正确，开始解析, debug header matched
        if(noteHead == 0x81)
        {
            // 拼接数值：noteHigh为高8位，noteLow为低8位，拼接在一起。highLimit记录拼接结果的历史最大值，lowLimit记录拼接结果的历史最小值，currentValue记录当前值
            unsigned int mergeValue = (noteHigh<<8) + noteLow;
            
            current[noteValue] = mergeValue;
            if(highLimit[noteValue] <= mergeValue){
                highLimit[noteValue] = mergeValue;
            }
            if(lowLimit[noteValue] >=  mergeValue){
                lowLimit[noteValue] = mergeValue;
            }
            
            if(mergeValue > 30000){
                NSLog(@"Note head:%u,Note status:%u,note value:%u, note high:%u, note low:%u",noteHead,noteStatus,noteValue,noteHigh,noteLow);
            }
            
            if(noteValue == 36){
                NSLog(@"Note head:%u,Note status:%u,note value:%u, note high:%u, note low:%u",noteHead,noteStatus,noteValue,noteHigh,noteLow);
            }
            // 更新UI
            [self updateUILabel:noteValue :noteStatus :mergeValue];
            
        } //end if nead = 129
        else{
            
            NSLog(@"Unexpected data package: Note head:%u,Note status:%u,note value:%u, note high:%u, note low:%u",noteHead,noteStatus,noteValue,noteHigh,noteLow);
        }
        
        // Log输出
        NSString *reciveText = [NSString stringWithFormat:@"App layer recevie:%X %X %X %X %X",noteHead,noteStatus,noteValue,noteHigh,noteLow];
        NSLog(@"%@",reciveText);
    }
}

- (void)updateUILabel:(int)noteValue: (int)noteStatus: (int)mergeValue{
    NSArray*childViews = self.view.subviews;
    // 更新Label值
    for (int i = 0; i<childViews.count; i++) {
        UILabel* labelValue = childViews[i];
        // 显示highLimit值
        if (labelValue.tag == tagHighLimitLabel + noteValue) {
            NSString *str = [NSString stringWithFormat:@"%d",highLimit[noteValue]];
            labelValue.text = str;
            labelValue.textColor = [UIColor blueColor];
        }
        // 显示current值
        else if (labelValue.tag == tagCurrentLabel + noteValue) {
            NSString *str = [NSString stringWithFormat:@"%d",current[noteValue]];
            labelValue.text = str;
            labelValue.textColor = [UIColor blueColor];
        }
        // 显示lowLimit值
        else if (labelValue.tag == tagLowLimitLabel + noteValue) {
            NSString *str = [NSString stringWithFormat:@"%d",lowLimit[noteValue]];
            labelValue.text = str;
            labelValue.textColor = [UIColor blueColor];
        }
        
    } //end for
    
    if (noteStatus == 0x90) {
        NSLog(@"Debug MIDI Message : Key(%d) ON, current reflect value = %u, history reflect value (high = %u, low = %u) ",noteValue,mergeValue,highLimit[noteValue],lowLimit[noteValue]);
        for (int i = 0; i<childViews.count; i++) {
            UIButton* btn = childViews[i];
            if (btn.tag == tagButton + noteValue) {
                //btn.backgroundColor = [UIColor blueColor];
            }
        } // end for
        
    } else {
        if (noteStatus == 0x80) {
            NSLog(@"Debug MIDI Message : Key(%d) OFF, current reflect value = %u, history reflect value (high = %u, low = %u) ",noteValue,mergeValue,highLimit[noteValue],lowLimit[noteValue]);
            for (int i = 0; i<childViews.count; i++) {
                UIButton* btn = childViews[i];
                if (btn.tag == tagButton + noteValue) {
                    //btn.backgroundColor = [UIColor blueColor];
                }
            } // end for
            
            
        } else {
            NSLog(@"Debug MIDI Message format error");
        }
        
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    // 获得蓝牙单例
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    // 注销监听器
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"blueReciveSuccess" object:nil];
    // 退出调试模式
    NSData *exitDebugMode = [self toHexExitDebugModeCommandline];
    [blue writeChar:exitDebugMode];
    isDebugModeCommandLineWritten = false;
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
