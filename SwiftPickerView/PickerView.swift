//
//  PickerView.swift
//  SwiftPickerView
//
//  Created by CoderDoraemon on 10/11/2019.
//  Copyright (c) 2019 CoderDoraemon. All rights reserved.
//

#if canImport(UIKit)
import UIKit

//MARK:- PickerViewDelegate 用于自动设置TextField的选中值
public protocol PickerViewDelegate: class {
    func singleColDidSelecte(_ selectedIndex: Int, selectedValue: String)
    func multipleColsDidSelecte(_ selectedIndexs: [Int], selectedValues: [String])
    func dateDidSelecte(_ selectedDate: Date)
}

//MARK:- 配置UIDatePicker的样式
public struct DatePickerSetting {
    /// 默认选中时间
    public var date = Date()
    /// 时间样式
    public var dateMode = UIDatePicker.Mode.date
    /// 最小时间
    public var minimumDate: Date?
    /// 最大时间
    public var maximumDate: Date?
    public init() {}
}

public enum PickerStyles {
    /// 单行
    case single
    /// 多行
    case multiple
    /// 多行联动
    case multipleAssociated
    /// 日期
    case date
}

//MARK:- PickerView
public class PickerView: UIView {
    
    /// 完成按钮回调
    public typealias BtnAction = () -> Void
    /// 单选完成按钮回调
    public typealias SingleDoneAction = (_ selectedIndex: Int, _ selectedValue: String) -> Void
    /// 多选完成按钮回调
    public typealias MultipleDoneAction = (_ selectedIndexs: [Int], _ selectedValues: [String]) -> Void
    /// 日期完成按钮回调
    public typealias DateDoneAction = (_ selectedDate: Date) -> Void
    /// 多选联动完成按钮回调
    public typealias MultipleAssociatedDataType = [[[String: [String]?]]]
    
    /// 屏幕宽度
    fileprivate let screenWidth = UIScreen.main.bounds.size.width
    /// pickerView高度
    fileprivate let pickerViewHeight = 216.0
    /// pickerView工具栏高度
    fileprivate let toolBarHeight = 44.0
    /// pickerView代理
    weak var delegate: PickerViewDelegate?
    /// 工具栏标题
    fileprivate var toolBarTitle = "请选择" {
        didSet {
            toolBar.title = toolBarTitle
        }
    }
    /// pickerView样式
    fileprivate var pickerStyle: PickerStyles = .single
    /// 配置UIDatePicker的样式
    fileprivate var datePickerSetting = DatePickerSetting() {
        didSet {
            datePicker.date = datePickerSetting.date
            datePicker.minimumDate = datePickerSetting.minimumDate
            datePicker.maximumDate = datePickerSetting.maximumDate
            datePicker.datePickerMode = datePickerSetting.dateMode
            /// set currentDate to the default
            selectedDate = datePickerSetting.date
        }
    }
    /// 取消按钮回调
    fileprivate var cancelAction: BtnAction? = nil {
        didSet {
            toolBar.cancelAction = cancelAction
        }
    }
    //MARK:- 只有一列的时候用到的属性
    fileprivate var singleDoneOnClick: SingleDoneAction? = nil {
        didSet {
            toolBar.doneAction =  {[unowned self] in
                
                self.singleDoneOnClick?(self.selectedIndex, self.selectedValue)
            }
        }
    }
    
    fileprivate var defalultSelectedIndex: Int? = nil {
        didSet {
            if let defaultIndex = defalultSelectedIndex, let singleData = singleColData {// 判断下标是否合法
                assert(defaultIndex >= 0 && defaultIndex < singleData.count, "设置的默认选中Index不合法")
                if defaultIndex >= 0 && defaultIndex < singleData.count {
                    // 设置默认值
                    selectedIndex = defaultIndex
                    selectedValue = singleData[defaultIndex]
                    // 滚动到默认位置
                    pickerView.selectRow(defaultIndex, inComponent: 0, animated: false)
                    
                }
                
            } else {// 没有默认值设置0行为默认值
                selectedIndex = 0
                selectedValue = singleColData![0]
                pickerView.selectRow(0, inComponent: 0, animated: false)
                
            }
        }
    }
    fileprivate var singleColData: [String]? = nil
    
    fileprivate var selectedIndex: Int = 0
    fileprivate var selectedValue: String = "" {
        didSet {
            delegate?.singleColDidSelecte(selectedIndex, selectedValue: selectedValue)
        }
    }
    
    
    //MARK:- 有多列不关联的时候用到的属性
    fileprivate var multipleDoneOnClick:MultipleDoneAction? = nil {
        didSet {
            
            toolBar.doneAction =  {[unowned self] in
                self.multipleDoneOnClick?(self.selectedIndexs, self.selectedValues)
            }
        }
    }
    
    fileprivate var multipleColsData: [[String]]? = nil {
        didSet {
            if let multipleData = multipleColsData {
                for _ in multipleData.indices {
                    selectedIndexs.append(0)
                    selectedValues.append(" ")
                }
                
            }
        }
    }
    
    fileprivate var selectedIndexs: [Int] = []
    fileprivate var selectedValues: [String] = [] {
        didSet {
            delegate?.multipleColsDidSelecte(selectedIndexs, selectedValues: selectedValues)
        }
    }
    // 不关联的数据时直接设置默认的下标
    fileprivate var defalultSelectedIndexs: [Int]? = nil {
        didSet {
            if let defaultIndexs = defalultSelectedIndexs {
                
                defaultIndexs.enumerated().forEach({ (component: Int, row: Int) in
                    
                    assert(component < pickerView.numberOfComponents && row < pickerView.numberOfRows(inComponent: component), "设置的默认选中Indexs有不合法的")
                    if component < pickerView.numberOfComponents && row < pickerView.numberOfRows(inComponent: component){
                        
                        // 滚动到默认位置
                        
                        // 设置默认值
                        selectedIndexs[component] = row
                        selectedValues[component] = titleForRow(row, forComponent: component) ?? " "
                        
                        DispatchQueue.main.async(execute: {
                            
                            self.pickerView.selectRow(row, inComponent: component, animated: false)
                        })

                    }
                    
                })
                
            } else {
                multipleColsData?.indices.forEach({ (index) in
                    // 滚动到默认位置
                    pickerView.selectRow(0, inComponent: index, animated: false)
                    
                    // 设置默认选中值
                    selectedIndexs[index] = 0
                    
                    selectedValues[index] = titleForRow(0, forComponent: index) ?? " "
                    
                })
            }
        }
    }
    
    //MARK:- 有多列关联的时候用到的属性
    fileprivate var multipleAssociatedColsData: MultipleAssociatedDataType? = nil {
        didSet {
            
            if let multipleAssociatedData = multipleAssociatedColsData {
                // 初始化选中的values
                for _ in 0...multipleAssociatedData.count {
                    selectedIndexs.append(0)
                    selectedValues.append(" ")
                }
            }
        }
    }
    
    // 多列关联数据的时候设置默认的values而没有使用默认的index
    fileprivate var defaultSelectedValues: [String]? = nil {
        didSet {
            
            if let defaultValues = defaultSelectedValues {
                defaultValues.enumerated().forEach { (component: Int, element: String) in
                    var row: Int? = nil

                    if component == 0 {
                        let firstData = multipleAssociatedColsData![0]
                    
                        for (index,associatedModel) in firstData.enumerated() {
                            if associatedModel.first!.0 == element {
                                row = index
                                break
                            }
                        }
                    } else {
                        
                        let associatedModels = multipleAssociatedColsData![component - 1]
                        var arr: [String]?
                        
                        for associatedModel in associatedModels {

                            if associatedModel.first!.0 == defaultValues[component - 1] {
                                arr = associatedModel.first!.1
                                break
                            }
                        }
                        row = arr?.firstIndex(of: element)
                        
                    }
                    
                    assert(row != nil, "第\(component)列设置的默认值有误")
                    if row == nil {
                        row = 0
                        print("第\(component)列设置的默认值有误")
                    }
                    if component < pickerView.numberOfComponents {
                        // 设置选中的下标
                        selectedIndexs[component] = row!
                        // 设置默认值
                        selectedValues[component] = titleForRow(row!, forComponent: component) ?? " "
                        // 滚动到默认的位置
                        DispatchQueue.main.async(execute: { 
                            
                            self.pickerView.selectRow(row!, inComponent: component, animated: false)
                        })

                    }
                    
                }
                
                
            } else {
                for index in 0...multipleAssociatedColsData!.count {
                    // 滚动到默认的位置 0 行
                    pickerView.selectRow(0, inComponent: index, animated: false)
                    // 设置默认的选中值
                    selectedValues[index] = titleForRow(0, forComponent: index) ?? " "

                    selectedIndexs[index] = 0
                }
            }
            
        }
        
    }
    
    // MARK:- 日期选择器用到的属性
    fileprivate var selectedDate = Date() {
        didSet {
            delegate?.dateDidSelecte(selectedDate)
        }
    }
    fileprivate var dateDoneAction: DateDoneAction? {
        didSet {
            toolBar.doneAction = {[unowned self] in
                self.dateDoneAction?(self.selectedDate)
                
            }
        }
    }
    
    fileprivate lazy var pickerView: UIPickerView = { [unowned self] in
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.backgroundColor = UIColor.white
        return picker
    }()
    
    fileprivate lazy var datePicker: UIDatePicker = {[unowned self] in
        let datePic = UIDatePicker()
        datePic.backgroundColor = UIColor.white
        datePic.locale = Locale(identifier: "zh_CN")
        return datePic
    }()
    
    fileprivate lazy var toolBar: ToolBarView = {
        
        let toolBar = ToolBarView()
        return toolBar
    }()
    
    //MARK:- 初始化
    public init(pickerStyle: PickerStyles) {
        let frame = CGRect(x: 0.0, y: 0.0, width: Double(screenWidth), height: toolBarHeight + pickerViewHeight)
        self.pickerStyle = pickerStyle
        super.init(frame: frame)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        print("\(self.debugDescription) --- 销毁")
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        let toolBarX = NSLayoutConstraint(item: toolBar, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        
        let toolBarY = NSLayoutConstraint(item: toolBar, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        let toolBarW = NSLayoutConstraint(item: toolBar, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
        let toolBarH = NSLayoutConstraint(item: toolBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(toolBarHeight))
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraints([toolBarX, toolBarY, toolBarW, toolBarH])

        if pickerStyle == PickerStyles.date {
            
            let pickerX = NSLayoutConstraint(item: datePicker, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
            
            let pickerY = NSLayoutConstraint(item: datePicker, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: CGFloat(toolBarHeight))
            let pickerW = NSLayoutConstraint(item: datePicker, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
            let pickerH = NSLayoutConstraint(item: datePicker, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(pickerViewHeight))
            datePicker.translatesAutoresizingMaskIntoConstraints = false
            addConstraints([pickerX, pickerY, pickerW, pickerH])
        } else {
            
            let pickerX = NSLayoutConstraint(item: pickerView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
            
            let pickerY = NSLayoutConstraint(item: pickerView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: CGFloat(toolBarHeight))
            let pickerW = NSLayoutConstraint(item: pickerView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
            let pickerH = NSLayoutConstraint(item: pickerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: CGFloat(pickerViewHeight))
            pickerView.translatesAutoresizingMaskIntoConstraints = false

            addConstraints([pickerX, pickerY, pickerW, pickerH])
        }

    }
    
    
}

fileprivate extension PickerView {
    
    func commonInit() {
        
        addSubview(toolBar)
        
        if pickerStyle == PickerStyles.date {
            datePicker.addTarget(self, action: #selector(self.dateDidChange(_:)), for: UIControl.Event.valueChanged)
            addSubview(datePicker)

        } else {
            addSubview(pickerView)
        }
    }
    
    @objc
    func dateDidChange(_ datePic: UIDatePicker) {
        selectedDate = datePic.date
    }
}

//MARK: UIPickerViewDelegate, UIPickerViewDataSource
extension PickerView: UIPickerViewDelegate, UIPickerViewDataSource {
    
    final public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        
        switch pickerStyle {
        case .single:
            return singleColData == nil ? 0 : 1
        case .multiple:
            return multipleColsData?.count ?? 0
        case .multipleAssociated:
            return multipleAssociatedColsData == nil ? 0 : multipleAssociatedColsData!.count+1
        default: return 0
        }
        
    }
    
    final public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        switch pickerStyle {
        case .single:
            return singleColData?.count ?? 0
        case .multiple:
            return multipleColsData?[component].count ?? 0
        case .multipleAssociated:
            if let multipleAssociatedData = multipleAssociatedColsData {
                
                if component == 0 {
                    return multipleAssociatedData[0].count
                }else {
                    let associatedDataModels = multipleAssociatedData[component - 1]
                    var arr: [String]?
                    
                    for associatedDataModel in associatedDataModels {
                        if associatedDataModel.first!.0 == selectedValues[component - 1] {
                            arr = associatedDataModel.first!.1
                        }
                    }
                    
                    return arr?.count ?? 0
                    
                }
                
            }
            return 0
        default: return 0
        }
        
    }
    
    final public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerStyle {
        case .single:
            selectedIndex = row
            selectedValue = singleColData![row]
        case .multiple:
            selectedIndexs[component] = row
            if let title = titleForRow(row, forComponent: component) {
                selectedValues[component] = title
            }
        case .multipleAssociated:
            // 设置选中值
            
            if let title = titleForRow(row, forComponent: component) {
                selectedValues[component] = title
                selectedIndexs[component] = row
                // 更新下一列关联的值
                if component < multipleAssociatedColsData!.count {
                    pickerView.reloadComponent(component + 1)
                    // 递归
                    self.pickerView(pickerView, didSelectRow: 0, inComponent: component+1)
                    pickerView.selectRow(0, inComponent: component+1, animated: true)
                    
                }

            }
            
            
        default : return
        }
        
        
    }
    
    final public func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
 
        let label = UILabel()
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 18.0)
        label.backgroundColor = UIColor.clear

        label.text = titleForRow(row, forComponent: component)
        return label
    }
    
    // Helper
    fileprivate func titleForRow(_ row: Int, forComponent component: Int) -> String? {
        switch pickerStyle {
        case .single:
            return singleColData?[row]
        case .multiple:
            return multipleColsData?[component][row]
        case .multipleAssociated:
            
            if let multipleAssociatedData = multipleAssociatedColsData {
                
                if component == 0 {
                    return multipleAssociatedData[0][row].first!.0
                }else {
                    let associatedDataModels = multipleAssociatedData[component - 1]
                    var arr: [String]?
                    
                    for associatedDataModel in associatedDataModels {
                        if associatedDataModel.first!.0 == selectedValues[component - 1] {
                            arr = associatedDataModel.first!.1
                        }
                    }
                    if arr?.count == 0 {// 空数组
                        return nil
                    }
                    return arr?[row]
                    
                }
                
            }
            return nil
        default: return nil
   
        }

    }

}

//MARK: 快速使用方法
public extension PickerView {
    
    /// 单列
    /// - Parameter toolBarTitle: 工具栏标题
    /// - Parameter singleColData: 数据源 ~> [String]
    /// - Parameter defaultIndex: 默认选中索引
    /// - Parameter cancelAction: 取消回调
    /// - Parameter doneAction: 完成回调
    class func singleColPicker(_ toolBarTitle: String, singleColData: [String], defaultIndex: Int?,cancelAction: BtnAction?, doneAction: SingleDoneAction?) -> PickerView {
        let pic = PickerView(pickerStyle: .single)
        
        pic.toolBarTitle = toolBarTitle
        pic.singleColData = singleColData
        pic.defalultSelectedIndex = defaultIndex
        
        pic.singleDoneOnClick = doneAction
        pic.cancelAction = cancelAction
        return pic
        
    }
    
    /// 多列不关联
    /// - Parameter toolBarTitle: 工具栏标题
    /// - Parameter multipleColsData: 数据源 ~> [[String]]
    /// - Parameter defaultSelectedIndexs: 默认选中索引
    /// - Parameter cancelAction: 取消回调
    /// - Parameter doneAction: 完成回调
    class func multipleCosPicker(_ toolBarTitle: String, multipleColsData: [[String]], defaultSelectedIndexs: [Int]?,cancelAction: BtnAction?, doneAction: MultipleDoneAction?) -> PickerView {
        
        let pic = PickerView(pickerStyle: .multiple)
        
        pic.toolBarTitle = toolBarTitle
        pic.multipleColsData = multipleColsData
        pic.defalultSelectedIndexs = defaultSelectedIndexs
        pic.cancelAction = cancelAction
        pic.multipleDoneOnClick = doneAction
        return pic
        
    }
    
    /// 多列关联
    /// - Parameter toolBarTitle: 工具栏标题
    /// - Parameter multipleAssociatedColsData: 数据源 ~> [[[String: [String]?]]]
    /// - Parameter defaultSelectedValues: 默认选中值 ~> [String]？
    /// - Parameter cancelAction: 取消回调
    /// - Parameter doneAction: 完成回调
    class func multipleAssociatedCosPicker(_ toolBarTitle: String, multipleAssociatedColsData: MultipleAssociatedDataType, defaultSelectedValues: [String]?,cancelAction: BtnAction?, doneAction: MultipleDoneAction?) -> PickerView {
        
        let pic = PickerView(pickerStyle: .multipleAssociated)
        
        pic.toolBarTitle = toolBarTitle
        pic.multipleAssociatedColsData = multipleAssociatedColsData
        pic.defaultSelectedValues = defaultSelectedValues
        pic.cancelAction = cancelAction
        pic.multipleDoneOnClick = doneAction
        return pic
        
    }
    
    /// 城市选择器
    /// - Parameter toolBarTitle: 工具栏标题
    /// - Parameter defaultSelectedValues: 默认选中值
    /// - Parameter cancelAction: 取消回调
    /// - Parameter doneAction: 完成回调
    /// - Parameter selectTopLevel: 是否选中顶部
    class func citiesPicker(_ toolBarTitle: String, defaultSelectedValues: [String]?, cancelAction: BtnAction?, doneAction: MultipleDoneAction?, selectTopLevel: Bool = false) -> PickerView {
        
        let provincePath = Bundle.main.path(forResource: "Province", ofType: "plist")
        let cityPath = Bundle.main.path(forResource: "City", ofType: "plist")
        let areaPath = Bundle.main.path(forResource: "Area", ofType: "plist")
        // 这里需要使用数组, 因为字典无序, 如果只使用 cityArr,areaArr, 那么显示将是无序的, 不能按照plist中的数组显示
        let proviceArr = NSArray(contentsOfFile: provincePath!)
        let cityArr = NSDictionary(contentsOfFile: cityPath!)
        let areaArr = NSDictionary(contentsOfFile: areaPath!)
        
        var citiesModelArr: [[String: [String]?]] = []
        var areasModelArr: [[String: [String]?]] = []

        proviceArr?.forEach({ (element) in
            if let provinceStr = element as? String {
                
                var cities = cityArr?[provinceStr] as? [String]
                if selectTopLevel {
                  cities?.insert("/", at: 0)
                }
                citiesModelArr.append([provinceStr: cities])
                
                cities?.forEach({ (city) in
                    if city == "/" {
                      areasModelArr.append([city: ["/"]])
                    }
                    else {
                      var areas = areaArr?[city]as? [String]
                      
                      if selectTopLevel {
                        areas!.insert("/", at: 0)
                      }
                      areasModelArr.append([city: areas])
                    }
                  
                })
            }
        })
        
        let citiesArr = [citiesModelArr, areasModelArr]
        
        
        let pic = PickerView.multipleAssociatedCosPicker(toolBarTitle, multipleAssociatedColsData: citiesArr, defaultSelectedValues: defaultSelectedValues, cancelAction: cancelAction, doneAction: doneAction)
        return pic
        
    }
    
    /// 时间选择器
    /// - Parameter toolBarTitle: 工具栏标题
    /// - Parameter datePickerSetting: date配置
    /// - Parameter cancelAction: 取消回调
    /// - Parameter doneAction: 完成回调
    class func datePicker(_ toolBarTitle: String, datePickerSetting: DatePickerSetting, cancelAction: BtnAction?, doneAction: DateDoneAction?) -> PickerView {
        
        let pic = PickerView(pickerStyle: .date)
        pic.datePickerSetting = datePickerSetting
        pic.toolBarTitle = toolBarTitle
        pic.cancelAction = cancelAction
        pic.dateDoneAction = doneAction
        return pic

    }
    
}

#endif
