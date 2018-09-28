//
//  PagesCollectionView.m
//  PageView
//
//  Created by ALEXEY ABDULIN on 27.09.2018.
//  Copyright © 2018 ALEXEY ABDULIN. All rights reserved.
//

#import "AAPagesCollectionView.h"


#define BIND_WEAK __weak typeof( self ) lpWeakSelf = self
#define CHECK_WEAK \
if( !lpWeakSelf ) \
return;

@interface AAPagesCollectionView () <UICollectionViewDelegate, UIScrollViewDelegate>
{
    __weak id<UICollectionViewDelegate> lpProxiedDelegate;
    
    CGPoint rStartOffset;
    CGFloat fOffsetDX;
    NSArray * lpObjects;
}

@end


@implementation AAPagesCollectionView
    
    
@synthesize lpDelegate, iType;

-(id) initWithCoder :(NSCoder *)aDecoder
{
    self = [super initWithCoder :aDecoder];
    
    if( self )
    {
        [self InitData];
    }
    
    return self;
}

-(id) initWithFrame :(CGRect)frame
{
    self = [super initWithFrame :frame];
    
    if( self )
    {
        [self InitData];
    }
    
    return self;
}

-(id) initWithFrame :(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame :frame collectionViewLayout :layout];
    
    if( self )
    {
        [self InitData];
    }
    
    return self;
}


-(void) InitData
{
    super.delegate = self;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
}

-(NSArray *) GetVisibleSorted
{
    NSArray * lpIndeces = [[self indexPathsForVisibleItems] sortedArrayUsingComparator :^NSComparisonResult( id  _Nonnull obj1, id  _Nonnull obj2 )
                           {
                               NSIndexPath * lpPath1 = obj1;
                               NSIndexPath * lpPath2 = obj2;
                               
                               return [lpPath1 compare :lpPath2];
                           }];
    
    return lpIndeces;
}

-(void) GoToNearCell
{
    NSArray * lpIndeces = [self GetVisibleSorted];
    NSIndexPath * lpGoToPath;
    if( lpIndeces.count > 1 )
    {
        if( fOffsetDX >= 0.0 )
        {
            if( fOffsetDX >= 50.0 )
            lpGoToPath = [lpIndeces objectAtIndex :1];
            else
            lpGoToPath = [lpIndeces firstObject];
        }
        else
        {
            if( fOffsetDX <= -50.0 )
            lpGoToPath = [lpIndeces firstObject];
            else
            lpGoToPath = [lpIndeces objectAtIndex :1];
        }
        
        if( !lpGoToPath )
        lpGoToPath = [lpIndeces firstObject];
    }
    else
    lpGoToPath = [lpIndeces firstObject];
    
    if( lpGoToPath )
    {
        BIND_WEAK;
        dispatch_async( dispatch_get_main_queue(), ^
                       {
                           CHECK_WEAK;
                           
                           [lpWeakSelf scrollToItemAtIndexPath :lpGoToPath atScrollPosition :UICollectionViewScrollPositionCenteredHorizontally animated :YES];
                       });
        
        NSInteger iPage = 0;
        switch( iType )
        {
            case EFOneStepTypeFinite:
            iPage = lpGoToPath.item;
            break;
            
            case EFOneStepTypeInfinite:
            iPage = lpGoToPath.item + ((lpObjects.count == 1) ? 0 : -1);
            break;
        }
        
        [lpDelegate PagesCollectionView :self didChangePage :iPage];
    }
}

-(void) SetObjects :(NSArray *)lpObjects_
{
    NSInteger iStart = 0;
    if( lpObjects_.count == 0 )
    lpObjects = @[];
    else if( (lpObjects_.count == 1) || (iType == EFOneStepTypeFinite) )
    lpObjects = lpObjects_;
    else
    {
        iStart = 1;
        NSMutableArray * lpNewObjects = [[NSMutableArray alloc] initWithCapacity :lpObjects_.count + 2];
        [lpNewObjects addObject :[lpObjects_ lastObject]];
        [lpNewObjects addObjectsFromArray :lpObjects_];
        [lpNewObjects addObject :[lpObjects_ firstObject]];
        lpObjects = lpNewObjects;
    }
    
    [self reloadData];
    if( (lpObjects.count != 0) && (iType == EFOneStepTypeInfinite) )
    {
        BIND_WEAK;
        dispatch_async( dispatch_get_main_queue(), ^
                       {
                           CHECK_WEAK;
                           
                           [lpWeakSelf scrollToItemAtIndexPath :[NSIndexPath indexPathForItem :iStart inSection :0] atScrollPosition :UICollectionViewScrollPositionCenteredHorizontally animated :NO];
                       });
    }
    
}

-(NSObject *) GetObjectForIndexPath :(NSIndexPath *)lpIndexPath
{
    return [lpObjects objectAtIndex :lpIndexPath.item];
}

-(NSInteger) GetObjectsCount
{
    return lpObjects.count;
}

#pragma mark - Proxy configure

-(NSMethodSignature *) methodSignatureForSelector :(SEL)lpSelector
{
    if( [super respondsToSelector :lpSelector] )
    return [super methodSignatureForSelector :lpSelector];
    
    if( [lpProxiedDelegate respondsToSelector :lpSelector] )
    {
        NSObject * lpObj = lpProxiedDelegate;
        return [lpObj methodSignatureForSelector :lpSelector];
    }
    
    return nil;
}

-(void) forwardInvocation :(NSInvocation *)lpInvocation
{
    if( [super respondsToSelector :lpInvocation.selector] )
    [lpInvocation invokeWithTarget :self];
    
    if( [lpProxiedDelegate respondsToSelector :lpInvocation.selector] )
    [lpInvocation invokeWithTarget :lpProxiedDelegate];
}

-(BOOL) respondsToSelector :(SEL)selector
{
    // Add the delegate to the autorelease pool, so it doesn't get deallocated
    // between this method call and -forwardInvocation:.
    __autoreleasing id delegate = lpProxiedDelegate;
    if( [delegate respondsToSelector :selector] )
    return YES;
    
    return [super respondsToSelector :selector];
}

#pragma mark - UIScrollViewDelegate

-(void) scrollViewDidScroll :(UIScrollView *)lpScrollView
{
    fOffsetDX = lpScrollView.contentOffset.x - rStartOffset.x;
}

-(void) scrollViewWillBeginDragging :(UIScrollView *)lpScrollView
{
    rStartOffset = lpScrollView.contentOffset;
}

- (void)scrollViewDidEndDragging :(UIScrollView *)lpScrollView willDecelerate :(BOOL)decelerate
{
    if( !decelerate )
    [self GoToNearCell];
}

-(void) scrollViewWillBeginDecelerating :(UIScrollView *)lpScrollView
{
    [self GoToNearCell];
}

-(void) scrollViewDidEndScrollingAnimation :(UIScrollView *)lpScrollView
{
    if( iType == EFOneStepTypeFinite )
    return;
    
    NSArray * lpSortedArr = [self GetVisibleSorted];
    if( lpObjects.count > 1 )
    {
        NSIndexPath * lpPath = [lpSortedArr firstObject];
        if( lpPath.item == 0 )
        {
            [self scrollToItemAtIndexPath :[NSIndexPath indexPathForItem :lpObjects.count - 2 inSection :0] atScrollPosition :UICollectionViewScrollPositionCenteredHorizontally animated :NO];
            [lpDelegate PagesCollectionView :self didChangePage :lpObjects.count - 3];
        }
        else
        {
            lpPath = [lpSortedArr lastObject];
            if( lpPath.item == lpObjects.count - 1 )
            {
                BIND_WEAK;
                dispatch_async( dispatch_get_main_queue(), ^
                               {
                                   CHECK_WEAK;
                                   
                                   [lpWeakSelf scrollToItemAtIndexPath :[NSIndexPath indexPathForItem :1 inSection :0] atScrollPosition :UICollectionViewScrollPositionCenteredHorizontally animated :NO];
                               });
                
                [lpDelegate PagesCollectionView :self didChangePage :0];
            }
        }
    }
}

#pragma mark - Properties

-(void) setLpType :(NSString *)lpType
{
    if( [lpType isEqualToString :@"finite"] )
        iType = EFOneStepTypeFinite;
    else if( [lpType isEqualToString :@"infinite"] )
        iType = EFOneStepTypeInfinite;
}

-(NSString *) lpType
{
    return nil;
}

-(BOOL) isProxy
{
    return YES;
}

-(void) setDelegate :(id<UICollectionViewDelegate>)lpDelegate_
{
    lpProxiedDelegate = lpDelegate_;
}

@end
