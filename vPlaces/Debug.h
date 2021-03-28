//
//  Debug.h
//  Newsletter
//
//  Created by Danis Tazetdinov on 21.02.12.
//  Copyright (c) 2012 Fujitsu Russia GDC. All rights reserved.
//

#ifndef Newsletter_Debug_h
#define Newsletter_Debug_h

#if DEBUG

#define DLog(fmt, ...) NSLog((@"(%@) %s [%d] " fmt), NSStringFromClass([self class]), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#else

#define DLog(...)

#endif

#endif


