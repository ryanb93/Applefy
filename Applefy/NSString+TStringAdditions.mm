//
//  NSString+TStringAdditions.m
//  PlayerKit
//
//  Created by Peter MacWhinnie on 9/27/09.
//  Copyright 2009 Roundabout Software. All rights reserved.
//

#import "NSString+TStringAdditions.h"

@implementation NSString (PKTStringAdditions)

#pragma mark Constructors

+ (NSString *)stringWithTagLibString:(const TagLib::String)string
{
    if(string.isNull())
        return nil;
    
    return [self stringWithUTF8String:string.toCString(true)];
}

- (id)initWithTagLibString:(const TagLib::String)string
{
    if(string.isNull())
        return nil;
    
    return [self initWithUTF8String:string.toCString(true)];
}

@end

#pragma mark -

TagLib::String NSStringToTagLibString(NSString *string)
{
    if(string)
        return TagLib::String([string UTF8String], TagLib::String::UTF8);
    
    return TagLib::String::null;
}