//
//  UIViewControllerStoryboard.swift
//  Jirassic
//
//  Created by Cristian Baluta on 02/05/16.
//  Copyright © 2016 Cristian Baluta. All rights reserved.
//

#if os(iOS)
    import UIKit
    typealias ViewController = UIViewController
#else
    import Cocoa
    typealias ViewController = NSViewController
#endif

extension ViewController {
    
    class func instantiateFromStoryboard (_ name: String) -> Self {
        return  instantiateFromStoryboard(name, type: self)
    }
    
    fileprivate class func instantiateFromStoryboard<T> (_ name: String, type: T.Type) -> T {
        #if os(iOS)
            return UIStoryboard(name: name, bundle: nil).instantiateViewControllerWithIdentifier(self.className) as! T
        #else
            return NSStoryboard(name: NSStoryboard.Name(rawValue: name), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: String(describing: self))) as! T
        #endif
    }
}
