//
//  MKTabBarController.m
//  DeviceTool
//
//  Created by Monky on 2017/3/20.
//  Copyright © 2017年 Monky. All rights reserved.
//

#import "MKTabBarController.h"
#import "MKScanCodeViewController.h"
#import "MKTestKeyViewController.h"
#import "MKDebugViewController.h"
#import "MKNavViewController.h"

@interface MKTabBarController ()

@end

@implementation MKTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /* 初始化子控制器 */
    /* 扫码 */
    [self addChrildWithVCtrl:[[MKScanCodeViewController alloc] init] Title:@"扫码测试" image:@"tabbar_scan_nor" selectedImage:@"tabbar_scan_hl"];
    
    /* 按键测试 */
    [self addChrildWithVCtrl:[[MKTestKeyViewController alloc] init] Title:@"按键测试" image:@"tabbar_key_nor" selectedImage:@"tabbar_key_hl"];
    
    /* 自定义调试 */
    [self addChrildWithVCtrl:[[MKDebugViewController alloc] init] Title:@"自定义调试" image:@"tabbar_debug_nor" selectedImage:@"tabbar_debug_hl"];
}

- (void)addChrildWithVCtrl:(UIViewController *)vCtrl Title:(NSString *)title image:(NSString *)image selectedImage:(NSString *)selectedImage
{
    //同时设置tabBarItem和navigationItem的title
    vCtrl.title = title;
    
    //普通状态和高亮状态显示图片
    vCtrl.tabBarItem.image = [UIImage imageNamed:image];
    vCtrl.tabBarItem.selectedImage = [[UIImage imageNamed:selectedImage] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    //普通状态和高亮状态文字样式
//    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
//    attributes[NSForegroundColorAttributeName] = [UIColor lightGrayColor];
//    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize:12];
//    NSMutableDictionary *selectedAttributes = [NSMutableDictionary dictionary];
//    selectedAttributes[NSForegroundColorAttributeName] = [UIColor blueColor];
//    
//    [vCtrl.tabBarItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
//    [vCtrl.tabBarItem setTitleTextAttributes:selectedAttributes forState:UIControlStateSelected];
    
    //添加自定义导航控制器
    MKNavViewController *navCtrl = [[MKNavViewController alloc] initWithRootViewController:vCtrl];
    
    [self addChildViewController:navCtrl];
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
