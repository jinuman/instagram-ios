//
//  MainTabBarController.swift
//  MyInstagram
//
//  Created by Jinwoo Kim on 03/03/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

class MainTabBarController: UITabBarController {
    
    // MARK:- Life cycle methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self    // UITabBarControllerDelegate
        
        checkUserIsLoggedIn()
        setupViewControllers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        checkUserIsLoggedIn()
        setupViewControllers()
    }
    
    deinit {
        print("MainTabBarController \(#function)")
    }
    
    // MARK:- Regarding screen methods
    
    // Refresh UI by logged in user.
    func setupViewControllers() {
        // home
        let homeNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "home_unselected"),
                                                      selectedImage: #imageLiteral(resourceName: "home_selected"),
                                                      rootViewController: HomeController(collectionViewLayout: UICollectionViewFlowLayout()))
        // search
        let searchNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "search_unselected"),
                                                        selectedImage: #imageLiteral(resourceName: "search_selected"),
                                                        rootViewController: UserSearchController(collectionViewLayout: UICollectionViewFlowLayout()))
        
        let plusNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "plus_unselected"), selectedImage: #imageLiteral(resourceName: "plus_unselected"))
        
        let likeNavController = templateNavController(unselectedImage: #imageLiteral(resourceName: "like_unselected"), selectedImage: #imageLiteral(resourceName: "like_selected"))
        
        // user profile
        let userProfileController = templateNavController(unselectedImage: #imageLiteral(resourceName: "profile_unselected"),
                                                          selectedImage: #imageLiteral(resourceName: "profile_selected"),
                                                          rootViewController: UserProfileController(collectionViewLayout: UICollectionViewFlowLayout()))
        
        tabBar.tintColor = .black
        
        viewControllers = [
            homeNavController,
            searchNavController,
            plusNavController,
            likeNavController,
            userProfileController
        ]
        
        guard let items = tabBar.items else { return }
        for item in items {
            item.imageInsets = UIEdgeInsets(top: 4, left: 0, bottom: -4, right: 0)
        }
    }
    
    fileprivate func templateNavController(unselectedImage: UIImage,
                                           selectedImage: UIImage,
                                           rootViewController: UIViewController = UIViewController()) -> UINavigationController {
        let viewController = rootViewController
        let navController = UINavigationController(rootViewController: viewController)
        navController.tabBarItem.image = unselectedImage
        navController.tabBarItem.selectedImage = selectedImage
        return navController
    }
    
    // MARK:- Handling methods
    fileprivate func checkUserIsLoggedIn() {
        // if user is not logged in
        if Auth.auth().currentUser == nil {
            DispatchQueue.main.async {
                let signInController = SignInController()
                let navController = UINavigationController(rootViewController: signInController)
                self.present(navController, animated: true, completion: nil)
            }
            return
        }
    }
}

// MARK:- Regarding UITabBarControllerDelegate
extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let index = viewControllers?.firstIndex(of: viewController)
        if index == 2 {
            let layout = UICollectionViewFlowLayout()
            let photoSelectorController = PhotoSelectorController(collectionViewLayout: layout)
            let navController = UINavigationController(rootViewController: photoSelectorController)
            present(navController, animated: true, completion: nil)
            return false
        }
        return true
    }
}
