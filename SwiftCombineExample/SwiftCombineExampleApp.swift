//
//  SwiftCombineExampleApp.swift
//  SwiftCombineExample
//
//  Created by Chris Brooks on 5/28/21.
//

import SwiftUI

@main
struct SwiftCombineExampleApp: App {
    var body: some Scene {
        WindowGroup {
            MovieCollectionView(movieViewModel: MovieCollectionViewModel())
        }
    }
}
