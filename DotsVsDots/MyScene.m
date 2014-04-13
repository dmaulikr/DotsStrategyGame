//
//  MyScene.m
//  DotsVsDots
//
//  Created by baka on 3/23/14.
//  Copyright (c) 2014 baka. All rights reserved.
//

#import "MyScene.h"
#import "CoreData.h"
#import "SKDot.h"

#define DOTS_OFFSET 10
#define MIN_SCALE 0.5
#define MAX_SCALE 3

@interface MyScene()

@property SKNode *camera;
@property CGPoint lastTouchPosition;
@property BOOL itWasTapOnly;
@property SKNode *world;
@property double lastLenBetweenFingers;
@property NSMutableSet *touches;
@property NSMutableArray *dots;
@property long long lastX, lastY;

@end

@implementation MyScene

-(NSUInteger)dotsWidth
{
    return self.dots.count;
}

-(NSUInteger)dotsHeight
{
    NSMutableArray *row = self.dots.firstObject;
    if (!row) {
        return 0;
    }
    return row.count;
}

-(SKDot*)dotsGetX:(NSUInteger)x y:(NSUInteger)y
{
    if ([self dotsWidth] <= x) {
        return nil;
    }
    NSMutableArray *row = self.dots[x];
    if (row.count <= y) {
        return nil;
    }
    return row[y];
}

-(void)dotsSetX:(NSUInteger)x y:(NSUInteger)y node:(SKDot*)node
{
    while ([self dotsWidth] <= x) {
        [self.dots addObject:[NSMutableArray new]];
    }
    NSMutableArray *row = self.dots[x];
    while (row.count <= y) {
        [row addObject:node];
    }
}

-(void)dotsShiftToX:(long long)x y:(long long)y
{
    long long
    shiftX = self.lastX - x,
    shiftY = self.lastY - y;
    if (shiftX == 0 && shiftY == 0) {
        return;
    }
    for (NSUInteger i = 0; i < [self dotsWidth]; i++) {
        for (NSUInteger j = 0; j < [self dotsHeight]; j++) {
            SKDot *node = [self dotsGetX:i y:j];
            long long resultingI = i+shiftX, resultingJ = j+shiftY;
            [node setPointX:[NSNumber numberWithLongLong:resultingI+x-[self dotsWidth]/2]
                          Y:[NSNumber numberWithLongLong:resultingJ+y-[self dotsHeight]/2]];
        }
    }
    self.lastX = x;
    self.lastY = y;
}

-(void)redrawDots
{
    double dotSize    = DOT_SIZE;
    double cameraX = self.camera.position.x;
    double cameraY = self.camera.position.y;
    long long centralNodeX = cameraX / dotSize;
    long long centralNodeY = cameraY / dotSize;
    
    for (NSUInteger i = 0; i < [self dotsWidth]; i++) {
        for (NSUInteger j = 0; j < [self dotsHeight]; j++) {
            SKDot *node = [self dotsGetX:i y:j];
            [node setPointX:[NSNumber numberWithLongLong:i+centralNodeX-[self dotsWidth]/2]
                          Y:[NSNumber numberWithLongLong:j+centralNodeY-[self dotsHeight]/2]];
        }
    }
}

-(void)dotsResizeToX:(NSUInteger)x y:(NSUInteger)y
             centerX:(long long)centerX
             centerY:(long long)centerY
{
    if ([self dotsWidth] == x &&
        [self dotsHeight] == y) {
        return;
    }
    while (x < [self dotsWidth])
    {
        [self.dots.lastObject enumerateObjectsUsingBlock:^(SKDot *dot, NSUInteger idx, BOOL *stop) {
            [dot removeFromParent];
        }];
        [self.dots removeLastObject];
    }
    while (x > [self dotsWidth]) {
        [self.dots addObject:[NSMutableArray new]];
    }
    [self.dots enumerateObjectsUsingBlock:^(NSMutableArray *row, NSUInteger i, BOOL *stop) {
        while (y < row.count)
        {
            SKDot *dot = row.lastObject;
            [dot removeFromParent];
            [row removeLastObject];
        }
        while (y > row.count) {
            SKDot *dot = [[SKDot alloc] init];
            dot.game = self.game;
            dot.theScene = self;
            [self.world addChild:dot];
            [row addObject:dot];
        }
    }];
    [self redrawDots];
}

-(void)createDots
{
    double frameWidth = self.frame.size.width / self.world.xScale;
    double frameHeigh = self.frame.size.height / self.world.yScale;
    double dotSize    = DOT_SIZE;
    double cameraX = self.camera.position.x;
    double cameraY = self.camera.position.y;
    long long centralNodeX = cameraX / dotSize;
    long long centralNodeY = cameraY / dotSize;
    
    [self dotsResizeToX:frameWidth/dotSize+DOTS_OFFSET
                      y:frameHeigh/dotSize+DOTS_OFFSET
                centerX:centralNodeX
                centerY:centralNodeY];
    [self dotsShiftToX:centralNodeX y:centralNodeY];
}

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.touches = [NSMutableSet new];
        self.dots = [NSMutableArray new];
        
        self.anchorPoint = CGPointMake(0.5, 0.5);
        self.world = [SKNode node];
        [self addChild:self.world];
        
        self.camera = [SKNode node];
        self.camera.name = @"camera";
        [self.world addChild:self.camera];
        
        self.backgroundColor = [SKColor whiteColor];
        
        self.game = [DGame newObjectWithContext:[CoreData sharedInstance].mainMOC entity:nil];
        
        [self.world setScale:0.5];

        [self createDots];
    }
    return self;
}

- (void)didSimulatePhysics
{
    [self centerOnNode: [self childNodeWithName: @"//camera"]];
}

- (void) centerOnNode: (SKNode *) node
{
    CGPoint cameraPositionInScene = [node.scene convertPoint:node.position fromNode:node.parent];
    node.parent.position = CGPointMake(node.parent.position.x - cameraPositionInScene.x,                                       node.parent.position.y - cameraPositionInScene.y);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    self.lastTouchPosition = [touch locationInNode:self];
    self.itWasTapOnly = YES;
    self.lastLenBetweenFingers = -1;
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self.touches addObject:obj];
    }];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self.touches enumerateObjectsUsingBlock:^(UITouch *obj, BOOL *stop) {
        if ((obj.phase == UITouchPhaseEnded) ||
            (obj.phase == UITouchPhaseCancelled))
            [self.touches removeObject:obj];
    }];
    if (self.touches.count > 1) {
        double lenBetweenFingers = 0;
        NSArray *touchesArray = [self.touches allObjects];
        for (int i = 0; i < touchesArray.count; i++) {
            for (int j = 0; j < touchesArray.count; j++) {
                if(i==j) continue;
                UITouch *t1 = touchesArray[i];
                UITouch *t2 = touchesArray[j];
                CGPoint t1position = [t1 locationInNode:self];
                CGPoint t2position = [t2 locationInNode:self];
                lenBetweenFingers += sqrt( pow(t1position.x-t2position.x, 2)
                                          +pow(t1position.y-t2position.y, 2));
            }
        }
        lenBetweenFingers /= touches.count;
        if(self.lastLenBetweenFingers > 0)
        {
            double scale = self.world.xScale * lenBetweenFingers / self.lastLenBetweenFingers;
            scale = MAX(scale, MIN_SCALE);
            scale = MIN(scale, MAX_SCALE);
            [self.world setScale:scale];
            [self createDots];
        }
        self.lastLenBetweenFingers = lenBetweenFingers;
    }
    else
    {
        if(self.lastLenBetweenFingers < 0)
        {
            UITouch *touch = [touches anyObject];
            CGPoint oldPosition = self.lastTouchPosition;
            CGPoint newPosition = [touch locationInNode:self];
            self.camera.position = CGPointMake(self.camera.position.x
                                               + (-newPosition.x + oldPosition.x)/self.world.xScale,
                                               self.camera.position.y
                                               + (-newPosition.y + oldPosition.y)/self.world.yScale);
            [self createDots];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.0001 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self redrawDots];
            });
            self.lastTouchPosition = newPosition;
        }
        self.lastLenBetweenFingers = -1;
    }
    self.itWasTapOnly = NO;
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self.touches removeObject:obj];
    }];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        [self.touches removeObject:obj];
    }];

    if(self.itWasTapOnly)
    {
        SKNode *node = [self nodeAtPoint:self.lastTouchPosition];
        if ([node isKindOfClass:[SKDot class]]) {
            SKDot *dotNode = (SKDot*)node;
            [dotNode makeTurn];
        }
        if ([node.parent isKindOfClass:[SKDot class]]) {
            SKDot *dotNode = (SKDot*)node.parent;
            [dotNode makeTurn];
        }
        self.itWasTapOnly = NO;
    }
}

-(void)update:(CFTimeInterval)currentTime {
}

@end
