//
//  CompositedViewController.swift
//  CustomLayoutSample
//
//  Copyright © 2017 Vidyo. All rights reserved.
//

import UIKit

class CompositedViewController : UIViewController, VCConnectorIConnect {

    // MARK: - Properties and variables

    @IBOutlet weak var vidyoView: UIView!
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    private var connector:VCConnector?
    var resourceID      = ""
    var displayName     = ""
    var micMuted        = false
    var cameraMuted     = false
    let VIDYO_TOKEN     = "" // Get a valid token. It is recommended that you create short lived tokens on your applications server and then pass it down here. For details on how to get a token check out - https://developer.vidyo.io/documentation/4-1-19-7/getting-started#Tokens
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder :aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CompositedViewController.refreshUI), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        connector = VCConnector(UnsafeMutableRawPointer(&vidyoView),
                              viewStyle: .default,
                              remoteParticipants: 4,
                              logFileFilter: UnsafePointer("info@VidyoClient info@VidyoConnector warning"),
                              logFileName: UnsafePointer(""),
                              userData: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.refreshUI()
        connector?.connect("prod.vidyo.io",
                          token: VIDYO_TOKEN,
                          displayName: "Demo User",
                          resourceId: "demoRoom",
                          connectorIConnect: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        connector?.disable()
        connector = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func refreshUI() {
        DispatchQueue.main.async {
            self.connector?.showView(at: UnsafeMutableRawPointer(&self.vidyoView),
                                    x: 0,
                                    y: 0,
                                    width: UInt32(self.vidyoView.frame.size.width),
                                    height: UInt32(self.vidyoView.frame.size.height))
        }
    }
    
    // MARK: - IConnect delegate methods

    func onSuccess() {
        print("Connection Successful")
    }
    
    func onFailure(_ reason: VCConnectorFailReason) {
        print("Connection failed \(reason)")
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func onDisconnected(_ reason: VCConnectorDisconnectReason) {
        print("Call Disconnected")
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
   
    // MARK: - Actions
    
    @IBAction func cameraClicked(_ sender: Any) {
        if cameraMuted {
            cameraMuted = !cameraMuted
            self.cameraButton.setImage(UIImage(named: "cameraOn.png"), for: .normal)
            connector?.setCameraPrivacy(cameraMuted)
        } else {
            cameraMuted = !cameraMuted
            self.cameraButton.setImage(UIImage(named: "cameraOff.png"), for: .normal)
            connector?.setCameraPrivacy(cameraMuted)
        }
    }

    @IBAction func micClicked(_ sender: Any) {
        if micMuted {
            micMuted = !micMuted
            self.micButton.setImage(UIImage(named: "microphoneOn.png"), for: .normal)
            connector?.setMicrophonePrivacy(micMuted)
        } else {
            micMuted = !micMuted
            self.micButton.setImage(UIImage(named: "microphoneOff.png"), for: .normal)
            connector?.setMicrophonePrivacy(micMuted)
        }
    }
    
    @IBAction func callClicked(_ sender: Any) {
        connector?.disconnect()
    }
}
