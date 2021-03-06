//
//  MyProfileViewController.swift
//  MyInstagram
//
//  Created by Jinwoo Kim on 03/03/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import UIKit
import Firebase

class MyProfileViewController: UIViewController {
    
    // MARK: - Properties
    
    // MARK: UI
    
    private lazy var profileCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .white
        
        collectionView.register(
            UserProfileHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: headerId
        )
        
        collectionView.register([
            UserProfilePhotoCell.self,
            HomePostCollectionViewCell.self
        ])
        
        return collectionView
    }()
    
    // MARK: General
    
    private let headerId = "headerId"
    
    private var user: User?
    private var posts = [Post]()
    
    private var isGridView: Bool = true
    var isFinishedPaging: Bool = false
    
    var userId: String?
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.configureLayout()
        
        self.navigationController?.navigationBar.prefersLargeTitles = false
        
        self.fetchUser()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        profileCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    // MARK: - Methods
    
    private func configureLayout() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "gear"),
            style: .plain,
            target: self,
            action: #selector(self.handleSignOut)
        )
        
        self.view.addSubviews([
            self.profileCollectionView
        ])
        
        self.profileCollectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    
    fileprivate func fetchUser() {
        let uid = userId ?? (Auth.auth().currentUser?.uid ?? "")
        
        Database.fetchUser(with: uid) { [weak self] (user) in
            guard let self = self else { return }
            
            self.user = user
            self.navigationItem.title = self.user?.username
            self.profileCollectionView.reloadData()
            
            self.paginatePosts()
        }
    }
    
    fileprivate func paginatePosts() {
        guard let uid = self.user?.uid else { return }
        let ref = Database.database().reference().child("posts").child(uid)
        
//        var query = ref.queryOrderedByKey()
        var query = ref.queryOrdered(byChild: "creationDate")
        
        if !posts.isEmpty {
//            let value = posts.last?.id
            let value = posts.last?.creationDate.timeIntervalSince1970
            query = query.queryEnding(atValue: value)
        }
        
        query.queryLimited(toLast: 4).observeSingleEvent(of: .value, with: { [weak self] (snapshot) in
            guard let self = self else { return }
            
            guard var allObjects = snapshot.children.allObjects as? [DataSnapshot] else { return }
            print(allObjects.count)
            allObjects.reverse()
            
            if allObjects.count < 4 {
                self.isFinishedPaging = true
            }
            
            if !self.posts.isEmpty && !allObjects.isEmpty {
                allObjects.removeFirst()
            }
            
            allObjects.forEach({ (snapshot) in
                guard
                    let dictionary = snapshot.value as? [String : Any],
                    let user = self.user,
                    var post = Post(user: user, dictionary: dictionary) else { return }
                
                post.id = snapshot.key
                
                self.posts.append(post)
            })
            
            self.posts.forEach({ (post) in
                print(post.id ?? "")
            })
            
            self.profileCollectionView.reloadData()
            
        }) { (err) in
            print("Failed to paginate for posts: ", err.localizedDescription)
        }
    }
    
    fileprivate func fetchOrderedPosts() {
        guard let uid = user?.uid else { return }
        
        let ref = Database.database().reference().child("posts").child(uid)
        
        ref.queryOrdered(byChild: "creationDate").observe(.childAdded, with: { [weak self] (snapshot) in
          
            guard
                let self = self,
                let dictionary = snapshot.value as? [String : Any],
                let user = self.user,
                let post = Post(user: user, dictionary: dictionary) else { return }
            
            self.posts.insert(post, at: 0) // insert latest post on the top
            self.profileCollectionView.reloadData()
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @objc private func handleSignOut() {
        let alertController = UIAlertController(title: "Do you want to sign out?", message: nil,
                                                preferredStyle: .actionSheet)
        let signOutAction = UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] (_) in
            guard let self = self else { return }
            do {
                try Auth.auth().signOut()
                
                let signInController = SignInController()
                let navController = UINavigationController(rootViewController: signInController)
                self.present(navController, animated: true, completion: nil)
                
            } catch let signOutErr {
                print("Failed to sign out: \(signOutErr.localizedDescription)")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(signOutAction)
        alertController.addAction(cancelAction)
        alertController.view.addSubview(UIView())  // actionSheet error disappears
        present(alertController, animated: false, completion: nil)
    }
}

// MARK: - Extensions

extension MyProfileViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
}

extension MyProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerId, for: indexPath) as? UserProfileHeader else { fatalError("Failed to cast UserProfileHeader") }
        
        header.user = self.user
        header.delegate = self
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: view.frame.width, height: 200)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // fire off the paginate call
        if indexPath.item == self.posts.count - 1 && isFinishedPaging == false {
            print("Paginating post")
            paginatePosts()
        }
        
        if isGridView {
            
            let cell = collectionView.dequeueReusableCell(
                cellType: UserProfilePhotoCell.self,
                for: indexPath
            )
            cell.post = posts[indexPath.item]
            return cell
            
        } else {
            
            let cell = collectionView.dequeueReusableCell(
                cellType: HomePostCollectionViewCell.self,
                for: indexPath
            )
            cell.post = posts[indexPath.item]
            return cell
        }
       
    }
    
    // 행들 간 간격 return
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    // 행 안에 셀들 간 간격 return
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        if isGridView {
            let width = (view.frame.width - 2) / 3
            return CGSize(width: width, height: width)
        } else {
            
            let width: CGFloat = view.safeAreaLayoutGuide.layoutFrame.width
            var height: CGFloat = 40 + 8 + 8 // userProfileImageView + padding
            height += width
            height += 50  // several buttons field
            height += 60  // caption field
            return CGSize(width: width, height: height)
        }
    }
}

extension MyProfileViewController: UserProfileHeaderDelegate {
    func didChangeToListView() {
        self.isGridView = false
        self.profileCollectionView.reloadData()
    }
    
    func didChangeToGridView() {
        self.isGridView = true
        self.profileCollectionView.reloadData()
    }
}
