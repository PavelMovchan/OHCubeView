//
//  OHCubeView.swift
//  CubeController
//
//  Created by Øyvind Hauge on 11/08/16.
//  Copyright © 2016 Oyvind Hauge. All rights reserved.
//
//import DACircularProgress
//import ValueAnimator
import UIKit
import ValueAnimator
@objc public enum ShadowPosition :Int{
    case NOSide = 0
    case Left = 1
    case Right = 2
    case LeftAndRight = 3
}


@available(iOS 9.0, *)
@objc public protocol OHCubeViewDelegate: class {
    @objc optional func cubeViewDidScroll(_ cubeView: OHCubeView, isr:Bool)
    @objc optional func cubeViewDidEndDecelerating(_ cubeView: OHCubeView, noAnyChanges:Bool, prePage:Int)
    @objc optional func cubeViewWillBeginDragging(_ cubeView: OHCubeView)
    @objc optional func cubeViewWillEndDragging(_ cubeView: OHCubeView)
    @objc optional func cubeViewWillResetScroll(_ cubeView: OHCubeView, noAnyChanges:Bool)
}

@available(iOS 9.0, *)
@objc open class OHCubeView: UIScrollView, UIScrollViewDelegate {
    
    @objc weak public var cubeDelegate: OHCubeViewDelegate?;
    @objc public var shadowType:ShadowPosition = ShadowPosition.NOSide;
    @objc public var page:Int = 0;
    @objc public var enableTransform = true;
    
    @objc public var endScrolledWithFinger = false;
    @objc public var isScrolling = false;
    @objc public var forceScrollingEnabled:Bool = false;
    @objc public var animationDuration = 0.3;
    @objc public var frameRate = 60;
    @objc public var prePage = 0;
    fileprivate var lastContentOffset = 0.0;
    fileprivate let maxAngle: CGFloat = 60.0;
    fileprivate var startPoint : CGPoint = CGPoint(x: 0, y: 0);
    fileprivate var startContentOffset : CGFloat = 0;
    fileprivate var isForceScrolling : Bool = false;
    
    fileprivate var isRightScrollDisabled:Bool = false;
    fileprivate var noAnyChangesGlobal:Bool = true;
    
    fileprivate var childViews = [UIView]()
    fileprivate var unscrollableViews = [UIView]()
    fileprivate var unscrollableViewPoints = [NSValue]()
    
    @objc public var stackView: UIStackView = {
        
        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = NSLayoutConstraint.Axis.horizontal
        sv.semanticContentAttribute = .forceLeftToRight
        sv.backgroundColor = UIColor.clear
        return sv
    }()
    
    open override func awakeFromNib() {
        super.awakeFromNib()
        configureScrollView()
    }
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        configureScrollView();
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc open func disableScrollCubeTo3rdView(value:Bool)
    {
        isRightScrollDisabled = value;
    }
    
    @objc open func getDisabledScrollCubeTo3rdView() -> Bool
    {
        return isRightScrollDisabled;
    }
    
    @objc open func clearUnscrollableViews()
    {
        for view in unscrollableViews {
            view.removeFromSuperview()
        }
    }
    
    @objc open func clearViews()
    {
        childViews.removeAll()
        for subUIView in stackView.subviews as [UIView] {
            subUIView.removeFromSuperview()
        }
    }
    
    @objc open func addChildViews(_ views: [UIView]) {
        
        clearViews()
        for view in views {
            view.layer.masksToBounds = true
            stackView.addArrangedSubview(view)
            
            addConstraint(NSLayoutConstraint(
                item: view,
                attribute: NSLayoutConstraint.Attribute.width,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: self,
                attribute: NSLayoutConstraint.Attribute.width,
                multiplier: 1,
                constant: 0)
            )
            childViews.append(view)
        }
    }
    
    @objc open func scrollToViewAtIndex(_ index: Int, animated: Bool, noAnyChanges:Bool, isUserInteraction:Bool) {
        noAnyChangesGlobal = noAnyChanges
        isScrolling = true
        NSLog("logcube 44 scrollToViewAtIndex noAnyChangesGlobal = %i", noAnyChangesGlobal);
        if index > -1 && index < childViews.count {
            
            let width = self.frame.size.width
            let height = self.frame.size.height
            
            let frame = CGRect(x: CGFloat(index)*width, y: self.frame.origin.y, width: width, height: height)//let fr1ame = CGRect(x: CGFloat(index)*width, y: 0, width: width, height: height)
            scrollRectToVisible(frame, animated: animated);
        }
    }
    
    func setScrollRectToVisible(rect: CGRect) {
        scrollRectToVisible(frame, animated: false)
        self.transformViewsInScrollView(self)
    }
    
    @objc open func scrollToViewAtIndexWithDecelerationAnimation(_ index: Int, animated: Bool, noAnyChanges:Bool, isUserInteraction:Bool) {
        noAnyChangesGlobal = noAnyChanges
        NSLog("logcube scrollToViewAtIndexWithDecelerationAnimation noAnyChangesGlobal = %i", noAnyChangesGlobal);
        
        if index > -1 && index < childViews.count {
            
            let width = self.frame.size.width
            let height = self.frame.size.height
            
            let frame = CGRect(x: CGFloat(index)*width, y: self.frame.origin.y, width: width, height: height)
            
            let s = self.contentOffset.x;
            let f = frame.origin.x;
            
            let d = 0.18
            if !isForceScrolling {
                isForceScrolling = true;
                ValueAnimator.frameRate = frameRate
                let animator = ValueAnimator.animate(props: ["some"], from: [s], to: [f], duration: d, onChanged: { (p, v) in
                    self.scrollRectToVisible(CGRect(x: CGFloat(v.value), y: 0, width: width, height: height), animated: false)
                    self.transformViewsInScrollView(self)
                }, onEnd: {
                    self.scrollViewDidEndScrollingAnimation(self)
                    self.isForceScrolling = false;
                })
                
                animator.resume()
            }
           
        }
    }
    
    @objc open func addUnscrollableChildViews(_ views: [UIView], points:[NSValue]) {
        clearUnscrollableViews()
        unscrollableViews = views
        unscrollableViewPoints = points
        for view in unscrollableViews {
            self.addSubview(view)
        }
    }
    
    @objc open func updateOnlyPoints(_ points: [NSValue]) {
        unscrollableViewPoints = points;
        updateUnscrollableViewItems()
    }
    
    
    @objc open func scrollToViewAtIndexWithDecelerationAnimationSlow(_ index: Int, animated: Bool, noAnyChanges:Bool, isUserInteraction:Bool) {
        noAnyChangesGlobal = noAnyChanges
        NSLog("logcube 11 scrollToViewAtIndexWithDecelerationAnimationSlow index = %i noAnyChangesGlobal = %i", index, noAnyChangesGlobal);
        
        if index > -1 && index < childViews.count {
            
            let width = self.frame.size.width
            let height = self.frame.size.height
            
            let frame = CGRect(x: CGFloat(index)*width, y:self.frame.origin.y, width: width, height: height)//CGRect(x: CGFloat(index)*width, y: 0, width: width, height: height)
            
            let s = self.contentOffset.x;
            let f = frame.origin.x;
            
            let d = 0.3
            if !isForceScrolling {
                ValueAnimator.frameRate = frameRate
                isForceScrolling = true
                let animator = ValueAnimator.animate(props: ["some"], from: [s], to: [f], duration: animationDuration, onChanged: { (p, v) in
                    self.scrollRectToVisible(CGRect(x: CGFloat(v.value), y: 0, width: width, height: height), animated: false)
                    self.transformViewsInScrollView(self)
                }, onEnd: {
                    self.scrollViewDidEndScrollingAnimation(self)
                    self.isForceScrolling = false;
                })
                
                animator.resume()
            }
            
        }
    }
    
    @objc open func scrollToViewAtIndexWithDecelerationAnimationSlow(_ index: Int, animated: Bool, noAnyChanges:Bool, isUserInteraction:Bool, withForceScrolling:Bool) {
        noAnyChangesGlobal = noAnyChanges
        forceScrollingEnabled = withForceScrolling;
        NSLog("logcube 11 scrollToViewAtIndexWithDecelerationAnimationSlow index = %i noAnyChangesGlobal = %i", index, noAnyChangesGlobal);
        
        if index > -1 && index < childViews.count {
            
            let width = self.frame.size.width
            let height = self.frame.size.height
            
            let frame = CGRect(x: CGFloat(index)*width, y:self.frame.origin.y, width: width, height: height)//CGRect(x: CGFloat(index)*width, y: 0, width: width, height: height)
            
            let s = self.contentOffset.x;
            let f = frame.origin.x;
            
            let d = 0.3
            if !isForceScrolling {
                isForceScrolling = true
                ValueAnimator.frameRate = frameRate
                let animator = ValueAnimator.animate(props: ["some"], from: [s], to: [f], duration: animationDuration, onChanged: { (p, v) in
                    self.scrollRectToVisible(CGRect(x: CGFloat(v.value), y: 0, width: width, height: height), animated: false)
                    self.transformViewsInScrollView(self)
                }, onEnd: {
                    self.scrollViewDidEndScrollingAnimation(self)
                    self.isForceScrolling = false
                })
                
                animator.resume()
            }
            
           
        }
    }
    
    
    @objc open func scrollToViewAtIndex(_ index: Int, animated: Bool) {
        NSLog("logcube scrollToViewAtIndex start scrolling");
        noAnyChangesGlobal = false
        isScrolling = true
        if index > -1 && index < childViews.count {
            
            let width = self.frame.size.width
            let height = self.frame.size.height
            
            let frame = CGRect(x: CGFloat(index)*width, y: self.frame.origin.y, width: width, height: height)
            scrollRectToVisible(frame, animated: animated);
        }
    }
    
    fileprivate func resetScroll(_ scrollView: UIScrollView)
    {
        var xOffset = scrollView.contentOffset.x
        var svWidth = scrollView.frame.width
        let childc = Int(childViews.count)
        if (xOffset >= svWidth) {
            let width = self.frame.size.width
            let height = self.frame.size.height
            
            let frame = CGRect(x: width, y: self.frame.origin.y, width: width, height: height)
            scrollRectToVisible(frame, animated: false)
            var pageloc:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
            var noAnyChanges:Bool = page == pageloc;
            cubeDelegate?.cubeViewWillResetScroll?(self, noAnyChanges: noAnyChanges);
        }
    }
    
    
    @objc open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        var pageloc:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
        var noAnyChanges:Bool = page == pageloc;
        NSLog("logcube 22 scrollViewDidEndScrollingAnimation1 page = %i, pageloc = %i, noAnyChangesGlobal = %i", page, pageloc, noAnyChangesGlobal);
        page = pageloc;
        var xOffset = scrollView.contentOffset.x
        var svWidth = scrollView.frame.width
        let childc = CGFloat(childViews.count)
        if (xOffset >= (svWidth*(childc-1))) {
            scrollView.contentOffset = CGPoint(x: (svWidth), y: 0)
            page = 1;
        }
        noAnyChangesGlobal = noAnyChanges ? noAnyChanges : noAnyChangesGlobal;
        forceScrollingEnabled = false
        cubeDelegate?.cubeViewDidEndDecelerating?(self, noAnyChanges: noAnyChangesGlobal, prePage: prePage);
        updateUnscrollableViewItems();
        resetAnchorPoint()
        endScrolledWithFinger = false
        isScrolling = false
        prePage = page;
    }
    
    @objc open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        noAnyChangesGlobal = true
        var pageloc:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
        var noAnyChanges:Bool = page == pageloc;
        NSLog("logcube 33 scrollViewDidEndDecelerating1 x = %f width = %f, noAnyChangesGlobal = %i", scrollView.contentOffset.x, scrollView.frame.size.width, noAnyChangesGlobal);
        
        page = pageloc;
        var xOffset = scrollView.contentOffset.x
        var svWidth = scrollView.frame.width
        let childc = CGFloat(childViews.count)
        if (xOffset >= (svWidth*(childc-1))) {
            scrollView.contentOffset = CGPoint(x: (svWidth), y: 0)
            page = 1;
        }
        cubeDelegate?.cubeViewDidEndDecelerating?(self, noAnyChanges: noAnyChanges, prePage: prePage)
        updateUnscrollableViewItems()
        resetAnchorPoint()
        endScrolledWithFinger = false
        isScrolling = false
        prePage = page;
    }
    
    @objc open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        
        var location = self.panGestureRecognizer.location(in: self);
        startPoint = location;
        startContentOffset = contentOffset.x;
        endScrolledWithFinger = true
        cubeDelegate?.cubeViewWillBeginDragging?(self);
    }
    
    @objc open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        cubeDelegate?.cubeViewWillEndDragging?(self);
    }
    @objc open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool){
        cubeDelegate?.cubeViewWillEndDragging?(self);
    }
    
    @objc open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        transformViewsInScrollView(scrollView)
        var isr = self.lastContentOffset > Double(scrollView.contentOffset.x)
        if(!isr && isRightScrollDisabled)
        {
            if(!forceScrollingEnabled)
            {
                resetScroll(scrollView);
            }
        }
        self.lastContentOffset = Double(scrollView.contentOffset.x);
        cubeDelegate?.cubeViewDidScroll?(self, isr: isr);
    }
    
    
    @objc open func resetAnchorPoint()
    {
        let childc = Int(childViews.count)
        for index in 0 ..< childc {
            
            let view = childViews[index]
            view.transform = .identity
            setAnchorPoint(CGPoint(x: 0.5, y: 0.5), forView: view)
        }
    }
    
    // MARK: Private methods
    
    fileprivate func configureScrollView() {
        
        backgroundColor = UIColor.clear
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        isPagingEnabled = true
        bounces = false
        delegate = self
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        addSubview(stackView)
        
        addConstraint(NSLayoutConstraint(
            item: stackView,
            attribute: NSLayoutConstraint.Attribute.leading,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self,
            attribute: NSLayoutConstraint.Attribute.leading,
            multiplier: 1,
            constant: 0)
        )
        
        addConstraint(NSLayoutConstraint(
            item: stackView,
            attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self,
            attribute: NSLayoutConstraint.Attribute.top,
            multiplier: 1,
            constant: 0)
        )
        
        addConstraint(NSLayoutConstraint(
            item: stackView,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self,
            attribute: NSLayoutConstraint.Attribute.height,
            multiplier: 1,
            constant: 0)
        )
        
        addConstraint(NSLayoutConstraint(
            item: stackView,
            attribute: NSLayoutConstraint.Attribute.centerY,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self,
            attribute: NSLayoutConstraint.Attribute.centerY,
            multiplier: 1,
            constant: 0)
        )
        
        addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutConstraint.Attribute.trailing,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: stackView,
            attribute: NSLayoutConstraint.Attribute.trailing,
            multiplier: 1,
            constant: 0)
        )
        
        addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutConstraint.Attribute.bottom,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: stackView,
            attribute: NSLayoutConstraint.Attribute.bottom,
            multiplier: 1,
            constant: 0)
        )
    }
    
    @objc open func updateUnscrollableViewItems()
    {
        var xOffset = self.contentOffset.x
        let len =  unscrollableViews.count
        for i in 0 ..< len {
            let view = unscrollableViews[i]
            let point = unscrollableViewPoints[i].cgPointValue
            view.frame = CGRect(x: point.x + xOffset, y: point.y, width: view.frame.size.width, height: view.frame.size.height);
        }
    }
    
    fileprivate func transformViewsInScrollView(_ scrollView: UIScrollView) {
        updateUnscrollableViewItems()
        if (!enableTransform) {
            return
        }
        
        var xOffset = scrollView.contentOffset.x
        var svWidth = scrollView.frame.width
        let childc = CGFloat(childViews.count)
        
        xOffset = scrollView.contentOffset.x
        svWidth = scrollView.frame.width
        var deg = maxAngle / bounds.size.width * xOffset
        
        for index in 0 ..< childViews.count {
            
            let view = childViews[index]
            
            deg = index == 0 ? deg : deg - maxAngle
            let rad = deg * CGFloat(Double.pi / 180)
            
            var transform = CATransform3DIdentity
            transform.m34 = 1 / svWidth
            transform = CATransform3DRotate(transform, rad, 0, 1, 0)
            
            view.layer.transform = transform
            
            var x = xOffset / svWidth > CGFloat(index) ? 1.0 : 0.0
            
            setAnchorPoint(CGPoint(x: x, y: 0.5), forView: view)
            
            applyShadowForView(view, index: index)
        }
    }
    
    fileprivate func applyShadowForView(_ view: UIView, index: Int) {
        
        let w = self.frame.size.width
        let h = self.frame.size.height
        
        let r1 = frameFor(origin: contentOffset, size: self.frame.size)
        let r2 = frameFor(origin: CGPoint(x: CGFloat(index)*w, y: 0), size: self.frame.size)
        func block() {
            let intersection = r1.intersection(r2)
            let intArea = intersection.size.width*intersection.size.height
            let union = r1.union(r2)
            let unionArea = union.size.width*union.size.height
            let multiplier = 1.0;
            let opac = ((intersection.size.width*0.75) / self.frame.size.width) + 0.25;
            view.layer.opacity = Float(opac);
        }
        
        if shadowType == ShadowPosition.Right {
            if r1.origin.x <= r2.origin.x {
                block();
            }
        }
        else if shadowType == ShadowPosition.Left {
            if r1.origin.x > r2.origin.x {
                block();
            }
        }else if shadowType == ShadowPosition.LeftAndRight {
            block();
        }
    }
    
    
    fileprivate func setAnchorPoint(_ anchorPoint: CGPoint, forView view: UIView) {
        
        var newPoint = CGPoint(x: view.bounds.size.width * anchorPoint.x, y: view.bounds.size.height * anchorPoint.y)
        var oldPoint = CGPoint(x: view.bounds.size.width * view.layer.anchorPoint.x, y: view.bounds.size.height * view.layer.anchorPoint.y)
        
        newPoint = newPoint.applying(view.transform)
        oldPoint = oldPoint.applying(view.transform)
        
        var position = view.layer.position
        position.x -= oldPoint.x
        position.x += newPoint.x
        
        position.y -= oldPoint.y
        position.y += newPoint.y
        
        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
    
    fileprivate func frameFor(origin: CGPoint, size: CGSize) -> CGRect {
        return CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height)
    }
}
