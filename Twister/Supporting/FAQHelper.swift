//
//  FAQHelper.swift
//  Twister
//
//  Created by Matteo Bart on 4/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit

// MARK: FAQItem
public struct FAQItem {
    public let question: String
    public let answer: String?
    public let attributedAnswer: NSAttributedString?

    public init(question: String, answer: String) {
        self.question = question
        self.answer = answer
        self.attributedAnswer = nil
    }

    public init(question: String, attributedAnswer: NSAttributedString) {
        self.question = question
        self.attributedAnswer = attributedAnswer
        self.answer = nil
    }

    public init(question: String, partiallyAttributed: NSMutableAttributedString) {
        self.question = question
        self.answer = nil
        let config = FAQConfiguration()
        let range = NSRange(location: 0, length: partiallyAttributed.length)
        partiallyAttributed.addAttribute(.foregroundColor, value: config.answerTextColor as Any, range: range)
        partiallyAttributed.addAttribute(.font, value: config.answerTextFont as Any, range: range)
        self.attributedAnswer = partiallyAttributed
    }
}

// MARK: FAQConfiguration
public class FAQConfiguration {
    public var questionTextColor: UIColor?
    public var answerTextColor: UIColor?
    public var questionTextFont: UIFont?
    public var answerTextFont: UIFont?
    public var titleTextColor: UIColor?
    public var titleTextFont: UIFont?
    public var viewBackgroundColor: UIColor?
    public var cellBackgroundColor: UIColor?
    public var separatorColor: UIColor?
    public var titleLabelBackgroundColor: UIColor?
    public var dataDetectorTypes: UIDataDetectorTypes?
    public var tintColor: UIColor?
    public var indicatorColor: UIColor?

    init() {
        defaultValue()
    }

    func defaultValue() {
        self.questionTextColor = UIColor.label
        self.answerTextColor = UIColor.label
        self.questionTextFont = UIFont(name: "HelveticaNeue-Bold", size: 16)
        self.answerTextFont = UIFont(name: "HelveticaNeue-Light", size: 15)
        self.titleTextColor = UIColor.label
        self.titleTextFont = UIFont(name: "HelveticaNeue-Light", size: 20)
        self.titleLabelBackgroundColor = UIColor.clear
        self.viewBackgroundColor = UIColor.systemBackground
        self.cellBackgroundColor = UIColor.systemBackground
        self.separatorColor = UIColor.systemFill
        self.indicatorColor = UIColor.label
    }
}

// MARK: FAQViewCell
class FAQViewCell: UITableViewCell {
    // MARK: Internal Properties
    var questionLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()
    var answerTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = UIColor.clear
        textView.isScrollEnabled = false
        textView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        textView.isEditable = false
        textView.dataDetectorTypes = []
        return textView
    }()
    var indicatorImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        let indicatorImage = UIImage.init(systemName: "triangle")
        //let indicatorImage = UIImage(named: "DownArrow", in: Bundle(for: FAQView.self), compatibleWith: nil)
        imageView.image = indicatorImage?.withRenderingMode(.alwaysTemplate)
        return imageView
    }()
    var answerTextViewBottom = NSLayoutConstraint()
    var configuration: FAQConfiguration! {
        didSet {
            setup(with: configuration)
        }
    }
    var didSelectQuestion: ((_ cell: FAQViewCell) -> Void)?
    // MARK: Private Properties
    private let actionByQuestionTap = #selector(didTapQuestion)
    private var containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    // MARK: Initialization
    #if swift(>=4.2)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewSetup()
    }
    #else
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        viewSetup()
    }
    #endif

    private func viewSetup() {
        selectionSetup()
        self.containerView.addSubview(indicatorImageView)
        contentView.addSubview(questionLabel)
        contentView.addSubview(answerTextView)
        contentView.addSubview(containerView)
        addLabelConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func configure(currentItem: FAQItem, indexPath: IndexPath, cellOperation: CellOperation) {
        questionLabel.text = currentItem.question
        switch cellOperation {
        case .collapsed:
            collapse(animated: false)
        case .expand:
            if let answer = currentItem.answer {
                expand(withAnswer: answer, animated: true)
            } else if let attributedAnswer = currentItem.attributedAnswer {
                expand(withAttributedAnswer: attributedAnswer, animated: true)
            }
        case .collapse:
            collapse(animated: true)
        case .expanded:
            if let answer = currentItem.answer {
                expand(withAnswer: answer, animated: false)
            } else if let attributedAnswer = currentItem.attributedAnswer {
                expand(withAttributedAnswer: attributedAnswer, animated: false)
            }
        }
    }
    // MARK: Private Methods
    private func selectionSetup() {
        questionLabel.isUserInteractionEnabled = true
        indicatorImageView.isUserInteractionEnabled = true
        let questionLabelGestureRecognizer = UITapGestureRecognizer(target: self, action: actionByQuestionTap)
        questionLabel.addGestureRecognizer(questionLabelGestureRecognizer)
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: actionByQuestionTap)
        indicatorImageView.addGestureRecognizer(imageGestureRecognizer)
    }
    private func setup(with configuration: FAQConfiguration) {
        self.backgroundColor = configuration.cellBackgroundColor
        self.questionLabel.textColor = configuration.questionTextColor
        self.answerTextView.textColor = configuration.answerTextColor
        self.questionLabel.font = configuration.questionTextFont
        self.answerTextView.font = configuration.answerTextFont
        self.indicatorImageView.tintColor = configuration.indicatorColor
        if let dataDetectorTypes = configuration.dataDetectorTypes {
            self.answerTextView.dataDetectorTypes = dataDetectorTypes
        }
        if let tintColor = configuration.tintColor {
            self.answerTextView.tintColor = tintColor
        }
    }
    //swiftlint:disable:next function_body_length
    private func addLabelConstraints() {
        let questionLabelTrailing = NSLayoutConstraint(item: questionLabel, attribute: .trailing, relatedBy: .equal,
                                                       toItem: contentView, attribute: .trailingMargin, multiplier: 1,
                                                       constant: -30)
        let questionLabelLeading = NSLayoutConstraint(item: questionLabel, attribute: .leading, relatedBy: .equal,
                                                      toItem: contentView, attribute: .leadingMargin, multiplier: 1,
                                                      constant: 0)
        let questionLabelTop = NSLayoutConstraint(item: questionLabel, attribute: .top, relatedBy: .equal,
                                                  toItem: contentView, attribute: .top, multiplier: 1,
                                                  constant: 10)
        let answerTextViewTrailing = NSLayoutConstraint(item: answerTextView, attribute: .trailing, relatedBy: .equal,
                                                        toItem: contentView, attribute: .trailingMargin, multiplier: 1,
                                                        constant: -30)
        let answerTextViewLeading = NSLayoutConstraint(item: answerTextView, attribute: .leading, relatedBy: .equal,
                                                       toItem: contentView, attribute: .leadingMargin, multiplier: 1,
                                                       constant: -5)
        let answerTextViewTop = NSLayoutConstraint(item: answerTextView, attribute: .top, relatedBy: .equal,
                                                   toItem: questionLabel, attribute: .bottom, multiplier: 1,
                                                   constant: 10)
        answerTextViewBottom = NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal,
                                                  toItem: answerTextView, attribute: .bottom, multiplier: 1,
                                                  constant: 0)
        let indicatorHorizontalCenter = NSLayoutConstraint(item: indicatorImageView, attribute: .centerX,
                                                           relatedBy: .equal,
                                                           toItem: containerView, attribute: .centerX, multiplier: 1,
                                                           constant: 0)
        let indicatorVerticalCenter = NSLayoutConstraint(item: indicatorImageView, attribute: .centerY,
                                                         relatedBy: .equal,
                                                         toItem: containerView, attribute: .centerY, multiplier: 1,
                                                         constant: 0)
        let indicatorWidth = NSLayoutConstraint(item: indicatorImageView, attribute: .width, relatedBy: .equal,
                                                toItem: nil, attribute: .notAnAttribute, multiplier: 1,
                                                constant: 30)
        let indicatorHeight = NSLayoutConstraint(item: indicatorImageView, attribute: .height, relatedBy: .equal,
                                                 toItem: nil, attribute: .notAnAttribute, multiplier: 1,
                                                 constant: 30)
        let containerTrailing = NSLayoutConstraint(item: containerView, attribute: .trailing, relatedBy: .equal,
                                                   toItem: contentView, attribute: .trailingMargin, multiplier: 1,
                                                   constant: 5)
        let containerWidth = NSLayoutConstraint(item: containerView, attribute: .width, relatedBy: .equal,
                                                toItem: nil, attribute: .notAnAttribute, multiplier: 1,
                                                constant: 30)
        let containerTop = NSLayoutConstraint(item: containerView, attribute: .top, relatedBy: .equal,
                                              toItem: contentView, attribute: .top, multiplier: 1,
                                              constant: 10)
        let containerHeight = NSLayoutConstraint(item: containerView, attribute: .height, relatedBy: .equal,
                                                 toItem: questionLabel, attribute: .height, multiplier: 1,
                                                 constant: 0)
        NSLayoutConstraint.activate([questionLabelTrailing, questionLabelLeading, questionLabelTop,
                                     answerTextViewLeading, answerTextViewTrailing, answerTextViewTop,
                                     answerTextViewBottom, indicatorVerticalCenter, indicatorHorizontalCenter,
                                     indicatorWidth, indicatorHeight, containerTrailing, containerTop, containerWidth,
                                     containerHeight])
    }
    @objc private func didTapQuestion(_ recognizer: UIGestureRecognizer) {
        self.didSelectQuestion?(self)
    }
    private func expand(withAnswer answer: String, animated: Bool) {
        answerTextView.text = answer
        expand(animated: animated)
    }
    private func expand(withAttributedAnswer attributedAnswer: NSAttributedString, animated: Bool) {
        answerTextView.attributedText = attributedAnswer
        expand(animated: animated)
    }
    private func expand(animated: Bool) {
        answerTextView.isHidden = false
        if animated {
            answerTextView.alpha = 0
            UIView.animate(withDuration: 0.5, animations: {
                self.answerTextView.alpha = 1
            })
        }
        answerTextViewBottom.constant = 20
        update(arrow: .upArrow, animated: animated)
    }
    private func collapse(animated: Bool) {
        answerTextView.text = ""
        answerTextView.isHidden = true
        answerTextViewBottom.constant = -20
        update(arrow: .downArrow, animated: animated)
    }
    private func update(arrow: ArrowDirection, animated: Bool) {
        switch arrow {
        case .downArrow:
            if animated {
                // Change direction from down to up with animation
                self.indicatorImageView.rotate(withAngle: CGFloat(0), animated: false)
                self.indicatorImageView.rotate(withAngle: CGFloat(Double.pi), animated: true)
            } else {
                // Change direction from down to up without animation
                self.indicatorImageView.rotate(withAngle: CGFloat(Double.pi), animated: false)
            }
        case .upArrow:
            if animated {
                // Change direction from up to down with animation
                self.indicatorImageView.rotate(withAngle: CGFloat(Double.pi), animated: false)
                self.indicatorImageView.rotate(withAngle: CGFloat(0), animated: true)
            } else {
                // Change direction from up to down without animation
                self.indicatorImageView.rotate(withAngle: CGFloat(0), animated: false)
            }
        }
    }
}

// MARK: ArrowDirection
enum ArrowDirection: String {
    case upArrow
    case downArrow
}

// MARK: Cell Operation
enum CellOperation {
    case collapsed
    case expand
    case expanded
    case collapse
}

extension UIImageView {
    func rotate(withAngle angle: CGFloat, animated: Bool) {
        UIView.animate(withDuration: animated ? 0.5 : 0, animations: {
            self.transform = CGAffineTransform(rotationAngle: angle)
        })
    }
}
