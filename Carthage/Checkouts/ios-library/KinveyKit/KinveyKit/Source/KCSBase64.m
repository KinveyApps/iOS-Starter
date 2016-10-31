//
//  KCSBase64.m
//  KinveyKit
//
//  Created by Brian Wilson on 1/17/12.
//

#import "KCSBase64.h"

NSString *KCSbasicAuthString(NSString *username, NSString *password)
{
    NSString *authString    = [NSString stringWithFormat:@"%@:%@", username, password];
    NSString *encodedString = [[authString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    NSString *headerString = [NSString stringWithFormat:@"Basic %@",
                              [encodedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
    return headerString;
}
