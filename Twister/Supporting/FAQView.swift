//
//  FAQView.swift
//  FAQView
//
//  Created by Mukesh Thawani on 12/11/16.
//  Edited by Matteo Bartalini on 4/2/20
//  Copyright © 2016 Mukesh Thawani. All rights reserved.
//
import Foundation
import UIKit

// MARK: FAQView
public class FAQView: UIView {

    // MARK: Public Properties

    public var items: [FAQItem]

    public var questionTextColor: UIColor! {
        get {
            return configuration.questionTextColor
        }
        set(value) {
            configuration.questionTextColor = value
        }
    }

    public var answerTextColor: UIColor! {
        get {
            return configuration.answerTextColor
        }
        set(value) {
            configuration.answerTextColor = value
        }
    }

    public var questionTextFont: UIFont! {
        get {
            return configuration.questionTextFont
        }
        set(value) {
            configuration.questionTextFont = value
        }
    }

    public var answerTextFont: UIFont! {
        get {
            return configuration.answerTextFont
        }
        set(value) {
            configuration.answerTextFont = value
        }
    }

    public var titleLabelTextColor: UIColor! {
        get {
            return configuration.titleTextColor
        }
        set(value) {
            configuration.titleTextColor = value
            titleLabel.textColor = configuration.titleTextColor
        }
    }

    public var titleLabelTextFont: UIFont! {
        get {
            return configuration.titleTextFont
        }
        set(value) {
            configuration.titleTextFont = value
            titleLabel.font = configuration.titleTextFont
        }
    }

    public var titleLabelBackgroundColor: UIColor! {
        get {
            return configuration.titleLabelBackgroundColor
        }
        set(value) {
            configuration.titleLabelBackgroundColor = value
            titleLabel.backgroundColor = configuration.titleLabelBackgroundColor
        }
    }

    public var viewBackgroundColor: UIColor! {
        get {
            return configuration.viewBackgroundColor
        }
        set(value) {
            configuration.viewBackgroundColor = value
            self.backgroundColor = configuration.viewBackgroundColor
        }
    }

    public var cellBackgroundColor: UIColor! {
        get {
            return configuration.cellBackgroundColor
        }
        set(value) {
            configuration.cellBackgroundColor = value
        }
    }

    public var separatorColor: UIColor! {
        get {
            return configuration.separatorColor
        }
        set(value) {
            configuration.separatorColor = value
        }
    }

    public var dataDetectorTypes: UIDataDetectorTypes? {
        get {
            return configuration.dataDetectorTypes
        }
        set(value) {
            configuration.dataDetectorTypes = value
        }
    }

    public var answerTintColor: UIColor! {
        get {
            return configuration.tintColor
        }
        set(value) {
            configuration.tintColor = value
        }
    }

    public var indicatorColor: UIColor! {
        get {
            return configuration.indicatorColor
        }
        set(value) {
            configuration.indicatorColor = value
        }
    }

    // MARK: Internal Properties

    var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = UIColor.clear
        tableview.allowsSelection = false
        tableview.separatorStyle = .none
        tableview.estimatedRowHeight = 50
        tableview.tableFooterView = UIView()
        return tableview
    }()

    var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    var expandedCells = [CellOperation]()
    var configuration = FAQConfiguration()
    var heightAtIndexPath = NSMutableDictionary()

    // MARK: Initialization

    public init(frame: CGRect, title: String = "Top Queries", items: [FAQItem]) {
        self.items = items
        super.init(frame: frame)
        expandedCells = Array(repeating: CellOperation.collapsed, count: items.count)
        setupTitleView(title: title)
        setupTableView()
        setupView()
        self.addSubview(tableView)
        self.addSubview(titleLabel)
        addConstraintsForTableViewAndTitleLabel()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal Methods

    func updateSection(_ section: Int) {
        if expandedCells[section] == .expanded {
            expandedCells[section] = .collapse
        } else {
            expandedCells[section] = .expand
        }
        tableView.reloadSections(IndexSet(integer: section), with: .fade)
        tableView.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: true)
    }

    func updateCellOperation(section: Int, cellOperation: CellOperation) {
        if cellOperation == .expand {
            expandedCells[section] = .expanded
        } else if cellOperation == .collapse {
            expandedCells[section] = .collapsed
        }
    }

    // MARK: Private Methods

    private func setupTitleView(title: String) {
        self.titleLabel.textColor = configuration.titleTextColor
        self.titleLabel.font = configuration.titleTextFont
        self.titleLabel.backgroundColor = configuration.titleLabelBackgroundColor
        self.titleLabel.text = title
    }

    private func setupTableView() {
        self.tableView.register(FAQViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    private func setupView() {
        self.backgroundColor = configuration.viewBackgroundColor
    }

    private func addConstraintsForTableViewAndTitleLabel() {
        let titleLabelTrailing = NSLayoutConstraint(item: titleLabel, attribute: .trailing, relatedBy: .equal,
                                                    toItem: self, attribute: .trailingMargin, multiplier: 1,
                                                    constant: 0)
        let titleLabelLeading = NSLayoutConstraint(item: titleLabel, attribute: .leading, relatedBy: .equal,
                                                   toItem: self, attribute: .leadingMargin, multiplier: 1,
                                                   constant: 0)
        let titleLabelTop = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: self,
                                               attribute: .topMargin, multiplier: 1,
                                               constant: 20)

        let tableViewTrailing = NSLayoutConstraint(item: tableView, attribute: .trailing, relatedBy: .equal,
                                                   toItem: self, attribute: .trailingMargin, multiplier: 1,
                                                   constant: 0)
        let tableViewLeading = NSLayoutConstraint(item: tableView, attribute: .leading, relatedBy: .equal,
                                                  toItem: self, attribute: .leadingMargin, multiplier: 1,
                                                  constant: 0)
        let tableViewTop = NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal,
                                              toItem: titleLabel, attribute: .bottom, multiplier: 1,
                                              constant: 15)
        let tableViewBottom = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal,
                                                 toItem: self, attribute: .bottomMargin, multiplier: 1,
                                                 constant: 0)
        NSLayoutConstraint.activate([tableViewTrailing, tableViewLeading, tableViewTop, tableViewBottom,
                                     titleLabelLeading, titleLabelTrailing, titleLabelTop])
    }

}

extension FAQView: UITableViewDelegate, UITableViewDataSource {

    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = self.heightAtIndexPath.object(forKey: indexPath)
        if let height = height as? CGFloat {
            return height
        } else {
            #if swift(>=4.2)
            return UITableView.automaticDimension
            #else
            return UITableViewAutomaticDimension
            #endif
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let height = cell.frame.size.height
        self.heightAtIndexPath.setObject(height, forKey: indexPath as NSCopying)
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return items.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? FAQViewCell else {
            return UITableViewCell()
        }
        cell.configuration = configuration
        let currentItem = items[indexPath.section]
        let cellOperation = expandedCells[indexPath.section]
        cell.configure(currentItem: currentItem, indexPath: indexPath, cellOperation: cellOperation)
        updateCellOperation(section: indexPath.section, cellOperation: cellOperation)
        cell.didSelectQuestion = { [weak self] cell in
            guard let faqView = self else {
                return
            }
            faqView.updateSection(indexPath.section)
        }
        return cell
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 2
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 2))
        headerView.backgroundColor = configuration.separatorColor
        return headerView
    }
}
