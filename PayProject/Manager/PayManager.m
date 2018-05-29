//
//  PayManager.m
//  SpecialTreatment
//
//  Created by alading on 2017/12/7.
//  Copyright © 2017年 sailekeji. All rights reserved.
//

#import "PayManager.h"
#import "WXApi.h"
#import <AlipaySDK/AlipaySDK.h>

@interface PayManager ()<WXApiDelegate>

@property (nonatomic, copy) void(^PaySuccess)(PayCode code);
@property (nonatomic, copy) void(^PayError)(PayCode code);

@end

@implementation PayManager

static id _instance;
+ (instancetype)sharedApi {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[PayManager alloc] init];
    });
    
    return _instance;
}

///回调处理
- (BOOL) handleOpenURL:(NSURL *) url
{
    if ([url.host isEqualToString:@"safepay"])
    {
        // 支付跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processOrderWithPaymentResult:url standbyCallback:^(NSDictionary *resultDic) {
            //【由于在跳转支付宝客户端支付的过程中，商户app在后台很可能被系统kill了，所以pay接口的callback就会失效，请商户对standbyCallback返回的回调结果进行处理,就是在这个方法里面处理跟callback一样的逻辑】
            NSLog(@"result = %@",resultDic);

            NSInteger resultCode = [resultDic[@"resultStatus"] integerValue];
            switch (resultCode) {
                case 9000:     //支付成功
                    self.PaySuccess(ALIPAYSUCESS);
                    break;

                case 6001:     //支付取消
                    self.PaySuccess(ALIPAYCANCEL);
                    break;

                default:        //支付失败
                    self.PaySuccess(ALIPAYERROR);
                    break;
            }
        }];

        // 授权跳转支付宝钱包进行支付，处理支付结果
        [[AlipaySDK defaultService] processAuth_V2Result:url standbyCallback:^(NSDictionary *resultDic) {
            NSLog(@"result = %@",resultDic);
            // 解析 auth code
            NSString *result = resultDic[@"result"];
            NSString *authCode = nil;
            if (result.length>0) {
                NSArray *resultArr = [result componentsSeparatedByString:@"&"];
                for (NSString *subResult in resultArr) {
                    if (subResult.length > 10 && [subResult hasPrefix:@"auth_code="]) {
                        authCode = [subResult substringFromIndex:10];
                        break;
                    }
                }
            }
            NSLog(@"授权结果 authCode = %@", authCode?:@"");
        }];
        return YES;
    }
    //微信支付
    return [WXApi handleOpenURL:url delegate:self];
}

#pragma mark 支付宝支付
- (void)aliPayWithPayParam:(NSString *)pay_param
                   success:(void (^)(PayCode code))successBlock
                   failure:(void (^)(PayCode code))failBlock
{
    self.PaySuccess = successBlock;
    self.PayError = failBlock;
    NSString * appScheme =  @"qianguan";
    
    [[AlipaySDK defaultService] payOrder:pay_param fromScheme:appScheme callback:^(NSDictionary *resultDic) {
        NSLog(@"----- %@",resultDic);
        NSInteger resultCode = [resultDic[@"resultStatus"] integerValue];
        switch (resultCode) {
            case 9000:     //支付成功
                successBlock(ALIPAYSUCESS);
                break;
                
            case 6001:     //支付取消
                failBlock(ALIPAYCANCEL);
                break;
                
            default:        //支付失败
                failBlock(ALIPAYERROR);
                break;
        }
    }];
}


///微信支付
- (void)wxPayWithPayParam:(NSDictionary *)pay_param
                  success:(void (^)(PayCode code))successBlock
                  failure:(void (^)(PayCode code))failBlock {
    self.PaySuccess = successBlock;
    self.PayError = failBlock;
    
    //解析结果
    NSString *appid = pay_param[@"appid"];
    NSString *partnerid = pay_param[@"partnerid"];
    NSString *prepayid = pay_param[@"prepayid"];
    NSString *package = pay_param[@"package"];
    NSString *noncestr = pay_param[@"noncestr"];
    NSString *timestamp = pay_param[@"timestamp"];
    NSString *sign = pay_param[@"sign"];
    
    [WXApi registerApp:appid];
    
    if(![WXApi isWXAppInstalled]) {
        failBlock(WXERROR_NOTINSTALL);
        return ;
    }
    if (![WXApi isWXAppSupportApi]) {
        failBlock(WXERROR_UNSUPPORT);
        return ;
    }
    
    //发起微信支付
    PayReq* req   = [[PayReq alloc] init];
    //微信分配的商户号
    req.partnerId = partnerid;
    //微信返回的支付交易会话ID
    req.prepayId  = prepayid;
    // 随机字符串，不长于32位
    req.nonceStr  = noncestr;
    // 时间戳
    req.timeStamp = timestamp.intValue;
    //暂填写固定值Sign=WXPay
    req.package   = package;
    //签名
    req.sign      = sign;
    [WXApi sendReq:req];
    
    //日志输出
    NSLog(@"appid=%@\npartid=%@\nprepayid=%@\nnoncestr=%@\ntimestamp=%ld\npackage=%@\nsign=%@",appid,req.partnerId,req.prepayId,req.nonceStr,(long)req.timeStamp,req.package,req.sign );
}

#pragma mark - 微信回调
// 微信终端返回给第三方的关于支付结果的结构体
- (void)onResp:(BaseResp *)resp
{
    if ([resp isKindOfClass:[PayResp class]])
    {
        switch (resp.errCode) {
            case WXSuccess:
                self.PaySuccess(WXSUCESS);
                break;
                
            case WXErrCodeUserCancel:   //用户点击取消并返回
                self.PayError(WXSCANCEL);
                break;
                
            default:        //剩余都是支付失败
                self.PayError(WXERROR);
                break;
        }
    }
}

//url 加密
- (NSString*)urlEncodedString:(NSString *)string
{
    NSString * encodedString = (__bridge_transfer  NSString*) CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef)string, NULL, (__bridge CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8 );
    
    return encodedString;
}


@end
