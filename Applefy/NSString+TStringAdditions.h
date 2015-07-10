//
//  NSString+TStringAdditions.h
//  PlayerKit
//
//  Created by Peter MacWhinnie on 9/27/09.
//  Copyright 2009 Roundabout Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus

#import <TagLib/tstring.h>

/*!
 @category
 @abstract	This category adds convenience methods for converting an NSString to and from a TagLib string.
 */
@interface NSString (PKTStringAdditions)

#pragma mark Constructors

/*!
 @method
 @abstract	Returns a string created by copying the data from a given TagLib string object.
 @param		string	The TagLib string whose data we are to copy.
 @result	A string created by copying the data from `string`.
 */
+ (NSString *)stringWithTagLibString:(const TagLib::String)string;

/*!
 @method
 @abstract	Returns an NSString initialized by copying the data from a given TagLib string object.
 @param		string	The TagLib string whose data we are to copy.
 @result	An NSString object initialized by data from `string`. The returned object may be different from the original receiver.
 */
- (id)initWithTagLibString:(const TagLib::String)string;

@end

/*!
 @function
 @abstract	Convert an NSString to a TagLib string taking into account nullness of the passed in string.
 */
extern TagLib::String NSStringToTagLibString(NSString *string);

#else
#	warning "NSString+TagLib::String requires C++."
#endif