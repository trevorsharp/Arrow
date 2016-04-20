//
//  ThingFields.h
//  KiiSDK-Private
//
//  Created by Syah Riza on 12/16/14.
//  Copyright (c) 2014 Kii Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KiiBaseObject.h"

/**Represent fields of thing on KiiCloud.
 */
@interface KiiThingFields : KiiBaseObject

/**Set and get firmwareVersion.
 */
@property(nonatomic, strong) NSString* firmwareVersion;

/**Set and get productName.
 */
@property(nonatomic, strong) NSString* productName;

/**Set and get the lot.
 */
@property(nonatomic, strong) NSString* lot;

/**Set and get the stringField1.
 */
@property(nonatomic, strong) NSString* stringField1;

/**Set and get the stringField2.
 */
@property(nonatomic, strong) NSString* stringField2;

/**Set and get the stringField3.
 */
@property(nonatomic, strong) NSString* stringField3;

/**Set and get the stringField4.
 */
@property(nonatomic, strong) NSString* stringField4;

/**Set and get the stringField5.
 */
@property(nonatomic, strong) NSString* stringField5;

/**Set and get the numberField1.
 */
@property(nonatomic, strong) NSNumber* numberField1;

/**Set and get the numberField2.
 */
@property(nonatomic, strong) NSNumber* numberField2;

/**Set and get the numberField3.
 */
@property(nonatomic, strong) NSNumber* numberField3;

/**Set and get the numberField4.
 */
@property(nonatomic, strong) NSNumber* numberField4;

/**Set and get the numberField5.
 */
@property(nonatomic, strong) NSNumber* numberField5;

/**Set and get vendor.
 */
@property(nonatomic, strong) NSString* vendor;


@end
