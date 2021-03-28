//
//  VPLPlaceCell.h
//  vPlaces
//
//  Created by Danis Tazetdinov on 13.11.13.
//  Copyright (c) 2013 Danis Tazetdinov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VPLPlaceCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *backgroundImage;
@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *details;

@property (nonatomic, assign) BOOL selectionMarkHidden;
@property (nonatomic, assign) BOOL marked;


@end
