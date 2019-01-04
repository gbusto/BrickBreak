//
//  OnboardingController.swift
//  Ballz1
//
//  Created by Gabriel Busto on 1/4/19.
//  Copyright © 2019 Self. All rights reserved.
//

import Foundation
import UIKit

class OnboardingController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    private lazy var pages: [UIViewController] = {
        return [
            getViewController(name: "TestPage1"),
            getViewController(name: "TestPage2"),
            getViewController(name: "TestPage3")
        ]
    }()
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: DataSource stubs
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        // Returns view controller before given view controller
        if viewController is TestPage1 {
            return nil
        }
        else if viewController is TestPage2 {
            return self.getViewController(name: "TestPage1")
        }
        
        // If the view controller is TestPage3
        return self.getViewController(name: "TestPage2")
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        // Returns view controller after given view controller
        if viewController is TestPage1 {
            return self.getViewController(name: "TestPage2")
        }
        else if viewController is TestPage2 {
            return self.getViewController(name: "TestPage3")
        }
        
        // If the view controller is TestPage3
        return nil
    }
    
    // MARK: Override functions
    override func viewDidLoad() {
        print("View loaded")
        
        self.delegate = self
        self.dataSource = self
        
        // Set the background color of the dots
        view.backgroundColor = GameMenuColorScheme().backgroundColor
        
        print("Transition style is \(self.transitionStyle.rawValue)")
        
        if let firstVC = pages.first {
            self.setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }

    }
    
    // MARK: Private functions
    private func getViewController(name: String) -> UIViewController {
        if name == "TestPage1" {
            return UIStoryboard(name: "BrickBreak", bundle: nil).instantiateViewController(withIdentifier: name)
        }
        
        else if name == "TestPage2" {
            return UIStoryboard(name: "BrickBreak", bundle: nil).instantiateViewController(withIdentifier: name)
        }
        
        else {
            // TestPage3
            return UIStoryboard(name: "BrickBreak", bundle: nil).instantiateViewController(withIdentifier: name)
        }
    }
}

// MARK: Page view controllers

class TestPage1: UIViewController {
    override func viewDidLoad() {
        print("Loading test page 1")
    }
}

class TestPage2: UIViewController {
    override func viewDidLoad() {
        print("Loading test page 2")
    }
}

class TestPage3: UIViewController {
    override func viewDidLoad() {
        print("Loading test page 3")
    }
}
