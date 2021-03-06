//
//  PhotoSceneViewController.swift
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
import AVFoundation

protocol PhotoSceneDisplayLogic: class {
    func displaySavePhoto(viewModel: PhotoScene.SavePhoto.ViewModel)
    func displayStorePhoto(viewModel: PhotoScene.StorePhoto.ViewModel)
}

protocol ImageForFilterDelegate {
    var currentFilteredImage: CIImage? { get set }
    func update(with image: CIImage)
}

class PhotoSceneViewController: UIViewController {
    
    // MARK: VARS
    
    var interactor: PhotoSceneBusinessLogic?
    var router: (NSObjectProtocol & PhotoSceneRoutingLogic & PhotoSceneDataPassing)?
    
    var camera: FilteredCamera?
    
    private var cellDelegates: [ImageForFilterDelegate]? = []
    private let syncQueue = DispatchQueue(label: "Store Delegate Sync Queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    let semaphore = DispatchSemaphore(value: 1)
    
    // MARK: CONSTANTS
    
    // MARK: OUTLETS
    
    @IBOutlet weak var takePhotoButton: ResizingButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    // MARK: Object lifecycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    // MARK: Setup
  
    private func setup() {
        PhotoSceneConfigurator.sharedInstance.configure(viewController: self)
    }
  
    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        doOnDidLoad()
    }
    
    // MARK: UI SETUP
    
    private func gestureSetup() {
        let longPressGestureRecognizer: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressGesture))
        longPressGestureRecognizer.minimumPressDuration = 0.2
        self.takePhotoButton.addGestureRecognizer(longPressGestureRecognizer)
    }
    @objc func didLongPressGesture(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            self.takePhotoButton.resize(scaleCoeff: 1.5)
        case .ended:
            self.takePhotoButton.resize(scaleCoeff: 1.0)
        default:
            print("Unsupported state: \(sender.state.rawValue)")
        }
    }
    
    private func collectionSetup() {
        self.collectionView.register(UINib.init(nibName: "FilteredCollectionCell", bundle: nil), forCellWithReuseIdentifier: "filteredCollectionCell")
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
    }
    
    private func cameraSetup() {
        self.camera = FilteredCamera(externalView: self.view)
        self.camera?.delegate = self
    }
    
    private func uiSetup() {
        self.takePhotoButton.configure(frame: self.takePhotoButton.frame, cornerRadius: self.takePhotoButton.layer.cornerRadius)
    }


    // MARK: Do some local logic
    
    private func doOnDidLoad() {
        self.cameraSetup()
        self.gestureSetup()
        self.collectionSetup()
        self.uiSetup()
    }
    
    @IBAction func takePhotoButtonClicked(_ sender: ResizingButton) {
        let request = PhotoScene.SavePhoto.Request()
        self.interactor?.savePhoto(request: request)
    }
    
    //VIPER stuff
    private func storePhoto(image: CIImage?) {
        let request = PhotoScene.StorePhoto.Request(image: image)
        self.interactor?.storePhoto(request: request)
    }
}

extension PhotoSceneViewController: PhotoSceneDisplayLogic {
    func displaySavePhoto(viewModel: PhotoScene.SavePhoto.ViewModel) {
        self.present(viewModel.alertController, animated: true, completion: nil)
    }
    
    func displayStorePhoto(viewModel: PhotoScene.StorePhoto.ViewModel) {
        //smth for display for photo store case
    }
}

extension PhotoSceneViewController: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        syncQueue.sync {
            self.semaphore.wait()
            self.cellDelegates = self.collectionView.visibleCells as? [ImageForFilterDelegate]
            self.semaphore.signal()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cellForFilter = cell as? ImageForFilterDelegate {
            syncQueue.sync {
                self.semaphore.wait()
                self.cellDelegates?.append(cellForFilter)
                self.semaphore.signal()
            }
        }
    }
}
extension PhotoSceneViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Filters.type.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filteredCollectionCell", for: indexPath) as? FilteredCollectionCell else { fatalError("Wrong cell") }
        
        if self.cellDelegates?.count == 0, indexPath[1] == 0 {
            syncQueue.sync {
                self.semaphore.wait()
                self.cellDelegates?.append(cell)
                self.semaphore.signal()
            }
        }
        
        cell.configure(filterName: Filters.type[indexPath[1]])
        

        return cell
    }
}

extension PhotoSceneViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    
}

extension PhotoSceneViewController: FilteredCameraDelegate {
    func filteredCamera(didUpdate image: CIImage) {
        var tempDelegates: [ImageForFilterDelegate]? = []
        syncQueue.sync {
            self.semaphore.wait()
            tempDelegates = self.cellDelegates
            self.semaphore.signal()
        }
        if let delegates = tempDelegates {
            for delegate in delegates {
                delegate.update(with: image)
                self.storePhoto(image: delegate.currentFilteredImage)
            }
        }
    }
}
