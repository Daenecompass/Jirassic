//
//  Conversions.swift
//  Jirassic
//
//  Created by Cristian Baluta on 06/11/2016.
//  Copyright © 2016 Cristian Baluta. All rights reserved.
//

import Foundation

extension Double {
    
    var minToSec: Double {
        return self * 60
    }

    var monthsToSec: Double {
        return self * 30 * 24.hoursToSec
    }

    var hoursToSec: Double {
        return self * 3600
    }
    
    var secToHours: Double {
        return self / 3600
    }
}
