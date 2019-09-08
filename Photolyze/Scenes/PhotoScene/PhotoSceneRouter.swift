//
//  PhotoSceneRouter.swift
//  Photolyze
//
//  Created by Mac on 05.09.2019.
//  Copyright (c) 2019 Lammax. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

@objc protocol PhotoSceneRoutingLogic {
    //func routeToSomewhere(segue: UIStoryboardSegue?)
}

protocol PhotoSceneDataPassing {
    var dataStore: PhotoSceneDataStore? { get }
}

class PhotoSceneRouter: NSObject, PhotoSceneRoutingLogic, PhotoSceneDataPassing {
    weak var viewController: PhotoSceneViewController?
    var dataStore: PhotoSceneDataStore?

    // MARK: Routing

    //func routeToSomewhere(segue: UIStoryboardSegue?)
    //{
    //  if let segue = segue {
    //    let destinationVC = segue.destination as! SomewhereViewController
    //    var destinationDS = destinationVC.router!.dataStore!
    //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
    //  } else {
    //    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    //    let destinationVC = storyboard.instantiateViewController(withIdentifier: "SomewhereViewController") as! SomewhereViewController
    //    var destinationDS = destinationVC.router!.dataStore!
    //    passDataToSomewhere(source: dataStore!, destination: &destinationDS)
    //    navigateToSomewhere(source: viewController!, destination: destinationVC)
    //  }
    //}

    // MARK: Navigation

    //func navigateToSomewhere(source: PhotoSceneViewController, destination: SomewhereViewController)
    //{
    //  source.show(destination, sender: nil)
    //}

    // MARK: Passing data

    //func passDataToSomewhere(source: PhotoSceneDataStore, destination: inout SomewhereDataStore)
    //{
    //  destination.name = source.name
    //}
}
