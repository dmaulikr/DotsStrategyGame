//
//  Grid+custom.m
//  DotsVsDots
//
//  Created by baka on 3/23/14.
//  Copyright (c) 2014 baka. All rights reserved.
//

#import "DGrid+custom.h"

@implementation DGrid (custom)

- (BOOL)ourDomain:(DPoint*)point
{
    long long radius = pow(5, self.level.longValue)/2;
    
    long long x1 = self.center.x.longLongValue - radius;
    long long x2 = self.center.x.longLongValue + radius;
    long long y1 = self.center.y.longLongValue - radius;
    long long y2 = self.center.y.longLongValue + radius;
    
    long long x = point.x.longLongValue;
    long long y = point.y.longLongValue;
    
    return (((x1 <= x) && (x <= x2)) &&
            ((y1 <= y) && (y <= y2)));
}

- (DDot*)dotAtPoint:(DPoint*)point lastGrid:(DGrid**)grid
{
    *grid = self;
    if([self ourDomain:point])
    {
        if(self.dot)
        {
            if([self.dot.position equal:point])
            {
                return self.dot;
            }
            else
            {
                return nil;
            }
        }
        else
        {
            if (!self.children) {
                return nil;
            }
            else
            {
                for (DGrid *child in self.children)
                {
                    if([child ourDomain:point])
                        return [child dotAtPoint:point lastGrid:grid];
                }
                // actually shoudn't happen
                return nil;
            }
        }
    }
    else
    {
        if(!self.root)
        {
            return nil;
        }
        return [self.root dotAtPoint:point lastGrid:grid];
    }
}

- (DDot*)createNewDotAtPoint:(DPoint*)point lastGrid:(DGrid**)grid
{
    *grid = self;
    if([self ourDomain:point])
    {
        if(self.dot)
        {
            // we don't test if dot.point == point because we create NEW dot
            // so if we have dot already - then we need to create grid below
            DDot *result;
            for (int i = 0; i < 5; i++) {
                for (int j = 0; j < 5; j++) {
                    DGrid *child = [DGrid new];
                    child.level = [NSNumber numberWithLong:self.level.longValue-1];
                    long long diameter = pow(5, child.level.longValue);
                    DPoint *center = [DPoint new];
                    center.x = [NSNumber numberWithLongLong:self.center.x.longLongValue + diameter*(i-2)];
                    center.y = [NSNumber numberWithLongLong:self.center.y.longLongValue + diameter*(j-2)];
                    child.center = center;
                    child.root = self;
                    if([child ourDomain:point])
                    {
                        result = [child createNewDotAtPoint:point lastGrid:grid];
                    }
                }
            }
            return result;
        }
        else
        {
            self.dot = [DDot new];
            return self.dot;
        }
    }
    else
    {
        if(!self.root)
        {
            DGrid *root = [DGrid new];
            root.level = [NSNumber numberWithLong:self.level.longValue+1];
            root.center = self.center;
            for (int i = 0; i < 5; i++) {
                for (int j = 0; j < 5; j++) {
                    if(i==2 && j==2)
                    {
                        self.root = root;
                    }
                    else
                    {
                        DGrid *child = [DGrid new];
                        child.level = self.level;
                        long long diameter = pow(5, child.level.longValue);
                        DPoint *center = [DPoint new];
                        center.x = [NSNumber numberWithLongLong:root.center.x.longLongValue + diameter*(i-2)];
                        center.y = [NSNumber numberWithLongLong:root.center.y.longLongValue + diameter*(j-2)];
                        child.center = center;
                        child.root = root;
                    }
                }
            }
        }
        return [self.root createNewDotAtPoint:point lastGrid:grid];
    }
}

- (DDot*)getOrCreateDotAtPoint:(DPoint*)point lastGrid:(DGrid**)grid
{
    DDot *dot = [self dotAtPoint:point lastGrid:grid];
    if (dot)
    {
        return dot;
    }
    else
    {
        return [self createNewDotAtPoint:point lastGrid:grid];
    }
}

@end