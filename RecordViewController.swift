//  RecordViewController.swift
//  HoopsCam
//
//  Created by Hans on 09/02/2018.
//  Copyright (c) 2018 Fresh Green. All rights reserved.
//

import AVFoundation
import AVKit
import UIKit
import CoreLocation


enum RecordStatus : Int {
    case none
    case recording
    case paused
}


var g_colorHome: UIColor = UIColor(red: (9/255.0), green: (42/255.0), blue: (86/255.0), alpha: 1)
var g_colorOpponent: UIColor = UIColor(red:  (29/255.0), green: (62/255.0), blue: (96/255.0), alpha: 1)
var g_homeName : String = "Home"
var g_homeNameShort : String = "Home"
var g_opponentName : String = "Opponent"
var g_opponentNameShort : String = "Oppo"
var g_isRecording: Bool = false
var g_isPaused: Bool = false
var g_isPeriodHalves: Bool = false
var g_recording4K: Bool = false
var g_periodNumber: Int = 0
var g_mainTitleText : String = ""
var g_secondTitleText : String = ""
var g_thirdTitleText : String = ""
var g_eventText : String = ""
var g_videoFileName: String = ""

var g_homeScore:Int = 0
var g_opponentScore:Int = 0

var g_clockSecs:Int = 0

var g_googleLocationUrl = String()
var g_locationAddressStr = String()


class RecordViewController: UIViewController {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var toolView: UIView!
    var recordHelper: CameraHelper?
    @IBOutlet weak var videoImageView: UIImageView!
    
    @IBOutlet weak var labHomeInitials: UILabel!
    @IBOutlet weak var labOpponentInitials: UILabel!
    
    @IBOutlet weak var btnHomeScoreUp: UIButton!
    @IBOutlet weak var btnHomeScoreDown: UIButton!
    
    @IBOutlet weak var btnHomeScoreDigitHi: UIButton!
    @IBOutlet weak var btnHomeScoreDigitLo: UIButton!
    
    @IBOutlet weak var btnPeriodUp: UIButton!
    @IBOutlet weak var btnPeriodDown: UIButton!
    @IBOutlet weak var btnPeriod: UIButton!
    
    
    @IBOutlet weak var btnOpponentScoreUp: UIButton!
    @IBOutlet weak var btnOpponentScoreDown: UIButton!
    
    
    @IBOutlet weak var btnOpponentScoreDigitHi: UIButton!
    @IBOutlet weak var btnOpponentScoreDigitLo: UIButton!
    
    @IBOutlet weak var labDateText: UILabel!
    @IBOutlet weak var labLocationText: UILabel!
    
    @IBOutlet weak var labEventText: UILabel!
    
    @IBOutlet var lbl_time: UILabel!

    @IBOutlet var lbl_title: UILabel!
    @IBOutlet var btn_record: UIButton!
    @IBOutlet var btn_pause: UIButton!
    var score_home: Int = 0
    var score_away: Int = 0
    var cover: String = ""
    var time: String = ""
    var recordStatus: RecordStatus?
    
    
    func setupDisplay()
    {
        
        g_homeScore = 0
        g_opponentScore = 0
        
        labHomeInitials.text = g_homeNameShort
        labHomeInitials.backgroundColor = g_colorHome
        labOpponentInitials.text = g_opponentNameShort
        labOpponentInitials.backgroundColor = g_colorOpponent
        
        if (g_isPeriodHalves == false) {
            var qtrPeriodIcons = ["Q1.png", "Q2.png", "Q3.png", "Q4.png", "OT.png"]
            btnPeriod.setImage(UIImage(named: qtrPeriodIcons[g_periodNumber]), for:[])
        }
        else {
            var halvesPeriodIcons = ["H1.png", "H2.png", "OT.png"]
            btnPeriod.setImage(UIImage(named: halvesPeriodIcons[g_periodNumber]), for:[])
        }
        updateHomeScore()
        updateOpponentScore()
        //var g_eventText = String()
        
    }
    func updateHomeScore()
    {
        btnHomeScoreDigitHi.setImage(getScoreHiDigitImage(g_homeScore), for: [])
        btnHomeScoreDigitLo.setImage(getScoreLoDigitImage(g_homeScore), for: [])
        
    }
    
    func updateOpponentScore()
    {
        btnOpponentScoreDigitHi.setImage(getScoreHiDigitImage(g_opponentScore), for: [])
        btnOpponentScoreDigitLo.setImage(getScoreLoDigitImage(g_opponentScore), for: [])
        
    }
    
    func getDigitImage(_ number: Int) -> UIImage {
        var digitListIcons = ["Zero.png", "One.png", "Two.png", "Three.png", "Four.png", "Five.png", "Six.png", "Seven.png", "Eight.png", "Nine.png"]
        //print ("Image number \(number) \n")
        return (UIImage(named: digitListIcons[number]))!
    }
    
    func getScoreHiDigitImage(_ number: Int) -> UIImage {
        var index : Int
        index = (number / 10) % 10
        return (getDigitImage(index))
    }
    func getScoreLoDigitImage(_ number: Int) -> UIImage {
        var index : Int
        index = number  % 10
        return (getDigitImage(index))
    }

    @IBAction func btnTagEventPressed(_ sender: Any) {
        
    }
    
    @IBAction func btnHomeScoreUp(_ sender: Any) {
        g_homeScore = g_homeScore + 1
        updateHomeScore()
    }
    
    @IBAction func btnHomeScoreDown(_ sender: Any) {
        g_homeScore = g_homeScore - 1
        updateHomeScore()
    }
    
    
    @IBAction func btnOpponentScoreUp(_ sender: Any) {
        print ("Opponent Score Up pressed")
        g_opponentScore = g_opponentScore + 1
        updateOpponentScore()
    }
    @IBAction func btnOpponentScoreDown(_ sender: Any) {
        print ("Opponent Score down pressed")
        g_opponentScore = g_opponentScore - 1
        updateOpponentScore()
    }
    
    
    @IBAction func btnPeriodUp(_ sender: Any) {
        if (g_isPeriodHalves == false) {
            var qtrPeriodIcons = ["Q1.png", "Q2.png", "Q3.png", "Q4.png", "OT.png"]
            if (g_periodNumber == 4) {
                
            }
            else {
                g_periodNumber = g_periodNumber + 1
            }
            btnPeriod.setImage(UIImage(named: qtrPeriodIcons[g_periodNumber]), for:[])
        }
        else {
            var halvesPeriodIcons = ["H1.png", "H2.png", "OT.png"]
            if (g_periodNumber == 2) {
                
            }
            else {
                g_periodNumber = g_periodNumber + 1
            }
            btnPeriod.setImage(UIImage(named: halvesPeriodIcons[g_periodNumber]), for:[])
        }
    }
    
    
    @IBAction func btnPeriodDown(_ sender: Any) {
        if (g_isPeriodHalves == false) {
            var qtrPeriodIcons = ["Q1.png", "Q2.png", "Q3.png", "Q4.png", "OT.png"]
            if (g_periodNumber == 0) {
                
            }
            else {
                g_periodNumber = g_periodNumber - 1
            }
            btnPeriod.setImage(UIImage(named: qtrPeriodIcons[g_periodNumber]), for:[])
        }
        else {
            var halvesPeriodIcons = ["H1.png", "H2.png", "OT.png"]
            if (g_periodNumber == 0) {
                
            }
            else {
                g_periodNumber = g_periodNumber - 1
            }
            btnPeriod.setImage(UIImage(named: halvesPeriodIcons[g_periodNumber]), for:[])
        }}
    
    

    
    func changeCover(_ t: String) -> Void {
        cover = t;
        lbl_title.text = cover
    }
    
    func changeTeamNamesColor() -> Void {
        labHomeInitials.text = g_homeNameShort
        labHomeInitials.backgroundColor = g_colorHome
        
        labOpponentInitials.text = g_opponentNameShort
        labOpponentInitials.backgroundColor = g_colorOpponent
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = true
        score_home = 0
        score_away = 0
        recordStatus = .none
        btn_record.isHidden = false
        btn_pause.isHidden = true
        time = "00 : 00 : 00"
        lbl_title.text = title
        lbl_title.isHidden = true
        labEventText.isHidden = true
        labDateText.isHidden = true
        labLocationText.isHidden = true
        setupDisplay()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubview(toFront: containerView)
        view.bringSubview(toFront: toolView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        recordHelper = CameraHelper()
        weak var weakSelf: RecordViewController? = self
        
        
        recordHelper?.imageCallback = {(_ image: UIImage?) -> Void in
            weakSelf?.videoImageView.image = image
        }
        
        recordHelper?.captureVideoPreviewLayer.frame = view.bounds
        recordHelper?.configSession()
    }
    
    @IBAction func startRecordAction(_ sender: Any) {
        weak var weakSelf: RecordViewController? = self
        if recordStatus == .none {
            let recorder = ScreenRecorder.sharedInstance()
            recorder?.durationCallback = {(_ duration: TimeInterval) -> Void in
                self.lbl_time.text = weakSelf?.niceTime(Int(duration))
            }
            recorder?.recordView = containerView
            if (recorder?.isRecording)! {
                
            }
            else {
                recorder?.startRecording(g_recording4K)
                print("Start recording")
                recordStatus = .recording
                lbl_title.text = g_mainTitleText
                labDateText.text = g_secondTitleText
                labLocationText.text = g_thirdTitleText
               
                btn_record.isHidden = true
                btn_pause.isHidden = false
                lbl_title.isHidden = false
                labDateText.isHidden = false
                labLocationText.isHidden = false
                perform(#selector(self.hideTitle), with: nil, afterDelay: 5)
            }
        }
        else if recordStatus == .paused {
            let recorder = ScreenRecorder.sharedInstance()
            recorder?.resumeRecording()
        }
    }
    
    @objc func hideTitle() {
        lbl_title.isHidden = true
        labDateText.isHidden = true
        labLocationText.isHidden = true
    }
    
    func niceTime(_ duration: Int) -> String {
        let h: Int = duration / 3600
        let m: Int = (duration % 3600) / 60
        let s: Int = duration - h * 3600 - m * 60
        time = String(format: "%02d : %02d : %02d", h, m, s)
        return time
    }
    
    @IBAction func pauseRecording(_ sender: Any) {
        recordStatus = .paused
        btn_record.isHidden = false
        btn_pause.isHidden = true
        let recorder = ScreenRecorder.sharedInstance()
        recorder?.pauseRecording()
    }
    
    @IBAction func saveRecording(_ sender: Any) {
        let fileName = "2018-06-05-home-away"
        if recordStatus != .none {
            Utils.sharedObject().showMBProgress(self.videoImageView, message: "Processing...");
            let recorder = ScreenRecorder.sharedInstance()
            recorder?.stopRecording(withCompletion: fileName, completion: {(_ videoPath: String?) -> Void in
                DispatchQueue.main.async(execute: {() -> Void in
                    Utils.sharedObject().hideMBProgress();
                    Utils.showSuccess("Video Saved!", to: self.videoImageView, afterDelay: 1.5);
                    self.recordStatus = .none
                    self.btn_record.isHidden = false
                    self.btn_pause.isHidden = true
                    self.lbl_time.text = "00 : 00 : 00"
                })
            });
        }
    }
    
    @IBAction func changeCameraAction(_ sender: Any) {
        let recorder = ScreenRecorder.sharedInstance()
        if recorder?.isRecording == false {
            recordHelper?.changeCamera()
        }
    }
}

