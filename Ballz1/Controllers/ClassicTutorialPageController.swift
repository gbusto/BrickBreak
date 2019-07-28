//
//  ClassTutorialPageController.swift
//  Ballz1
//
//  Created by Gabriel Busto on 7/28/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import UIKit

class ClassicTutorialPageController: UIPageViewController, UIPageViewControllerDataSource {
    
    // Returns the view controllers in order for classic tutorial/onboarding
    private(set) lazy var orderedViewControllers: [UIViewController] = {
        return [newClassicTutorialViewController(storyboardId: "ClassicTutorial1"),
                newClassicTutorialViewController(storyboardId: "ClassicTutorial2"),
                newClassicTutorialViewController(storyboardId: "ClassicTutorial3")
        ]
    }()
    
    // Returns the view controller with the specified storyboardID
    private func newClassicTutorialViewController(storyboardId: String) -> UIViewController {
        return UIStoryboard(name: "BrickBreak", bundle: nil).instantiateViewController(withIdentifier: storyboardId)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        
        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    // Data source function to show the previous view controller in the list
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let prevIndex = viewControllerIndex - 1
        
        guard prevIndex >= 0 else {
            return nil
        }
        
        return orderedViewControllers[prevIndex]
    }
    
    // Data source function to show the next view controller in the list
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        guard nextIndex <= orderedViewControllers.count - 1 else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }
    
    // Data source function to show the number of view controllers (to know how many dots to create)
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return orderedViewControllers.count
    }
    
    // This seems to work, so not sure what it's actually supposed to do..
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
}
