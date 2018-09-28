//
//  PagesCollectionView.h
//  PageView
//
//  Created by ALEXEY ABDULIN on 27.09.2018.
//  Copyright © 2018 ALEXEY ABDULIN. All rights reserved.
//

#import <UIKit/UIKit.h>


typedef NS_ENUM( NSInteger, EFOneStepType )
{
    EFOneStepTypeFinite = 0,
    EFOneStepTypeInfinite
};

@class AAPagesCollectionView;
@protocol AAPagesCollectionViewDelegate <NSObject>
    
-(void) PagesCollectionView :(AAPagesCollectionView *)lpCollectionView didChangePage :(NSInteger)iPageNum;
    
@end


@interface AAPagesCollectionView : UICollectionView
    
@property (nonatomic, weak) id<AAPagesCollectionViewDelegate> lpDelegate;
@property (nonatomic) EFOneStepType iType;

@property (nonatomic) NSString * lpType;

-(void) SetObjects :(NSArray *)lpObjects;
-(NSObject *) GetObjectForIndexPath :(NSIndexPath *)lpIndexPath;
-(NSInteger) GetObjectsCount;

@end
