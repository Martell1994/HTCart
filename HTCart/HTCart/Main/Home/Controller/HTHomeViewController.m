//
//  HTHomeViewController.m
//  HTCart
//
//  Created by Huiting Mao on 2017/5/27.
//  Copyright © 2017年 Martell. All rights reserved.
//

#import "HTHomeViewController.h"
#import "HTCartViewController.h"
#import "HTCollectionViewCell.h"
#import "HTGoodsModel.h"
#define TAG_BTN 0x1000

@interface HTHomeViewController ()<UICollectionViewDelegate,UICollectionViewDataSource>

@property (nonatomic, strong) UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, strong) UICollectionView *collectionView;

/** 商品列表 */
@property (nonatomic, strong) NSArray *goodsArr;

/** 购物车清单本地存储地址 */
@property (nonatomic, strong) NSString *path;

@end

@implementation HTHomeViewController

static const CGFloat kPadding = 15;             // 同一行 item 之间的间距
static const CGFloat kLinePadding = 10;         // 不同行之间的间距

- (UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.minimumInteritemSpacing = kPadding;
        _flowLayout.minimumLineSpacing = kLinePadding;
        _flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
        CGFloat width = (SCREEN_WIDTH - 10 * 2 - kPadding) / 2;
        _flowLayout.itemSize = CGSizeMake(width, width + 110);
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    }
    return _flowLayout;
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64 - 49) collectionViewLayout:self.flowLayout];
        [self.view addSubview:_collectionView];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.backgroundColor = [UIColor whiteColor];
        _collectionView.showsVerticalScrollIndicator = NO;
        [_collectionView registerClass:[HTCollectionViewCell class] forCellWithReuseIdentifier:@"homeCell"];
    }
    return _collectionView;
}

- (NSArray *)goodsArr {
    if (!_goodsArr) {
        _goodsArr = [HTGoodsModel mj_objectArrayWithFilename:@"goodsList.plist"];
    }
    return _goodsArr;
}

- (NSString *)path {
    if (!_path) {
        _path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:@"cart.plist"];
        NSLog(@"文件路径%@",_path);
    }
    return _path;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"商城";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tabbar_cart_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(gotoCartVC)];
    self.collectionView.hidden = NO;
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.goodsArr.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HTCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"homeCell" forIndexPath:indexPath];
    HTGoodsModel *goodsModel = _goodsArr[indexPath.row];
    cell.imageView.image = [UIImage imageNamed:goodsModel.goods_image];
    cell.priceLabel.text = [NSString stringWithFormat:@"💰%@",goodsModel.current_price];
    cell.buyButton.tag = TAG_BTN + indexPath.row;
    [cell.buyButton addTarget:self action:@selector(addToCart:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

#pragma mark - SEL
- (void)gotoCartVC {
    HTCartViewController *cartVC = [HTCartViewController new];
    cartVC.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:cartVC animated:YES];
}

- (void)addToCart:(UIButton *)button {
    HTGoodsModel *goodsModel = _goodsArr[button.tag - TAG_BTN];
    NSMutableArray *cartArray = [HTPlistTool readPlistArrayWithPath:self.path];
    BOOL hasEqualShop = NO;
    BOOL hasEqualGoods = NO;
    for (NSMutableDictionary *shopDic in cartArray) {
        NSMutableArray *goodsArr = [shopDic valueForKey:@"goods"];
        // 是否有属于相同商铺的商品
        if ([[shopDic valueForKey:@"shop_id"] isEqualToString:goodsModel.shop_id]) {
            for (NSMutableDictionary *goodsDic in goodsArr) {
                if ([[goodsDic valueForKey:@"goods_id"] isEqualToString:goodsModel.goods_id]) {
                    hasEqualGoods = YES;
                    int count = [[goodsDic valueForKey:@"goods_count"] intValue];
                    [goodsDic setValue:@(count + 1) forKey:@"goods_count"];
                }
            }
            if (!hasEqualGoods) {
                NSMutableDictionary *newCartDic = [goodsModel mj_JSONObject];
                [newCartDic setValue:@(1) forKey:@"goods_count"];
                [goodsArr addObject:newCartDic];
            }
            hasEqualShop = YES;
            [HTPlistTool writeDataToPlist:self.path withArr:cartArray];
            NSLog(@"%@",cartArray);
        }
    }
    if (!hasEqualShop) {
        NSMutableArray *goodsArr = [NSMutableArray array];
        NSMutableDictionary *newCartDic = [goodsModel mj_JSONObject];
        [newCartDic setValue:@(1) forKey:@"goods_count"];
        [goodsArr addObject:newCartDic];
        NSMutableDictionary *shopDic = [NSMutableDictionary dictionaryWithDictionary:@{@"shop_id":goodsModel.shop_id,@"shop_name":goodsModel.shop_name,@"goods":goodsArr}];
        [cartArray addObject:shopDic];
        [HTPlistTool writeDataToPlist:self.path withArr:cartArray];
        NSLog(@"%@",cartArray);
    }
    if ([self.delegate respondsToSelector:@selector(refreshCart)]) {
        [self.delegate refreshCart];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
