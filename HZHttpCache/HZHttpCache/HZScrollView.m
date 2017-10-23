//
//  HZScrollView.m
//  HZHttpCache
//
//  Created by 韩志峰 on 2017/10/23.
//  Copyright © 2017年 韩志峰. All rights reserved.
//

#import "HZScrollView.h"

@interface HZScrollView ()<UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView  *scrollView;
@property (nonatomic, strong) UIImageView  *middleView;
@property (nonatomic, strong) UIImageView  *leftView;
@property (nonatomic, strong) UIImageView  *rightView;
@property (nonatomic, strong) NSTimer  *timer;
@property (nonatomic, strong) UIPageControl  *pageControll;
@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, assign) NSInteger count;

@end


@implementation HZScrollView
static const int viewNumber = 3;
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _currentIndex = 0;
    }
    return self;
}
- (void)setImageArray:(NSArray *)imageArray{
    _imageArray = imageArray;
    _count = imageArray.count;
    [self createScrollView];
    [self createTimer];
    [self createPageControl];
}
- (void)createScrollView{
    _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    _scrollView.delegate = self;
    _scrollView.bounces = NO;
    _scrollView.pagingEnabled = YES;
    _scrollView.showsVerticalScrollIndicator = NO;
    _scrollView.showsHorizontalScrollIndicator = NO;
    _scrollView.backgroundColor = [UIColor redColor];
    _scrollView.contentSize = CGSizeMake(viewNumber * self.bounds.size.width, self.bounds.size.height);
    [self addSubview:_scrollView];
    _leftView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
    _leftView.image = [UIImage imageNamed:_imageArray[_count - 1]];
    _middleView = [[UIImageView alloc] initWithFrame:CGRectMake(self.bounds.size.width, 0, self.bounds.size.width, self.bounds.size.height)];
    _middleView.image = [UIImage imageNamed:_imageArray[0]];
    _rightView = [[UIImageView alloc] initWithFrame:CGRectMake( 2 * self.bounds.size.width, 0, self.bounds.size.width, self.bounds.size.height)];
    _leftView.image = [UIImage imageNamed:_imageArray[1]];
    [_scrollView addSubview:_leftView];
    [_scrollView addSubview:_middleView];
    [_scrollView addSubview:_rightView];
    _scrollView.contentOffset = CGPointMake(self.bounds.size.width, 0);
    
}
- (void)createPageControl{
    CGFloat pageControlHeight = 20.f;
    CGFloat pageControlWidth = 80.f;
    _pageControll = [[UIPageControl alloc] initWithFrame:CGRectMake(20.f, self.frame.size.height-pageControlHeight, pageControlWidth, pageControlHeight)];
    _pageControll.numberOfPages = _count;
    _pageControll.currentPageIndicatorTintColor = [UIColor redColor];
    _pageControll.currentPage = 0.f;
    [self addSubview:_pageControll];
    
}
- (void)createTimer{
    __weak typeof(self) weakSelf = self;
    _timer = [NSTimer timerWithTimeInterval:2.f repeats:YES block:^(NSTimer * _Nonnull timer) {
        [weakSelf fireAction];
    }];
    [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}
- (void)fireAction{
    [_scrollView scrollRectToVisible:CGRectMake(2 * self.bounds.size.width, 0, self.bounds.size.width, self.bounds.size.height) animated:YES];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    //准备拖动的时候，定时器失效
    [self invalidateTimer];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    //停止拖动的时候，定时器生效
    [self createTimer];
}
- (void)invalidateTimer{
    [_timer invalidate];
    _timer = nil;
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.x == 2 * self.bounds.size.width) {//滑动到最右边
        _currentIndex ++;
        [self resetImages];
    }else if (scrollView.contentOffset.x == 0){//滑动到最左边的时候
        _currentIndex = _currentIndex + _count;
        _currentIndex --;
        [self resetImages];
    }
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (scrollView.contentOffset.x == 2*self.frame.size.width) {
        //滑动到最右边的时候
        _currentIndex ++;
        //重置图片内容、修改偏移量
        [self resetImages];
    }
}
//重置图片内容修改偏移量
- (void)resetImages{
    _leftView.image = [UIImage imageNamed:_imageArray[(_currentIndex-1)%_count]];
    _middleView.image = [UIImage imageNamed:_imageArray[(_currentIndex)%_count]];
    _rightView.image = [UIImage imageNamed:_imageArray[(_currentIndex+1)%_count]];
    _scrollView.contentOffset = CGPointMake(self.frame.size.width, 0.f);
}
@end
