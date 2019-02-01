//
//  ViewController.swift
//  20180131-RohanSharma-NYCSchools
//
//  Created by Rohan Sharma on 1/31/19.
//  Copyright © 2019 Rohan Sharma. All rights reserved.
//

import UIKit

// Storing JSON keys for easy reference
struct Keys {
    let dbn = "dbn"
    let schoolName = "school_name"
    let numOfTestTakers = "num_of_sat_test_takers"
    let critReadingScore = "sat_critical_reading_avg_score"
    let mathScore = "sat_math_avg_score"
    let writingScore = "sat_writing_avg_score"
}

// Custom struct to store school data
struct SchoolDataStruct {
    var dbn: String!
    var name: String!
    var numOfTestTakers: String!
    var critReadingScore: String!
    var mathScore: String!
    var writingScore: String!
    
    init() {
        self.dbn = nil
        self.name = nil
        self.numOfTestTakers = nil
        self.critReadingScore = nil
        self.mathScore = nil
        self.writingScore = nil
    }
    
    init(dbn: String, name: String, numOfTestTakers: String, critReadingScore: String, mathScore: String, writingScore: String) {
        self.dbn = dbn
        self.name = name
        self.numOfTestTakers = numOfTestTakers
        self.critReadingScore = critReadingScore
        self.mathScore = mathScore
        self.writingScore = writingScore
    }
    
    // Print func for debugging purposes
    func printInfo() {
        print("dbn: \(self.dbn ?? "")")
        print("name: \(self.name ?? "")")
        print("numOfTestTakers: \(self.numOfTestTakers ?? "")")
        print("critReadingScore: \(self.critReadingScore ?? "")")
        print("mathScore: \(self.mathScore ?? "")")
        print("writingScore: \(self.writingScore ?? "") \n")
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadDataButton: UIButton!
    
    var activityIndicator: UIActivityIndicatorView!
    
    var schoolDict = [String: String]()
    var schoolDataStructArr = [SchoolDataStruct]()
    
    var viewTappedDict = [Int: Bool]() // For detecting when a header view was tapped
    
    var alertView: UIAlertController!
    
    var deleteDataTapped = false
    
    let loadButtonColor = UIColor(red: 75/255, green: 92/255, blue: 87/255, alpha: 1.0)
    let deleteButtonColor = UIColor.red
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Making sure tableView delegate and data source funcs will be called
        tableView.dataSource = self
        tableView.delegate = self
        
        loadDataButton.layer.cornerRadius = 5
        
        let screenBounds = UIScreen.main.bounds
        activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.frame.origin = CGPoint(x: (screenBounds.width - activityIndicator.bounds.width) / 2,
                                                 y: (screenBounds.height - activityIndicator.bounds.height) / 2)
        self.view.addSubview(activityIndicator)
        
        alertView = UIAlertController(title: "Alert", message: "Could not load data from API", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Okay", style: .cancel, handler: nil))
    }
    
    // Making API call to get school names and dbns
    func loadSchoolData() {
        activityIndicator.startAnimating()
        loadDataButton.alpha = 0.25
        loadDataButton.isUserInteractionEnabled = false
        guard let schoolUrl = URL(string: "https://data.cityofnewyork.us/resource/97mf-9njv.json") else {
            alertView.message = "Could not convert https://data.cityofnewyork.us/resource/97mf-9njv.json to URL"
            self.present(self.alertView, animated: true, completion: nil)
            return
        }
        // Making the API call
        let schoolTask = URLSession.shared.dataTask(with: schoolUrl) { (data, resp, err) in
            guard let dataResp = data,
                err == nil else {
                    self.alertView.message = err?.localizedDescription ?? "Error receiving data"
                    self.present(self.alertView, animated: true, completion: nil)
                    return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: dataResp, options: [])
                guard let jsonDict = json as? [[String: String]] else {
                    self.alertView.message = "Could not convert json to [String: String]"
                    self.present(self.alertView, animated: true, completion: nil)
                    return
                }
                // Initial storing of [dbns: school names]
                for i in 0..<jsonDict.count {
                    self.schoolDict[jsonDict[i][Keys().dbn]!] = jsonDict[i][Keys().schoolName]!
                }
                
                self.loadSATData()
            } catch let parsingErr {
                self.alertView.message = parsingErr.localizedDescription
                self.present(self.alertView, animated: true, completion: nil)
            }
        }
        schoolTask.resume()
    }
    
    // Making API call to get SAT scores for the schools
    func loadSATData() {
        guard let satURL = URL(string: "https://data.cityofnewyork.us/resource/734v-jeq5.json") else {
            alertView.message = "Could not convert https://data.cityofnewyork.us/resource/734v-jeq5.json to URL"
            self.present(self.alertView, animated: true, completion: nil)
            return
        }
        // Making the API call
        let satTask = URLSession.shared.dataTask(with: satURL) { (data, resp, err) in
            guard let dataResp = data,
                err == nil else {
                    self.alertView.message = err?.localizedDescription ?? "Error receiving data"
                    self.present(self.alertView, animated: true, completion: nil)
                    return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: dataResp, options: [])
                guard let jsonDict = json as? [[String: String]] else {
                    self.alertView.message = "Could not convert json to [String: String]"
                    self.present(self.alertView, animated: true, completion: nil)
                    return
                }
                // Creating custom school struct for easy data access
                for i in 0..<jsonDict.count {
                    let schoolDBN = jsonDict[i][Keys().dbn]!
                    if self.schoolDict[schoolDBN] != nil {
                        var schoolDataStruct = SchoolDataStruct()
                        schoolDataStruct.dbn = schoolDBN
                        schoolDataStruct.name = self.schoolDict[schoolDBN]
                        schoolDataStruct.numOfTestTakers = jsonDict[i][Keys().numOfTestTakers]!
                        schoolDataStruct.critReadingScore = jsonDict[i][Keys().critReadingScore]!
                        schoolDataStruct.mathScore = jsonDict[i][Keys().mathScore]!
                        schoolDataStruct.writingScore = jsonDict[i][Keys().writingScore]!
                        self.schoolDataStructArr.append(schoolDataStruct)
                    }
                }
                // Updates to UI are on the main thread
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    self.loadDataButton.alpha = 1.0
                    self.loadDataButton.isUserInteractionEnabled = true
                    self.tableView.reloadData()
                    
                    if self.loadDataButton.titleLabel?.text == "Load Data" {
                        self.loadDataButton.setTitle("Delete Data", for: .normal)
                        self.loadDataButton.backgroundColor = self.deleteButtonColor
                    } else {
                        self.loadDataButton.setTitle("Load Data", for: .normal)
                        self.loadDataButton.backgroundColor = self.loadButtonColor
                    }
                }
            } catch let parsingErr {
                self.alertView.message = parsingErr.localizedDescription
                self.present(self.alertView, animated: true, completion: nil)
            }
        }
        satTask.resume()
    }
    
    // Handles tap on Header for displaying school info
    @objc func headerViewTapped(_ gesture: UITapGestureRecognizer) {
        let headerView = gesture.view!
        
        if viewTappedDict[headerView.tag] == nil {
            viewTappedDict[headerView.tag] = true
        } else  {
            viewTappedDict[headerView.tag] = !(viewTappedDict[headerView.tag]!)
        }
        // Only reloading tapped section for efficiency
        tableView.reloadSections(IndexSet(integer: headerView.tag), with: .none)
    }
    
    // Handling load/delete data button taps
    @IBAction func touchUpIn(_ sender: Any) {
        if sender is UIButton {
            
            if loadDataButton.titleLabel?.text == "Load Data" {
                if schoolDataStructArr.count == 0 {
                    loadSchoolData()
                } else {
                    tableView.reloadData()
                    loadDataButton.setTitle("Delete Data", for: .normal)
                    loadDataButton.backgroundColor = deleteButtonColor
                }
            } else {
                viewTappedDict.removeAll()
                deleteDataTapped = true
                tableView.reloadData()
                loadDataButton.setTitle("Load Data", for: .normal)
                loadDataButton.backgroundColor = loadButtonColor
                deleteDataTapped = false
            }
        }
    }
    
    // MARK: - UITableViewDatasource/Delegate methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if deleteDataTapped {
            return 0
        }
        return schoolDataStructArr.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if viewTappedDict[section] == nil {
            return 0
        }
        
        return viewTappedDict[section]! ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 100
    }
    
    // Custom view for headers
    // Contains a UILabel for the school names
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 100))
        headerView.backgroundColor = UIColor(red: 234/255, green: 226/255, blue: 224/255, alpha: 1.0)
        headerView.tag = section
        
        let borderView = UIView(frame: CGRect(x: 10, y: 10, width: headerView.frame.width - 20, height: headerView.frame.height - 20))
        borderView.layer.cornerRadius = 5
        borderView.layer.borderWidth = 3
        borderView.layer.borderColor = UIColor(red: 23/255, green: 38/355, blue: 38/255, alpha: 1.0).cgColor
        
        let titleLabel = UILabel(frame: CGRect(x: 5, y: 0, width: borderView.bounds.width - 10, height: borderView.bounds.height))
        titleLabel.textAlignment = .center
        titleLabel.text = schoolDataStructArr[section].name
        
        borderView.addSubview(titleLabel)
        headerView.addSubview(borderView)
        
        let tapGest = UITapGestureRecognizer(target: self, action: #selector(headerViewTapped(_ :)))
        tapGest.numberOfTapsRequired = 1
        headerView.addGestureRecognizer(tapGest)
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let schoolCellID = "schoolCell"
        let schoolCell = tableView.dequeueReusableCell(withIdentifier: schoolCellID, for: indexPath) as! SchoolCell
        schoolCell.layer.backgroundColor = UIColor.clear.cgColor
        schoolCell.testTakersLabel.text = schoolDataStructArr[indexPath.section].numOfTestTakers!
        schoolCell.readingScoreLabel.text = schoolDataStructArr[indexPath.section].critReadingScore!
        schoolCell.mathScoreLabel.text = schoolDataStructArr[indexPath.section].mathScore!
        schoolCell.writingScoreLabel.text = schoolDataStructArr[indexPath.section].writingScore!
        
        return schoolCell
    }
}

// MARK: - UITableViewCell classes

class SchoolCell: UITableViewCell {
    @IBOutlet weak var testTakersLabel: UILabel!
    @IBOutlet weak var readingScoreLabel: UILabel!
    @IBOutlet weak var mathScoreLabel: UILabel!
    @IBOutlet weak var writingScoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // No need for selecting cells
        self.selectionStyle = .none
    }
}
