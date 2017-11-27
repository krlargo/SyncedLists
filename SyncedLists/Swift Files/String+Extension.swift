//
//  String+Extension.swift
//  SyncedLists
//
//  Created by Kevin Largo on 11/26/17.
//  Copyright © 2017 Kevin Largo. All rights reserved.
//

import Foundation

extension String {
    var isAlphanumeric: Bool {
        return !isEmpty && range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil
    }
}
