//
//  RemoteViewsHelper.swift
//  CustomLayoutSample
//  Helper class to initialize remote view size and location
//  Copyright © 2017 Vidyo. All rights reserved.
//


import Foundation

class RemoteViewLayout {
    
    private static var oneTile = [CGRect]()
    private static var twoTiles = [CGRect]()
    private static var threeTiles = [CGRect]()
    private static var fourTiles = [CGRect]()
    
    private static var oneTileL = [CGRect]()
    private static var twoTilesL = [CGRect]()
    private static var threeTilesL = [CGRect]()
    private static var fourTilesL = [CGRect]()
    private static var setupDone = false
    
    static func setup() {
        
        let widthL: CGFloat
        let widthP: CGFloat
        let heightL: CGFloat
        let heightP: CGFloat
        if UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height {
            // landscape mode
            widthL = UIScreen.main.bounds.size.width
            widthP = UIScreen.main.bounds.size.height
            heightL = UIScreen.main.bounds.size.height
            heightP = UIScreen.main.bounds.size.width
        } else {
            // portrait mode
            widthL = UIScreen.main.bounds.size.height
            widthP = UIScreen.main.bounds.size.width
            heightL = UIScreen.main.bounds.size.width
            heightP = UIScreen.main.bounds.size.height
        }
        oneTile.append(CGRect(x: 0, y: 0, width: widthP, height: heightP))
        twoTiles.append(CGRect(x: 0, y: 0, width: widthP, height: heightP/2))
        twoTiles.append(CGRect(x: 0, y: heightP/2, width: widthP, height: heightP/2))
        threeTiles.append(CGRect(x: 0, y: 0, width: widthP, height: heightP/3))
        threeTiles.append(CGRect(x: 0, y: heightP/3, width: widthP, height: heightP/3))
        threeTiles.append(CGRect(x: 0, y: (heightP * 2)/3, width: widthP, height: heightP/3))
        fourTiles.append(CGRect(x: 0, y: 0, width: widthP, height: heightP/3))
        fourTiles.append(CGRect(x: 0, y: heightP/3, width: widthP, height: heightP/3))
        fourTiles.append(CGRect(x: 0, y: (heightP * 2)/3, width: widthP/2, height: heightP/3))
        fourTiles.append(CGRect(x: widthP/2, y: (heightP * 2)/3, width: widthP/2, height: heightP/3))
        
        oneTileL.append(CGRect(x: 0, y: 0, width: widthL, height: heightL))
        twoTilesL.append(CGRect(x: 0, y: 0, width: widthL/2, height: heightL))
        twoTilesL.append(CGRect(x: widthL/2, y: 0, width: widthL/2, height: heightL))
        threeTilesL.append(CGRect(x: 0, y: 0, width: widthL/2, height: heightL/2))
        threeTilesL.append(CGRect(x: widthL/2, y: 0, width: widthL/2, height: heightL/2))
        threeTilesL.append(CGRect(x: widthL/4, y: heightL/2, width: widthL/2, height: heightL/2))
        fourTilesL.append(CGRect(x: 0, y: 0, width: widthL/2, height: heightL/2))
        fourTilesL.append(CGRect(x: widthL/2, y: 0, width: widthL/2, height: heightL/2))
        fourTilesL.append(CGRect(x: 0, y: heightL/2, width: widthL/2, height: heightL/2))
        fourTilesL.append(CGRect(x: widthL/2, y: heightL/2, width: widthL/2, height: heightL/2))
        setupDone = true
    }
    
    static func getTileFrames(numberOfTiles:Int) -> NSMutableArray {
        if setupDone == false {
            self.setup()
        }
        var arrayRect = oneTile
        let orientation = UIDevice.current.orientation
        
        if orientation == .portrait || orientation == .portraitUpsideDown || orientation == .faceUp {
                switch numberOfTiles {
                case 1:
                    arrayRect = oneTile
                case 2:
                    arrayRect = twoTiles
                case 3:
                    arrayRect = threeTiles
                case 4:
                    arrayRect = fourTiles
                default:
                    arrayRect = fourTiles
                }
            } else {
                switch numberOfTiles {
                case 1:
                    arrayRect = oneTileL
                case 2:
                    arrayRect = twoTilesL
                case 3:
                    arrayRect = threeTilesL
                case 4:
                    arrayRect = fourTilesL
                default:
                    arrayRect = fourTilesL
                }
            }
        
        let nsArrayRects:NSMutableArray = NSMutableArray()
        
        for rect in arrayRect {
            nsArrayRects.add(NSValue(cgRect:rect))
        }
        return nsArrayRects
    }
}
