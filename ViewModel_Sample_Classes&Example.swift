//
//  ViewModel_Sample_Classes&Example.swift
//  Demo Compass
//
//  Created by appsDev on 19/11/19.
//

import UIKit

struct BrokenRule {
    var propertyName :String
    var message :String
}
protocol ViewModel {
    var brokenRules :[BrokenRule] { get set}
    var isValid :Bool { mutating get }
    var showAlertClosure: (() -> ())? { get set }
    var updateLoadingStatus: (() -> ())? { get set }
    var didFinishFetch: (() -> ())? { get set }
    var error: String? { get set }
    var isLoading: Bool { get set }
}

// Mark: Creating Generic datatype for accepting dynamic data
class Dynamic<T> {
    typealias Listener = (T) -> ()
    var listener: Listener?
    
    func bind(_ listener: Listener?) {
        self.listener = listener
    }
    
    func bindAndFire(_ listener: Listener?) {
        self.listener = listener
        listener?(value)
    }
    
    var value: T {
        didSet {
            listener?(value)
        }
    }
    
    init(_ v: T) {
        value = v
    }
}


// Mark: Creating Binding UI for the UITextField

class BindingTextField : UITextField {
    
    var textChanged :(String) -> () = { _ in }
    
    func bind(callback :@escaping (String) -> ()) {
        
        self.textChanged = callback
        self.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField :UITextField) {
        
        self.textChanged(textField.text!)
    }
    
}

// Mark: Creating Binding UI for the UISlider

class BindingSlider : UISlider {
    
    var valueChanged :(Float) -> () = { _ in }
    
    func bind(callback :@escaping (Float) -> ()) {
        
        self.valueChanged = callback
        self.addTarget(self, action: #selector(valueDidChange), for: .valueChanged)
    }
    
    @objc func valueDidChange(_ slider:UISlider) {
        
        self.valueChanged(slider.value)
    }
}

// Mark: Creating Binding UI for the UIButton

class BindingButtonTitle : UIButton {
    
    var titleChanged :(String) -> () = { _ in }
    var ob:NSKeyValueObservation?
    func bind(callback :@escaping (String) -> ()) {
        
        self.titleChanged = callback
        ob = self.titleLabel?.observe(\.text, options: [.new], changeHandler: { [weak self] (_,change ) in
            self?.titleChanged(self?.title(for: .normal)! ?? "Title")
        })
    }
}


// Mark: Creating View Model Sample for Form type class

class SampleViewModel :NSObject, ViewModel {
    var brokenRules: [BrokenRule] = [BrokenRule]()
    var email :Dynamic<String> = Dynamic("")
    var password :Dynamic<String> = Dynamic("")
    
    
    var isValid :Bool {
        get {
            self.brokenRules = [BrokenRule]()
            self.Validate()
            return self.brokenRules.count == 0 ? true : false
        }
    }
    // MARK: - Closures for callback, since we are not using the ViewModel to the View.
    var showAlertClosure: (() -> ())?
    var updateLoadingStatus: (() -> ())?
    var didFinishFetch: (() -> ())?
    
    //API related Variable
    var error: String? {
        didSet { self.showAlertClosure?() }
    }
    var isLoading: Bool = false {
        didSet {
            self.updateLoadingStatus?()
        }
    }
    //Firebase Auth User ID
    var userID : String? {
        didSet {
            guard let _ = userID else { return }
            self.didFinishFetch?()
        }
    }
}
extension SampleViewModel {
    private func Validate() {
        if email.value == "" {
            self.brokenRules.append(BrokenRule(propertyName: "NoEmail", message: "Please enter email"))
        }
        if password.value == "" {
            self.brokenRules.append(BrokenRule(propertyName: "noPassword", message: "Please enter password"))
        }
    }
}
extension SampleViewModel {
    // MARK: - Network call
    func signIn() {
        isLoading = true
        let model = NetworkManager.sharedInstance
        model.register_Login(email: email.value, password: password.value) {[weak self](result, err) in
            guard let this = self else {return}
            if let er = err {
                this.error = er
                this.isLoading = false
                return
            }
            if result?.Response ?? 0 == 0 {
                this.error = result?.Msg ?? "Error"
                this.isLoading = false
                return
            }
            this.error = nil
            this.isLoading = false
            AppSettings.hasLogIn = true
            this.didFinishFetch?()
        }
    }
}

// Mark: Creating View Model Sample for Table class


class SampleTableViewModel :NSObject, ViewModel {
    var brokenRules: [BrokenRule] = [BrokenRule]()
    @objc dynamic private(set) var sourceViewModels : [PropertyList_User] = [PropertyList_User]()
    var isValid :Bool {
        get {
            self.brokenRules = [BrokenRule]()
            return self.brokenRules.count == 0 ? true : false
        }
    }
    // MARK: - Closures for callback, since we are not using the ViewModel to the View.
    var showAlertClosure: (() -> ())?
    var updateLoadingStatus: (() -> ())?
    var didFinishFetch: (() -> ())?
    
    //API related Variable
    var error: String? {
        didSet { self.showAlertClosure?() }
    }
    var isLoading: Bool = false {
        didSet {
            self.updateLoadingStatus?()
        }
    }
    //Firebase Auth User ID
    var userID : String? {
        didSet {
            guard let _ = userID else { return }
            self.didFinishFetch?()
        }
    }
    
    private var token :NSKeyValueObservation?
    var bindToSourceViewModels :(() -> ()) = {  }
    
    override init() {
        super.init()
        token = self.observe(\.sourceViewModels) { _,_ in
            self.bindToSourceViewModels()
        }
    }
    func invalidateObservers() {
        self.token?.invalidate()
    }
    func populateSources() {
        isLoading = true
        let model = NetworkManager.sharedInstance
        model.UserRequests_GetInformation(type: type.param) {[weak self](result, err) in
            guard let this = self else {return}
            this.didFinishFetch?()
            if let er = err {
                this.error = er
                this.isLoading = false
                return
            }
            if result?.Response ?? 0 == 0 {
                this.error = result?.Msg ?? "Error"
                this.isLoading = false
                return
            }
            this.error = nil
            this.isLoading = false
            this.sourceViewModels = result?.propertylst ?? []
        }
    }
}

class PropertyList_User : NSObject,Codable {
    let Id: Int?
    let FirstName: String?
    let LastName: String?
    let CreatedDate: String?
    let Image: String?
    let EmailID: String?
    let Address: String?
    let Phone: String?
    let PropertyImage: String?
    let Latitude: String?
    let Longitude: String?
    let MLSID: String?
    enum CodingKeys: String, CodingKey {
        case Id = "Id"
        case FirstName = "FirstName"
        case LastName = "LastName"
        case CreatedDate = "CreatedDate"
        case Image = "Image"
        case EmailID = "EmailID"
        case Address = "Address"
        case Phone = "Phone"
        case PropertyImage = "PropertyImage"
        case Latitude = "Latitude"
        case Longitude = "Longitude"
        case MLSID = "MLSID"
    }
}


// Mark: Using View Model Sample for Form type class


class LoginVC: UIViewController {
    
    @IBOutlet weak var email_text:BindingTextField! {
        didSet { email_text.bind { self.viewModel.email.value = $0 } }
    }
    @IBOutlet weak var password_text:BindingTextField! {
        didSet { password_text.bind { self.viewModel.password.value = $0 } }
    }
    var viewModel :SampleViewModel! {
        didSet {
            viewModel.email.bind { [unowned self] in self.email_text.text = $0 }
            viewModel.password.bind { [unowned self] in self.password_text.text = $0 }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SampleViewModel.init()
    }
    @IBAction func btnAction(_ sender:UIButton) {
        if viewModel.isValid {
            //Validation Success
            viewModel.signIn()
            viewModel.didFinishFetch = { [weak self] in
                // API Success
                DispatchQueue.main.async {
                    self?.performSegue(withIdentifier: "login", sender: self)
                }
            }
        } else {
            // show errors
            print(viewModel.brokenRules)
        }
    }
}


// Mark: Using View Model Sample for Table type class

class UsersTabVC: UIViewController {
    var viewModel :SampleTableViewModel!
    //MARK:-
    private var dataSource :TableViewDataSource<UserTabUserCell,PropertyList_User>!
    @IBOutlet weak var userTable : UITableView!
   
    //MARK:- View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = SampleTableViewModel()
    }
    override func viewWillAppear(_ animated: Bool) {
        self.viewModel.bindToSourceViewModels = {
            DispatchQueue.main.async {
                self.updateDataSource()
            }
        }
        viewModel.populateSources()
    }
    //MARK:-
    private func updateDataSource() {
        self.dataSource = TableViewDataSource(cellIdentifier: String.init(describing: UserTabUserCell.self), items: self.viewModel.sourceViewModels) { cell, vm in
            
        }
        self.userTable.dataSource = self.dataSource
        self.userTable.reloadData()
    }
}

class UserTabUserCell: UITableViewCell {
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
