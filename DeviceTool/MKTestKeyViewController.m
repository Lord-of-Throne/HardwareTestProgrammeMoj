//
//  MKTestKeyViewController.m
//  DeviceTool
//
//  Created by Monky on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "MKTestKeyViewController.h"
#import "MojoyBluetoothMgr.h"

@interface MKTestKeyViewController ()

@end
int tagButtonTestKeyView = 10000;
int tagCurrentLabelTestKeyView = 20000;
int tagButtonIsPassTestKeyView = 30000;
int tagLabelIsPassTestKeyView = 40000;
// 按键次数记录数组
unsigned int clickTimesTestKeyView[255];
// 按键状态记录数组
unsigned int clickStatusTestKeyView[255];
// 蓝牙名
NSString *bluetoothNameTestKeyView = @"mjm";
// 按键次数线
const int stageOne = 3;
const int stageTwo = 5;
// 琴键编号上下限
const int keyLowest = 24;
const int keyHighest = 107;

@implementation MKTestKeyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // 获得蓝牙单例
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    blue.deviceName = bluetoothNameTestKeyView;
    // 接收到数据的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getReciveData:) name:@"blueReciveSuccess" object:nil];
    
    // 布局控制
    // 按键布局
    const int top_HighGap   = 66;
    const int top_WidthGap  = 50;
    const int row_HighGap   = 95;
    const int line_WidthGap = 75;
    const int cell_Width    = 70;
    const int cell_High     = 80;
    // 标签布局
    const int top_WidthGap_KeyNumLabel   =  top_WidthGap + 5;
    const int top_WidthGap_LimitLabel    =  top_WidthGap_KeyNumLabel + 10;
    const int top_HighGap_KeyNumLabel    =  top_HighGap - 30;
    const int top_HighGap_HighLimitLabel =  top_HighGap_KeyNumLabel + 20;
    const int top_HighGap_CurrentLabel   =  top_HighGap_KeyNumLabel + 40;
    const int top_HighGap_LowLimitLabel  =  top_HighGap_KeyNumLabel + 60;
    // 按键次数默认值
    int defaultClickTimes = 0;
    
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
        // 代表按键的Button
        UIButton *btn1 =  [UIButton buttonWithType:UIButtonTypeCustom];
        btn1.tag = tagButtonTestKeyView + i;
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
        // 当前按键次数值label
        UILabel *labelCurrent = [[UILabel alloc] initWithFrame:CGRectMake(top_WidthGap_LimitLabel   + line_WidthGap   * line,
                                                                          top_HighGap_CurrentLabel  + row_HighGap     * row  + rowGap,
                                                                          cell_Width, cell_High)];
        NSString *strCurrent = [NSString stringWithFormat:@"%d",defaultClickTimes];
        labelCurrent.text = strCurrent;
        labelCurrent.textColor = [UIColor cyanColor];
//        labelCurrent.font = (UIFont *)fontWithSize:(CGFloat)fontSize;
        labelCurrent.tag = tagCurrentLabelTestKeyView + i;
        [self.view addSubview:labelCurrent];
    }
    // 当前魔棒是否合格标记：需所有按键就收到超过stageTwo次数方为合格
    UIButton *btnIsPass =  [UIButton buttonWithType:UIButtonTypeCustom];
    btnIsPass.tag = tagButtonIsPassTestKeyView;
    btnIsPass.backgroundColor = [UIColor redColor];
    btnIsPass.frame = CGRectMake(top_WidthGap + line_WidthGap * 12,
                                 top_HighGap  + row_HighGap   * 0,
                                 cell_Width, cell_High * 2);
    btnIsPass.enabled = false;
    [self.view addSubview:btnIsPass];
    
    UILabel *labelIsPass = [[UILabel alloc] initWithFrame:CGRectMake(top_WidthGap_LimitLabel   + line_WidthGap   * 12 - 5,
                                                                     top_HighGap_CurrentLabel  + row_HighGap     * 0  + 25,
                                                                     cell_Width, cell_High)];
    NSString *strCurrent = @"不合格";
    labelIsPass.text = strCurrent;
    labelIsPass.textColor = [UIColor cyanColor];
    labelIsPass.tag = tagLabelIsPassTestKeyView;
    [self.view addSubview:labelIsPass];
}

// 通知：接收到蓝牙数据的回调
- (void)getReciveData:(NSNotification *)notification{
    // 获得蓝牙单例
    MojoyBluetoothMgr *blue = [MojoyBluetoothMgr shareBlueTooth];
    
    NSDictionary * infoDic = [notification object];
    NSLog(@"App layer received:%@",infoDic[@"reciveData"]);
    NSData *midiData = infoDic[@"reciveData"];
    
    NSUInteger len = [midiData length];
    NSUInteger loopCount = len / 5;
    NSLog(@"Translating....");
    const unsigned char *nsdata_bytes = (unsigned char*)[midiData bytes];
    
    unsigned int noteHead1    = 0;
    unsigned int noteHead2    = 0;
    unsigned int noteStatus   = 0;
    unsigned int noteValue    = 0;
    unsigned int noteVelocity = 0;
    // 魔棒反馈数据，正常情况下每次5个字节
    for (int i = 0; i < loopCount; i++) {
        // 数据分解
        noteHead1    = nsdata_bytes[i*5 + 0];
        noteHead2    = nsdata_bytes[i*5 + 1];
        noteStatus   = nsdata_bytes[i*5 + 2];
        noteValue    = nsdata_bytes[i*5 + 3];
        noteVelocity = nsdata_bytes[i*5 + 4];
        
        // 数据解析，只处理midi信息，其他信息比如魔棒状态反馈和命令反馈信息被丢弃。日志全打印
        if(noteHead1 == 0x80 && noteHead2 == 0x80){
            // 反馈解析
            // 0x80魔棒正常状态下的报文
            // 与MKSerialController不同的是，此处的逻辑是仅对接收的数据进行处理，而不需等待魔棒返回确认信息。故逻辑放在收取数据出进行处理。
            // 标志头为80，数据正确，开始解析, debug header matched
            // 按键检查：note on(144代表按下键)接受到后，state变为1，在此基础上，相同键位的off(128代表键抬起)接收到后state变为2。
            // state为2时才代表该按键合格
            if(noteStatus == 0x80){
                //note off
                NSLog(@"Note off");
                if(clickStatusTestKeyView[noteValue] == 1){
                    clickStatusTestKeyView[noteValue] = 2;
                }
                
                if(clickStatusTestKeyView[noteValue] == 2){
                    // 记录按键次数
                    clickTimesTestKeyView[noteValue]++;
                    // 更新ui
                    [self updateUILabel:noteValue :noteStatus];
                    // 恢复默认
                    clickStatusTestKeyView[noteValue] = 0;
                }
            }else if(noteStatus == 0x90){
                //note on
                NSLog(@"Note on");
                clickStatusTestKeyView[noteValue] = 1;
                // 更新ui
                [self updateUILabel:noteValue :noteStatus];
            }
        }
        
        // Log输出
        NSString *reciveText = [NSString stringWithFormat:@"App layer recevie:%X %X %X %X %X",noteHead1,noteHead2,noteStatus,noteValue,noteVelocity];
        NSLog(@"%@",reciveText);
    }
}

- (void)updateUILabel:(int)noteValue: (int)noteStatus{
    NSArray*childViews = self.view.subviews;
    // 按键次数更新
    for (int i = 0; i<childViews.count; i++) {
        UILabel* labelValue = childViews[i];
        // 显示highLimit值
        if (labelValue.tag == tagCurrentLabelTestKeyView + noteValue) {
            NSString *str = [NSString stringWithFormat:@"%d",clickTimesTestKeyView[noteValue]];
            labelValue.text = str;
            if(clickTimesTestKeyView[noteValue] >= stageOne && clickTimesTestKeyView[noteValue] < stageTwo){
                labelValue.textColor = [UIColor yellowColor];
            }else if(clickTimesTestKeyView[noteValue] >= stageTwo){
                labelValue.textColor = [UIColor blueColor];
            }
        }
    } //end for
    
    // 按下或者抬起按键的ui表示
    if (noteStatus == 0x90) {
        NSLog(@"Debug MIDI Message : Key(%d) ON, click times = %u) ",noteValue,clickTimesTestKeyView[noteValue]);
        for (int i = 0; i<childViews.count; i++) {
            UIButton* btn = childViews[i];
            if (btn.tag == tagButtonTestKeyView + noteValue) {
                //btn.backgroundColor = [UIColor blueColor];
            }
        } // end for
        
    } else {
        if (noteStatus == 0x80) {
            NSLog(@"Debug MIDI Message : Key(%d) ON, click times = %u) ",noteValue,clickTimesTestKeyView[noteValue]);
            for (int i = 0; i<childViews.count; i++) {
                UIButton* btn = childViews[i];
                if (btn.tag == tagButtonTestKeyView + noteValue) {
                    //btn.backgroundColor = [UIColor blueColor];
                }
            } // end for
            
            
        } else {
            NSLog(@"Debug MIDI Message format error");
        }
        
    }
    // 检测是否通过
    bool isPass = true;
    for(int i=keyLowest; i<=keyHighest; i++){
        if(clickTimesTestKeyView[i] < stageTwo){
            isPass = false;
            break;
        }
    }
    if(isPass){
        NSLog(@"Debug MIDI Message : Key test is passed!) ");
        for (int i = 0; i<childViews.count; i++) {
            // 更新合格按钮背景色
            UIButton* btn = childViews[i];
            if (btn.tag == tagButtonIsPassTestKeyView ) {
                btn.backgroundColor = [UIColor greenColor];
            }
            
            UILabel* labelValue = childViews[i];
            // 更新合格按钮文字
            if (labelValue.tag == tagLabelIsPassTestKeyView) {
                NSString *str = @"合格";
                labelValue.text = str;
                labelValue.textColor = [UIColor blueColor];
            }
        } // end for
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
