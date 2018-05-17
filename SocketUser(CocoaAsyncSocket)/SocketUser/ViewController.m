//
//  ViewController.m
//  SocketUser
//
//  Created by 函冰 on 2018/5/16.
//  Copyright © 2018年 今晚打老虎. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"

@interface ViewController ()<UIAlertViewDelegate,GCDAsyncSocketDelegate>
{
    NSString *myName;
    GCDAsyncSocket *_socket;
    BOOL isOnline;
}
/**    */
@property (weak, nonatomic) IBOutlet UILabel *showView;

/** <#注释#>   */
@property (weak, nonatomic) IBOutlet UITextField *inputField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    创建一个UIalertview提醒用户输入名字
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"名字" message:@"请输入您的名字" delegate:self cancelButtonTitle:@"确定" otherButtonTitles: nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert show];
}

- (void)finishEdit:(UIButton*)sender
{
    [sender resignFirstResponder];
}
- (IBAction)send:(id)sender {
    if (isOnline) {
        NSString *stringToSend = [NSString stringWithFormat:@"%@说:%@",myName,self.inputField.text];
        self.inputField.text = nil;
        [_socket writeData:[stringToSend dataUsingEncoding:NSUTF8StringEncoding] withTimeout:5 tag:0];
    }else{
        NSLog(@"未连接服务器");
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
//    获取alert的字符赋值给myname
    myName = [alertView textFieldAtIndex:0].text;
//创建socket无需回调函数
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    if (_socket != nil) {
        NSError *error = nil;
        NSString *host = @"xx.xx.xx.xx";
        int port = 30000;
        [_socket connectToHost:host onPort:port error:&error];
        if (error) {
            NSLog(@"连接出现错误!---%@----",error);
        }
    }

}

#pragma mark     ------  代理方法
//连接到服务器时触发
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    isOnline = YES;
    NSLog(@"已连接到服务器!");
    [sock readDataWithTimeout:-1 tag:0];
}
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    self.showView.text = [self.showView.text stringByAppendingString:[NSString stringWithFormat:@"%@\n",string]];
    [sock readDataWithTimeout:-1 tag:0];
}

@end
