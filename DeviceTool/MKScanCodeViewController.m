//
//  MKScanCodeViewController.m
//  DeviceTool
//
//  Created by Monky on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "MKScanCodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MKSerialController.h"
#define MAINSCREEN_BOUNDS [UIScreen mainScreen].bounds
#define SYSTEM_VERSION_FLOAT [[UIDevice currentDevice]systemVersion].floatValue
#define RGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

@interface MKScanCodeViewController ()<AVCaptureMetadataOutputObjectsDelegate>
{
    AVCaptureSession *avSession;
    AVCaptureDevice *avDevice;
    AVCaptureDeviceInput *avInput;
    AVCaptureMetadataOutput *avOutput;
    AVCaptureVideoPreviewLayer *preViewLayer;
    CGRect drawRect;
    UIImageView *blueImageView;
    NSString *tiaoxinmaString;
}
@property (strong, nonatomic) UILabel *descriptionLabel;
@end

@implementation MKScanCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createScanner];
    [self.view insertSubview:[self makeScanCameraShadowViewWithRect:[self makeScanReaderInterrestRect]] atIndex:1];
}
- (void)viewDidAppear:(BOOL)animated{
    [avSession startRunning];
}
/*
 扫码框frame
 */
- (CGRect)makeScanReaderInterrestRect {
    CGFloat size = MIN(MAINSCREEN_BOUNDS.size.width, MAINSCREEN_BOUNDS.size.height)*3/5;
    CGRect scanRect = CGRectMake(0, 0, size, size);
    scanRect.origin.x = MAINSCREEN_BOUNDS.size.width/2 - scanRect.size.width / 2;
    scanRect.origin.y = MAINSCREEN_BOUNDS.size.height / 3 - scanRect.size.height / 2;
    return scanRect;
}
/*
 生成扫码框
 */
- (UIImageView *)makeScanCameraShadowViewWithRect:(CGRect)rect {
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:MAINSCREEN_BOUNDS];
    UIGraphicsBeginImageContext(imgView.frame.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 0, 0, 0, 0.3);
    drawRect = MAINSCREEN_BOUNDS;
    CGContextFillRect(context, drawRect);
    
    [self.descriptionLabel removeFromSuperview];
    drawRect = CGRectMake(rect.origin.x - imgView.frame.origin.x-rect.size.width/6, rect.origin.y - imgView.frame.origin.y+rect.size.height/3+20+50, rect.size.width*4/3, rect.size.height*2/3);
    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(drawRect.origin.x, drawRect.origin.y+drawRect.size.height, drawRect.size.width, 60.0)];
    self.descriptionLabel.font = [UIFont systemFontOfSize:12];
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
    self.descriptionLabel.textColor= [UIColor whiteColor];
    self.descriptionLabel.text = @"将条码放入框内，即可自动扫描";
    [self.view addSubview:self.descriptionLabel];

    [self createCornerView:drawRect];
    CGContextClearRect(context, drawRect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    imgView.image = image;
    return imgView;
}
/*
 四边角
 */
- (void)createCornerView:(CGRect)frame {
    UIImage *upLeftImg = [UIImage imageNamed:@"leftCorner"];
    UIImageView *upleftimgView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x , frame.origin.y, 20.0, 20.0)];
    upleftimgView.image = upLeftImg;
    UIImageView *downLeftImgView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x , frame.origin.y + frame.size.height-20.0, 20.0, 20.0)];
    downLeftImgView.image = [UIImage imageNamed:@"downLeftCorner"];
    UIImageView *upRightImgView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x + frame.size.width-20.0, frame.origin.y, 20.0, 20.0)];
    upRightImgView.image = [UIImage imageNamed:@"rightCorner"];
    UIImageView *downRightImgView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x + frame.size.width-20.0, frame.origin.y + frame.size.height-20.0, 20.0, 20.0)];
    downRightImgView.image = [UIImage imageNamed:@"downRightCorner"];
    [self.view addSubview:upRightImgView];
    [self.view addSubview:downRightImgView];
    [self.view addSubview:downLeftImgView];
    [self.view addSubview:upleftimgView];
}


/*
 生成扫码器
 */
- (void)createScanner {
    avDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    avInput = [AVCaptureDeviceInput deviceInputWithDevice:avDevice error:nil];
    avOutput = [[AVCaptureMetadataOutput alloc] init];
    [avOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    avSession = [[AVCaptureSession alloc] init];
    [avSession setSessionPreset:AVCaptureSessionPresetHigh];
    if ([avSession canAddInput:avInput]) {
        [avSession addInput:avInput];
    }
    if ([avSession canAddOutput:avOutput]) {
        [avSession addOutput:avOutput];
    }
    
    if (SYSTEM_VERSION_FLOAT < 8.0) {
        avOutput.metadataObjectTypes = @[AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeQRCode,AVMetadataObjectTypeAztecCode,/*AVMetadataObjectTypeInterleaved2of5Code,AVMetadataObjectTypeITF14Code,AVMetadataObjectTypeDataMatrixCode*/];
    }
    else {
        avOutput.metadataObjectTypes = @[AVMetadataObjectTypeCode128Code,AVMetadataObjectTypeUPCECode,AVMetadataObjectTypeCode39Code,AVMetadataObjectTypeCode39Mod43Code,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode93Code,AVMetadataObjectTypePDF417Code,AVMetadataObjectTypeQRCode,AVMetadataObjectTypeAztecCode,AVMetadataObjectTypeInterleaved2of5Code,AVMetadataObjectTypeITF14Code,AVMetadataObjectTypeDataMatrixCode];
    }
    
    preViewLayer = [AVCaptureVideoPreviewLayer layerWithSession:avSession];
    preViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preViewLayer.frame = CGRectMake(0, 0, MAINSCREEN_BOUNDS.size.width, MAINSCREEN_BOUNDS.size.height);
    preViewLayer.connection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    AVCaptureConnection *output2VideoConnection = [avOutput connectionWithMediaType:AVMediaTypeVideo];
    output2VideoConnection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
    [self.view.layer insertSublayer:preViewLayer atIndex:0];
    [avSession startRunning];
}

/*
 扫码完成后代理
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    NSString *stringValue;
    
    if ([metadataObjects count] >0)
    {
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex:0];
        stringValue = metadataObject.stringValue;
    }
    [avSession stopRunning];
    [blueImageView.layer removeAllAnimations];
    if (stringValue.length > 0) {
        tiaoxinmaString = stringValue;
        NSString *str = [NSString stringWithFormat:@"是否确认连接\n %@",stringValue];

        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提示" message:str preferredStyle:UIAlertControllerStyleAlert];
        [alertVc addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [avSession startRunning];
            NSLog(@"点击取消");
        }]];

        [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            MKSerialController *serialVC = [[MKSerialController alloc]init];
            serialVC.codeNum = stringValue;
            [self.navigationController pushViewController:serialVC animated:YES];
            NSLog(@"点击确认");
            
        }]];
        

        [self presentViewController:alertVc animated:YES completion:nil];
    }
}

//摄像头横屏
- (AVCaptureVideoOrientation) videoOrientationFromCurrentDeviceOrientation {
    return AVCaptureVideoOrientationLandscapeLeft;
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
