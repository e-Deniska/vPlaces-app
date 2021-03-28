//
//  VPLInfoCell.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 22.03.14.
//  Copyright (c) 2014 Danis Tazetdinov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VPLInfoCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *details;

@property (nonatomic, assign) float downloadProgress;
@property (nonatomic, assign) BOOL progressHidden;

@property (nonatomic, copy) NSString *placeIdentifier;

@end
