//
//  KCSMemory.h
//  KinveyKit
//
//  Created by Victor Barros on 2015-05-04.
//  Copyright (c) 2015 Kinvey. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "mach/mach.h"

vm_size_t usedMemory(void);
vm_size_t freeMemory(void);
