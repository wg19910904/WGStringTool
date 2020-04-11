
//  Copyright © 2019 WG. All rights reserved.


#import "NSString+Tool.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
@implementation NSString (Tool)
+(void)load{
    //防止拼接nil时崩溃
    Method oldAppending = class_getInstanceMethod(self, @selector(stringByAppendingString:));
    Method newAppending = class_getInstanceMethod(self, @selector(WGStringByAppendingString:));
    /**
     *  我们在这里使用class_addMethod()函数对Method Swizzling做了一层验证，如果self没有实现被交换的方法，会导致失败。
     *  而且self没有交换的方法实现，但是父类有这个方法，这样就会调用父类的方法，结果就不是我们想要的结果了。
     *  所以我们在这里通过class_addMethod()的验证，如果self实现了这个方法，class_addMethod()函数将会返回NO，我们就可以对其进行交换了。
     */
    if (!class_addMethod([self class], @selector(stringByAppendingString:), method_getImplementation(newAppending), method_getTypeEncoding(newAppending))) {
        method_exchangeImplementations(oldAppending, newAppending);
    }
}
- (NSString *)WGStringByAppendingString:(NSString *)string{
    //判断要拼接的字符串是否为nil
    if (string == nil) {
        NSLog(@"拼接了空字符串");
        return self;
    }else{
        return [self WGStringByAppendingString:string];
    }
}

+(NSString *)md5HexDigest:(NSString *)input{
    const char* str = [input UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), result);
    NSMutableString *ret = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH];
    for(int i = 0; i<CC_MD5_DIGEST_LENGTH; i++) {
        [ret appendFormat:@"%02x",result[i]];
    }
    return ret;
}

+(NSInteger)getDatelineOfDate:(NSString *)date formate:(NSString *)formate{
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formate];
    NSDate *distanceDate = [dateFormatter dateFromString:date];
    return [distanceDate timeIntervalSince1970];
}

+(NSString *)formateDate:(NSString *)formate dateline:(NSInteger)unixTime{
    
    NSDate *detailDate = [NSDate dateWithTimeIntervalSince1970:unixTime];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:formate];
    NSString *currentdateStr = [dateFormatter stringFromDate:detailDate];
    return currentdateStr;
}

+(NSString *)distanceTimeFormNow:(NSInteger)unixTime{
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:unixTime];
    NSInteger longtime = [date timeIntervalSinceNow];
    int day = -(int)longtime/(3600*24);
    int hour = -(int)(longtime-day*24*3600)/3600;
    int min = -(int)(longtime-day*24*3600-3600*hour)/60;
    NSString *str;
    if (day==0) {
        if (hour==0) {
            if (min==0)  str=@"1分钟前";
            else str=[NSString stringWithFormat:@"%d分钟前",min];
        }else{
            if (min==0) {
                str=[NSString stringWithFormat:@"%d小时前",hour];
            }else{
                str=[NSString stringWithFormat:@"%d小时%d分钟前",hour,min];
            }
        }
    }else{
        if (hour==0) {
            if (min==0)  str=[NSString stringWithFormat:@"%d天",day];
            else str=[NSString stringWithFormat:@"%d天%d分钟前",day,min];
        }else{
            if (min==0) {
                str=[NSString stringWithFormat:@"%d天%d小时前",day,hour];
            }else{
                str=[NSString stringWithFormat:@"%d天%d小时%d分钟前",day,hour,min];
            }
        }
    }
    
    return str;
}


//将字典转换为json字符串
+ (NSString*)dictionaryToJson:(NSDictionary *)dic

{
    NSError *parseError = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
/**
 *  截取小数点后两位
 *
 *  @param str 需要截取的字符串
 *
 *  @return 返回的值
 */
+(NSString *)getFloatString:(NSString *)str{
    str = [str substringWithRange:NSMakeRange(0, [str rangeOfString:@"."].location+3)];
    return str;
}


/**
 获取AttributeString
 
 @param str 未处理过的str
 @param attributeDic 需要添加的属性
 @return 返回ttributeString
 */
+(NSAttributedString *)getAttributeString:(NSString *)str strAttributeDic:(NSDictionary *)attributeDic{
    if (str.length == 0) {
        return [[NSMutableAttributedString alloc] initWithString:@""];
    }
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:str];
    [att addAttributes:attributeDic range:NSMakeRange(0, str.length)];
    return att.copy;
}

+(NSAttributedString *)getAttributeString:(NSString *)str dealStr:(NSString *)dealStr strAttributeDic:(NSDictionary *)attributeDic{
    if (str.length == 0 || dealStr.length == 0) {
        return [[NSMutableAttributedString alloc] initWithString:@""];
    }
    NSRange range = [str rangeOfString:dealStr];
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:str];
    [att addAttributes:attributeDic range:range];
    return att.copy;
}

+(NSAttributedString *)addAttributeString:(NSAttributedString *)str dealStr:(NSString *)dealStr strAttributeDic:(NSDictionary *)attributeDic{
    if (str.length == 0) {
        return [[NSMutableAttributedString alloc] initWithString:@""];
    }
    NSRange range = [str.string rangeOfString:dealStr options:NSBackwardsSearch];
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithAttributedString:str];
    [att addAttributes:attributeDic range:range];
    return att.copy;
}

// 获取价格的AttributeString
+(NSAttributedString *)priceLabText:(NSString *)money attributeFont:(float)font{
    
    NSString *str = [NSString stringWithFormat:@"%@ ",NSLocalizedString(@"¥", nil)];
    NSMutableAttributedString *att = [[NSMutableAttributedString alloc] initWithString:str];
    [att appendAttributedString:[NSString getAttributeString:money strAttributeDic:@{NSFontAttributeName :[UIFont systemFontOfSize:font]}]];
    return att.copy;
}

// 获取带有行间距的字符串
+(NSAttributedString *)getParagraphStyleAttributeStr:(NSString *)str lineSpacing:(float)lineSpace{
    
    NSMutableAttributedString * attStr = [[NSMutableAttributedString alloc] initWithString:str];
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineSpace];
    [attStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [attStr length])];
    return attStr.copy;
}

// 获取带有行间距的字符串
+(NSAttributedString *)addParagraphStyleAttributeStrWithAttributeStr:(NSAttributedString *)attStr lineSpacing:(float)lineSpace{
    
    NSMutableAttributedString * attributeStr = [[NSMutableAttributedString alloc] initWithAttributedString:attStr];
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:lineSpace];
    
    [attributeStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [attStr length])];
    return attributeStr.copy;
    
}
//改变图片的尺寸大小
+(UIImage * )scaleFromImage:(UIImage*)img scaledToSize:(CGSize)newSize{
    CGSize imageSize = img.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    if (width <= newSize.width && height <= newSize.height){
        return img;
    }
    if (width == 0 || height == 0){
        return img;
    }
    CGFloat widthFactor = newSize.width / width;
    CGFloat heightFactor = newSize.height / height;
    CGFloat scaleFactor = (widthFactor<heightFactor?widthFactor:heightFactor);
    CGFloat scaledWidth = width * scaleFactor;
    CGFloat scaledHeight = height * scaleFactor;
    CGSize targetSize = CGSizeMake(scaledWidth,scaledHeight);
    UIGraphicsBeginImageContext(targetSize);
    [img drawInRect:CGRectMake(0,0,scaledWidth,scaledHeight)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+(NSString *)getStrFromFloatValue:(float)ft bitCount:(int)bitCount{
    
    int count = 0;
    float p = ft;
    for (NSInteger i=0; i<bitCount; i++) {
        
        p = p - (int)p;
        if (p == 0) {
            if (i == 0) {
                return [NSString stringWithFormat:@"%d",(int)ft];
            }
        }else{
            count++;
        }
        p = p * 10;
        
    }
    
    NSString *str = [NSString stringWithFormat:@"%@.%df",@"%",count];
    return [NSString stringWithFormat:str,ft];
    
}


+(NSString *)getSingleParamFormUrlStr:(NSString *)urlStr param:(NSString *)param{
    
    NSError *error;
    if (!urlStr) {return @"";}
    
    NSString *regTags=[[NSString alloc]initWithFormat:@"(^|&|\\?)+%@=+([^&]*)(&|$)",param];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regTags
                                                                           options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray *matches = [regex matchesInString:urlStr  options:0 range:NSMakeRange(0, [urlStr length])];
    
    for (NSTextCheckingResult *match in matches) {
        NSString *tagValue = [urlStr substringWithRange:[match rangeAtIndex:2]]; //分组2所对应的串
        return tagValue;
    }
    return @"";
}

+(NSDictionary *)getParamsFormUrlStr:(NSString *)urlStr{
    
    if (!urlStr) {return @{};}
    
    NSURLComponents * urlComponents = [NSURLComponents componentsWithString:urlStr];
    
    NSArray *queryItems = [urlComponents queryItems];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in queryItems) {
        dic[item.name] = item.value;
    }
    return dic.copy;
}
@end
