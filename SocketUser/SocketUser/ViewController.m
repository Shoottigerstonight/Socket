//
//  ViewController.m
//  SocketUser
//
//  Created by 函冰 on 2018/5/16.
//  Copyright © 2018年 今晚打老虎. All rights reserved.
//
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import "ViewController.h"

@interface ViewController ()<UIAlertViewDelegate>
{
    NSString *myName;
    CFSocketRef _socket;
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
        const char *data = [stringToSend UTF8String];
        send(CFSocketGetNative(_socket), data, strlen(data) + 1, 1);
    }else{
        NSLog(@"未连接服务器");
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
//    获取alert的字符赋值给myname
    myName = [alertView textFieldAtIndex:0].text;
//创建socket无需回调函数
    _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketNoCallBack, nil, NULL);
    if (_socket != nil) {
//        定义sockadd_in    作为cfsocket的地址
        struct sockaddr_in addr4;
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
//        设置远程服务器地址
        addr4.sin_addr.s_addr = inet_addr("xx.xx.xx.xx");
        addr4.sin_port = htons(30000);
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
        CFSocketError result = CFSocketConnectToAddress(_socket, address, 5);
        if (result == kCFSocketSuccess) {
            isOnline = YES;
            [NSThread detachNewThreadSelector:@selector(readStream) toTarget:self withObject:nil];
        }
    }

}

@end
