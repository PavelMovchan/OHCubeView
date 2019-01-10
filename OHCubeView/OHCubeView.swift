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
    @objc optional func cubeViewDidEndDecelerating(_ cubeView: OHCubeView, noAnyChanges:Bool, isUserInteraction:Bool, prePage:Int)
    @objc optional func cubeViewWillBeginDragging(_ cubeView: OHCubeView)
}

@available(iOS 9.0, *)
@objc open class OHCubeView: UIScrollView, UIScrollViewDelegate {

    @objc weak public var cubeDelegate: OHCubeViewDelegate?;
    @objc public var shadowType:ShadowPosition = ShadowPosition.NOSide;
    @objc public var animationEnabled:Bool = true;
    @objc public var isScrolling:Bool = false;
    @objc public var isBeginDragging:Bool = false;
    @objc public var page:Int = 0;


    //fileprivate var displayLink:CADisplayLink = CADisplayLink.init();
    fileprivate var lastContentOffset = 0.0;
    fileprivate let maxAngle: CGFloat = 60.0;
    fileprivate var startPoint : CGPoint = CGPoint(x: 0, y: 0);
    fileprivate var startContentOffset : CGFloat = 0;

    fileprivate var isRightScrollDisabled:Bool = false;
    fileprivate var noAnyChangesGlobal:Bool = true;
    @objc public var isUserInteractionGlobal:Bool = false;

    fileprivate var childViews = [UIView]()


    fileprivate lazy var stackView: UIStackView = {

        let sv = UIStackView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.axis = UILayoutConstraintAxis.horizontal
        sv.semanticContentAttribute = .forceLeftToRight
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

    open func disableScrollCubeTo3rdView(value:Bool)
    {
        isRightScrollDisabled = value;
    }

    open func getDisabledScrollCubeTo3rdView() -> Bool
    {
        return isRightScrollDisabled;
    }

    open func clearViews()
    {
        childViews.removeAll()
        for subUIView in stackView.subviews as [UIView] {
            subUIView.removeFromSuperview()
        }
    }

    open func addChildViews(_ views: [UIView]) {

        clearViews()
        for view in views {
            view.layer.masksToBounds = true
            stackView.addArrangedSubview(view)

            addConstraint(NSLayoutConstraint(
                item: view,
                attribute: NSLayoutAttribute.width,
                relatedBy: NSLayoutRelation.equal,
                toItem: self,
                attribute: NSLayoutAttribute.width,
                multiplier: 1,
                constant: 0)
            )
            childViews.append(view)
        }
    }

    open func addChildView(_ view: UIView) {
        addChildViews([view])
    }

    open func scrollToViewAtIndex(_ index: Int, animated: Bool, noAnyChanges:Bool, isUserInteraction:Bool) {
        noAnyChangesGlobal = noAnyChanges
        isUserInteractionGlobal = isUserInteraction
        NSLog("log2 scrollToViewAtIndex noAnyChangesGlobal = %i", noAnyChangesGlobal);
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

    open func scrollToViewAtIndexWithDecelerationAnimation(_ index: Int, animated: Bool, noAnyChanges:Bool, isUserInteraction:Bool) {
        noAnyChangesGlobal = noAnyChanges
        isUserInteractionGlobal = isUserInteraction
        NSLog("log2 scrollToViewAtIndexWithDecelerationAnimation noAnyChangesGlobal = %i", noAnyChangesGlobal);

        isScrolling = true
        isUserInteractionEnabled = false
        if index > -1 && index < childViews.count {

            let width = self.frame.size.width
            let height = self.frame.size.height

            let frame = CGRect(x: CGFloat(index)*width, y: self.frame.origin.y, width: width, height: height)//CGRect(x: CGFloat(index)*width, y: 0, width: width, height: height)

            let s = self.contentOffset.x;
            let f = frame.origin.x;

            let d = 0.18
            ValueAnimator.frameRate = 70
            let animator = ValueAnimator.animate(props: ["some"], from: [s], to: [f], duration: d, onChanged: { (p, v) in
                self.scrollRectToVisible(CGRect(x: CGFloat(v.value), y: 0, width: width, height: height), animated: false)
                self.transformViewsInScrollView(self)
            }, onEnd: {
                self.scrollViewDidEndScrollingAnimation(self)
            })
            
            animator.resume()
        }
    }

    open func scrollToViewAtIndexWithDecelerationAnimationSlow(_ index: Int, animated: Bool, noAnyChanges:Bool, isUserInteraction:Bool) {
        noAnyChangesGlobal = noAnyChanges
        isUserInteractionGlobal = isUserInteraction
        NSLog("log2 scrollToViewAtIndexWithDecelerationAnimation noAnyChangesGlobal = %i", noAnyChangesGlobal);

        isScrolling = true
        isUserInteractionEnabled = false
        if index > -1 && index < childViews.count {

            let width = self.frame.size.width
            let height = self.frame.size.height

            let frame = CGRect(x: CGFloat(index)*width, y:self.frame.origin.y, width: width, height: height)//CGRect(x: CGFloat(index)*width, y: 0, width: width, height: height)

            let s = self.contentOffset.x;
            let f = frame.origin.x;

            let d = 0.4
            ValueAnimator.frameRate = 70
            let animator = ValueAnimator.animate(props: ["some"], from: [s], to: [f], duration: d, onChanged: { (p, v) in
                self.scrollRectToVisible(CGRect(x: CGFloat(v.value), y: 0, width: width, height: height), animated: false)
                self.transformViewsInScrollView(self)
            }, onEnd: {
                self.scrollViewDidEndScrollingAnimation(self)
            })

            animator.resume()
        }
    }


    open func scrollToViewAtIndex(_ index: Int, animated: Bool) {
        NSLog("log16 scrollToViewAtIndex start scrolling");
        isUserInteractionGlobal = false
        noAnyChangesGlobal = false
        if index > -1 && index < childViews.count {

            let width = self.frame.size.width
            let height = self.frame.size.height

            let frame = CGRect(x: CGFloat(index)*width, y: self.frame.origin.y, width: width, height: height)//CGRect(x: CGFloat(index)*width, y: 0, width: width, height: height)
            scrollRectToVisible(frame, animated: animated);
        }
    }

    fileprivate func resetScroll(_ scrollView: UIScrollView)
    {
        var xOffset = scrollView.contentOffset.x
        var svWidth = scrollView.frame.width
        let childc = Int(childViews.count)
        if (xOffset >= svWidth) {
            //NSLog("log16 resetScroll");
            let width = self.frame.size.width
            let height = self.frame.size.height

            let frame = CGRect(x: width, y: self.frame.origin.y, width: width, height: height)//CGRect(x: width, y: 0, width: width, height: height)
            scrollRectToVisible(frame, animated: false)
            //page = 1;
        }
    }


    open func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        var pageloc:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
        var noAnyChanges:Bool = page == pageloc;
        NSLog("log2 scrollViewDidEndScrollingAnimation1 page = %i, pageloc = %i, noAnyChangesGlobal = %i", page, pageloc, noAnyChangesGlobal);
        var prePage = page;
        page = pageloc;
        var xOffset = scrollView.contentOffset.x
        var svWidth = scrollView.frame.width
        let childc = CGFloat(childViews.count)
        if (xOffset >= (svWidth*(childc-1))) {
            scrollView.contentOffset = CGPoint(x: (svWidth), y: 0)
            page = 1;
        }
        noAnyChangesGlobal = noAnyChanges ? noAnyChanges : noAnyChangesGlobal;
        cubeDelegate?.cubeViewDidEndDecelerating?(self, noAnyChanges: noAnyChangesGlobal, isUserInteraction: isUserInteractionGlobal, prePage: prePage);
        resetAnchorPoint()
        isScrolling = false
        isUserInteractionEnabled = true
        isBeginDragging = false
    }

    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        isBeginDragging = false
        noAnyChangesGlobal = true
        var pageloc:Int = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
        var noAnyChanges:Bool = page == pageloc;
        NSLog("log2 scrollViewDidEndDecelerating1 x = %f width = %f, noAnyChangesGlobal = %i", scrollView.contentOffset.x, scrollView.frame.size.width, noAnyChangesGlobal);
        var prePage = page;
        page = pageloc;
        var xOffset = scrollView.contentOffset.x
        var svWidth = scrollView.frame.width
        let childc = CGFloat(childViews.count)
        if (xOffset >= (svWidth*(childc-1))) {
            scrollView.contentOffset = CGPoint(x: (svWidth), y: 0)
            page = 1;
        }
        isUserInteractionGlobal = true
        cubeDelegate?.cubeViewDidEndDecelerating?(self, noAnyChanges: noAnyChanges, isUserInteraction: isUserInteractionGlobal, prePage: prePage)
        resetAnchorPoint()
        isScrolling = false
        isUserInteractionEnabled = true
    }

    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

        var location = self.panGestureRecognizer.location(in: self);//[scrollView.panGestureRecognizer locationInView:scrollView];
        startPoint = location;
        startContentOffset = contentOffset.x;
        isBeginDragging = true
        isUserInteractionGlobal = true
        isScrolling = true
        cubeDelegate?.cubeViewWillBeginDragging?(self);
    }

    open func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {

    }

    open func scrollViewDidScroll(_ scrollView: UIScrollView) {

        //noAnyChangesGlobal = true
        //NSLog("log16 %f", scrollView.contentOffset.x);

        //#warnigng test
        /*var location = self.panGestureRecognizer.location(in: self);//[scrollView.panGestureRecognizer locationInView:scrollView];
        var endcofs = abs(startContentOffset - scrollView.contentOffset.x);
        NSLog("scrollViewWillBeginDragging = %@",NSStringFromCGPoint(location));
        NSLog("scrollViewWillBeginDragging = %@",NSStringFromCGPoint(startPoint));
        var diff:CGFloat = (abs(startPoint.y - location.y) - (abs(startPoint.x - location.x)+endcofs));
        NSLog("scrollViewWillBeginDragging = %f",diff);
        var svWidth = self.frame.width
        if (diff > 0) {
            NSLog("scrollViewWillBeginDragging stop");
            //isScrollEnabled = false
            // isScrollEnabled = true
            resetScroll(scrollView);
        }*/
        //end test

        isScrolling = true
        transformViewsInScrollView(scrollView)
        var isr = false;
        if (self.lastContentOffset > Double(scrollView.contentOffset.x)) {
            isr = true;
        } else if (self.lastContentOffset < Double(scrollView.contentOffset.x)) {
            isr = false;
        }
        if(!isr && isRightScrollDisabled)
        {
            resetScroll(scrollView);
            isScrolling = false
        }else
        {

        }
        self.lastContentOffset = Double(scrollView.contentOffset.x);
        cubeDelegate?.cubeViewDidScroll?(self, isr: isr);
    }


    open func resetAnchorPoint()
    {

        var xOffset = self.contentOffset.x
        var svWidth = self.frame.width
        let childc = Int(childViews.count)

        xOffset = self.contentOffset.x
        svWidth = self.frame.width
        var deg = maxAngle / bounds.size.width * xOffset

        for index in 0 ..< childc {

            let view = childViews[index]
            view.transform = .identity
            setAnchorPoint(CGPoint(x: 0.5, y: 0.5), forView: view)

        }
    }

    // MARK: Private methods

    fileprivate func configureScrollView() {

        backgroundColor = UIColor.black
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        isPagingEnabled = true
        bounces = false
        delegate = self
        //self.semanticContentAttribute = .forceRightToLeft
        if #available(iOS 11.0, *) {
            contentInsetAdjustmentBehavior = .never
        } else {
            // Fallback on earlier versions
        }
        addSubview(stackView)

        addConstraint(NSLayoutConstraint(
            item: stackView,
            attribute: NSLayoutAttribute.leading,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.leading,
            multiplier: 1,
            constant: 0)
        )

        addConstraint(NSLayoutConstraint(
            item: stackView,
            attribute: NSLayoutAttribute.top,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.top,
            multiplier: 1,
            constant: 0)
        )

        addConstraint(NSLayoutConstraint(
            item: stackView,
            attribute: NSLayoutAttribute.height,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.height,
            multiplier: 1,
            constant: 0)
        )

        addConstraint(NSLayoutConstraint(
            item: stackView,
            attribute: NSLayoutAttribute.centerY,
            relatedBy: NSLayoutRelation.equal,
            toItem: self,
            attribute: NSLayoutAttribute.centerY,
            multiplier: 1,
            constant: 0)
        )

        addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.trailing,
            relatedBy: NSLayoutRelation.equal,
            toItem: stackView,
            attribute: NSLayoutAttribute.trailing,
            multiplier: 1,
            constant: 0)
        )

        addConstraint(NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.bottom,
            relatedBy: NSLayoutRelation.equal,
            toItem: stackView,
            attribute: NSLayoutAttribute.bottom,
            multiplier: 1,
            constant: 0)
        )
    }

    fileprivate func transformViewsInScrollView(_ scrollView: UIScrollView) {

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
            transform.m34 = 1 / 500
            transform = CATransform3DRotate(transform, rad, 0, 1, 0)

            view.layer.transform = transform

            var x = xOffset / svWidth > CGFloat(index) ? 1.0 : 0.0
            if(!animationEnabled)
            {
                //x = 0.5
            }

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
            //NSLog("ffff----- %f", Float(opac));
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
