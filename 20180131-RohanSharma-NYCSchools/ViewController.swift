//
//  ViewController.swift
//  20180131-RohanSharma-NYCSchools
//
//  Created by Rohan Sharma on 1/31/19.
//  Copyright © 2019 Rohan Sharma. All rights reserved.
//

import UIKit

struct Keys {
    let dbn = "dbn"
    let schoolName = "school_name"
    let numOfTestTakers = "num_of_sat_test_takers"
    let critReadingScore = "sat_critical_reading_avg_score"
    let mathScore = "sat_math_avg_score"
    let writingScore = "sat_writing_avg_score"
}

struct SchoolDataStruct {
    var dbn: String!
    var name: Any!
    var numOfTestTakers: Any!
    var critReadingScore: Any!
    var mathScore: Any!
    var writingScore: Any!
    
    init() {
        self.dbn = nil
        self.name = nil
        self.numOfTestTakers = nil
        self.critReadingScore = nil
        self.mathScore = nil
        self.writingScore = nil
    }
    
    init(dbn: String, name: Any, numOfTestTakers: Any, critReadingScore: Any, mathScore: Any, writingScore: Any) {
        self.dbn = dbn
        self.name = name
        self.numOfTestTakers = numOfTestTakers
        self.critReadingScore = critReadingScore
        self.mathScore = mathScore
        self.writingScore = writingScore
    }
    
    func printInfo() {
        print("dbn: \(self.dbn ?? "")")
        print("name: \(self.name ?? "")")
        print("numOfTestTakers: \(self.numOfTestTakers ?? "")")
        print("critReadingScore: \(self.critReadingScore ?? "")")
        print("mathScore: \(self.mathScore ?? "")")
        print("writingScore: \(self.writingScore ?? "") \n")
    }
}

class ViewController: UIViewController {
    var schoolDict = [String: [Any]]()
    var schoolDataStructArr = [SchoolDataStruct]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let schoolUrl = URL(string: "https://data.cityofnewyork.us/resource/97mf-9njv.json") else { return }
        
        let schoolTask = URLSession.shared.dataTask(with: schoolUrl) { (data, resp, err) in
            guard let dataResp = data,
                err == nil else {
                    print(err?.localizedDescription ?? "Error receiving data")
                    return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: dataResp, options: [])
                guard let jsonDict = json as? [[String: Any]] else {
                    print("couldn't transform json to [dict]")
                    return
                }
                for i in 0..<jsonDict.count {
                    self.schoolDict[jsonDict[i][Keys().dbn] as! String] = [jsonDict[i][Keys().schoolName] as! String]
                }
                
                self.getSATData()
            } catch let parsingErr {
                print("Error: \(parsingErr)")
            }
        }
        schoolTask.resume()
    }
    
    func getSATData() {
        guard let satURL = URL(string: "https://data.cityofnewyork.us/resource/734v-jeq5.json") else {
            return
        }
        
        let satTask = URLSession.shared.dataTask(with: satURL) { (data, resp, err) in
            guard let dataResp = data,
                err == nil else {
                    print(err?.localizedDescription ?? "Error receiving data")
                    return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: dataResp, options: [])
                guard let jsonDict = json as? [[String: Any]] else {
                    print("couldn't transform json to [dict]")
                    return
                }
                for i in 0..<jsonDict.count {
                    let schoolDBN = jsonDict[i][Keys().dbn] as! String
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
                    
                    // Update UI here
                    DispatchQueue.main.async {
                        
                    }
                }
            } catch let parsingErr {
                print("Error: \(parsingErr)")
            }
        }
        satTask.resume()
    }
}

