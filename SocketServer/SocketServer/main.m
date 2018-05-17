//
//  main.m
//  SocketServer
//
//  Created by 函冰 on 2018/5/16.
//  Copyright © 2018年 今晚打老虎. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <arpa/inet.h>

CFWriteStreamRef oStream;

void readStream (CFReadStreamRef iStream,CFStreamEventType eventType,void *clientCallBackInfo)
{
    uint8 buff[2048];
    CFIndex hasRead = CFReadStreamRead(iStream, buff, 2048);
    if (hasRead > 0) {
        buff[hasRead] = '\0';
        printf("接收到数据:%s\n",buff);
        const char *str = (char *)buff;
        //            向客户端输出数据
        CFWriteStreamWrite(oStream, (uint8 *)str, strlen(str) + 1);
    }
}

void TCPServerAcceptCallBack(CFSocketRef socket,CFSocketCallBackType type,CFDataRef address,const void *data,void *info)
{
//如果有客户端连接进来
    if (kCFSocketAcceptCallBack == type) {
//        本地socket的handle
        CFSocketNativeHandle nativaSocketHandle = *(CFSocketNativeHandle *)data;
        uint8_t name[SOCK_MAXADDRLEN];
        socklen_t nameLen = sizeof(name);
//        获取对方的socket信息，和本程序的socket信息
        if (getpeername(nativaSocketHandle, (struct sockaddr*)name, &nameLen) != 0) {
            NSLog(@"error");
            exit(1);
        }
        
//        获取连接信息
        struct sockaddr_in *add_in = (struct sockaddr_in *)name;
        NSLog(@"%s : %d",inet_ntoa(add_in -> sin_addr),add_in -> sin_port);
        CFReadStreamRef iStream;
        
//        创建一个可读写的CFStream
        CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativaSocketHandle, &iStream, &oStream);
        if (iStream && oStream) {
//            打开输入流和输出流
            CFReadStreamOpen(iStream);
            CFWriteStreamOpen(oStream);
            CFStreamClientContext streamConText = {0,NULL,NULL,NULL};
//            readStream函数为有可读数据时候调用
            if (!CFReadStreamSetClient(iStream, kCFStreamEventHasBytesAvailable, readStream, &streamConText)) {
                exit(1);
            }
            CFReadStreamScheduleWithRunLoop(iStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
            const char *str = "您好，您已成功连接\n";
//            向客户端输出数据
            CFWriteStreamWrite(oStream, (uint8 *)str, strlen(str) + 1);
        }
    }
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
//        创建socket,指定callback
        CFSocketRef _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, TCPServerAcceptCallBack, NULL);
        if (_socket == NULL) {
            NSLog(@"创建socket失败");
            return 0;
        }
        int optval = 1;
//        设置允许重用本地地址和端口
        setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (void*)&optval, sizeof(optval));
//        定义socket地址
        struct sockaddr_in addr4;
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
//        设置本服务器可以监听本机任意可用 的IP地址
//        addr4.sin_addr.s_addr = htonl(INADDR_ANY);
//        设置服务器的监听地址,里面设置自己本机的网络地址
        addr4.sin_addr.s_addr = inet_addr("192.168.1.13");
//        设置服务器监听端口
        addr4.sin_port = htons(30000);
//        将ipv4转换为cfdataref
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (uint8 *)&addr4, sizeof(addr4));
//        将cfsocket绑定到指定的IP
        if (CFSocketSetAddress(_socket, address) != kCFSocketSuccess) {
            NSLog(@"地址绑定失败");
//            如果_socket不为null。释放_socket
            if (_socket) {
                CFRelease(_socket);
                exit(1);
            }
            _socket = NULL;
        }
        NSLog(@"启动循环监听客户端连接-----");
//        获取当前线程的runloop
        CFRunLoopRef cfrunloop = CFRunLoopGetCurrent();
//        将socket包装成cfrunloopsource
        CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
//        为runloop添加source
        CFRunLoopAddSource(cfrunloop, source, kCFRunLoopCommonModes);
        CFRelease(source);
        CFRunLoopRun();
    }
    return 0;
}
