//
//  CVCalendarContentViewController.swift
//  CVCalendar Demo
//
//  Created by Eugene Mozharovsky on 12/04/15.
//  Copyright (c) 2015 GameApp. All rights reserved.
//

import UIKit

public typealias Identifier = String
public class CVCalendarContentViewController: UIViewController {
    // MARK: - Constants
    public let Previous = "Previous"
    public let Presented = "Presented"
    public let Following = "Following"
    
    // MARK: - Public Properties
    public let calendarView: CalendarView
    public let scrollView: UIScrollView
    
    public var presentedMonthView: MonthView
    
    public var bounds: CGRect {
        return CGRectMake(scrollView.bounds.origin.x, scrollView.bounds.origin.y, scrollView.bounds.size.width, scrollView.bounds.size.height/2)
//        return scrollView.bounds
    }
    
    public var currentPage = 1
    public var pageChanged: Bool {
        get {
            return currentPage == 1 ? false : true
        }
    }
    
    public var pageLoadingEnabled = true
    public var presentationEnabled = true
    public var lastContentOffset: CGFloat = 0
    public var direction: CVScrollDirection = .None
    
    public init(calendarView: CalendarView, frame: CGRect) {
        self.calendarView = calendarView
        scrollView = UIScrollView(frame: calendarView.frame)

//        scrollView = UIScrollView(frame: frame)
        
        // Calendar view has same frame as scrollview
        
        print("Calendar view frame: \(calendarView.frame)")
        print("scroll view frame: \(scrollView.frame)")
        
        presentedMonthView = MonthView(calendarView: calendarView, date: NSDate())
        
        
        // Presented month view also uses the same frame
        presentedMonthView.updateAppearance(frame)
        
        super.init(nibName: nil, bundle: nil)
        
        scrollView.contentSize = CGSizeMake(frame.width * 3, calendarView.frame.height)
//        scrollView.contentSize = CGSizeMake(frame.width * 3, frame.height)
        print("scrollview content size: \(scrollView.contentSize)")
//        scrollView.contentSize = CGSizeMake(frame.width * 3, 500)

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.layer.masksToBounds = true
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        
        scrollView.layer.borderWidth = 2
        scrollView.layer.borderColor = UIColor.redColor().CGColor
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UI Refresh

extension CVCalendarContentViewController {
    public func updateFrames(frame: CGRect) {
        if frame != CGRectZero {
            print("scrollview frame: \(scrollView.frame)")

            scrollView.frame = frame
//            scrollView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width * 3, frame.size.height + 200)
            scrollView.removeAllSubviews()
//            scrollView.contentSize = CGSizeMake(frame.size.width * 3, 500)
            scrollView.contentSize = CGSizeMake(frame.size.width * 3, frame.size.height)
        }
        
        calendarView.hidden = false
    }
}

//MARK: - Month Refresh

extension CVCalendarContentViewController {
    public func refreshPresentedMonth() {
        for weekV in presentedMonthView.weekViews {
            for dayView in weekV.dayViews {
                removeCircleLabel(dayView)
                removeDotViews(dayView)
                dayView.preliminarySetup()
                dayView.supplementarySetup()
            }
        }
    }
}


// MARK: Delete circle and dot views (in effect refreshing the dayView circle)

extension CVCalendarContentViewController {
    func removeCircleLabel(dayView: CVCalendarDayView) {
        for each in dayView.subviews {
            if each is UILabel {
                continue
            }
            else if each is CVAuxiliaryView  {
                continue
            }
            else {
                each.removeFromSuperview()
            }
        }
    }
}

//MARK: Delete dot views (in effect refreshing the dayView dots)

extension CVCalendarContentViewController {
    func removeDotViews(dayView: CVCalendarDayView) {
        for each in dayView.subviews {
            if each is CVAuxiliaryView && each.frame.height == 13 {
                each.removeFromSuperview()
            }
        }
    }
}

// MARK: - Abstract methods

/// UIScrollViewDelegate
extension CVCalendarContentViewController: UIScrollViewDelegate { }

/// Convenience API.
extension CVCalendarContentViewController {
    public func performedDayViewSelection(dayView: DayView) { }
    
    public func togglePresentedDate(date: NSDate) { }
    
    public func presentNextView(view: UIView?) { }
    
    public func presentPreviousView(view: UIView?) { }
    
    public func updateDayViews(hidden: Bool) { }
}

// MARK: - Contsant conversion

extension CVCalendarContentViewController {
    public func indexOfIdentifier(identifier: Identifier) -> Int {
        let index: Int
        switch identifier {
        case Previous: index = 0
        case Presented: index = 1
        case Following: index = 2
        default: index = -1
        }
        
        return index
    }
}

// MARK: - Date management

extension CVCalendarContentViewController {
    public func dateBeforeDate(date: NSDate) -> NSDate {
        let components = Manager.componentsForDate(date)
        let calendar = NSCalendar.currentCalendar()
        
        components.month -= 1
        
        let dateBefore = calendar.dateFromComponents(components)!
        
        return dateBefore
    }
    
    public func dateAfterDate(date: NSDate) -> NSDate {
        let components = Manager.componentsForDate(date)
        let calendar = NSCalendar.currentCalendar()
        
        components.month += 1
        
        let dateAfter = calendar.dateFromComponents(components)!
        
        return dateAfter
    }
    
    public func matchedMonths(lhs: Date, _ rhs: Date) -> Bool {
        return lhs.year == rhs.year && lhs.month == rhs.month
    }
    
    public func matchedWeeks(lhs: Date, _ rhs: Date) -> Bool {
        return (lhs.year == rhs.year && lhs.month == rhs.month && lhs.week == rhs.week)
    }
    
    public func matchedDays(lhs: Date, _ rhs: Date) -> Bool {
        return (lhs.year == rhs.year && lhs.month == rhs.month && lhs.day == rhs.day)
    }
}

// MARK: - AutoLayout Management

extension CVCalendarContentViewController {
    private func layoutViews(views: [UIView], toHeight height: CGFloat) {
//        scrollView.frame.size.height = height
        
        var superStack = [UIView]()
        var currentView: UIView = calendarView
        while let currentSuperview = currentView.superview where !(currentSuperview is UIWindow) {
            superStack += [currentSuperview]
            currentView = currentSuperview
        }
        
        for view in views + superStack {
            view.layoutIfNeeded()
        }
    }
    
    public func updateHeight(height: CGFloat, animated: Bool) {
        if calendarView.shouldAnimateResizing {
            var viewsToLayout = [UIView]()
            if let calendarSuperview = calendarView.superview {
                for constraintIn in calendarSuperview.constraints {
                    if let firstItem = constraintIn.firstItem as? UIView, let _ = constraintIn.secondItem as? CalendarView {
                        
                        viewsToLayout.append(firstItem)
                    }
                }
            }
            
            
            for constraintIn in calendarView.constraints where constraintIn.firstAttribute == NSLayoutAttribute.Height {
//                constraintIn.constant = height
                
                if animated {
                    UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
                        self.layoutViews(viewsToLayout, toHeight: height)
                        }) { _ in
                            print("presented month view potential size: \(self.presentedMonthView.potentialSize)")
                            self.presentedMonthView.frame.size = self.presentedMonthView.potentialSize
                            self.presentedMonthView.updateInteractiveView()
                    }
                } else {
                    layoutViews(viewsToLayout, toHeight: height)
                    presentedMonthView.updateInteractiveView()
                    presentedMonthView.frame.size = presentedMonthView.potentialSize
//                    presentedMonthView.frame.size = CGSizeMake(343, 150)
//                    presentedMonthView.clipsToBounds = true
                    print("presented month view potential size: \(self.presentedMonthView.potentialSize)")
                    presentedMonthView.updateInteractiveView()
                }
                
                break
            }
        }
    }
    
    public func updateLayoutIfNeeded() {
        if presentedMonthView.potentialSize.height != scrollView.bounds.height {
            updateHeight(presentedMonthView.potentialSize.height, animated: true)
        } else if presentedMonthView.frame.size != scrollView.frame.size {
            presentedMonthView.frame.size = presentedMonthView.potentialSize
            presentedMonthView.updateInteractiveView()
        }
    }
}

extension UIView {
    public func removeAllSubviews() {
        for subview in subviews {
            subview.removeFromSuperview()
        }
    }
}