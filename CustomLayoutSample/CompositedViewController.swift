//
//  CompositedViewController.swift
//  CustomLayoutSample
//
//  Copyright © 2017 Vidyo. All rights reserved.
//

import UIKit

class CompositedViewController : UIViewController, VCConnectorIConnect {
    
    // MARK: - Properties and variables
    
    @IBOutlet var vidyoView: UIView!
    
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    private var connector: VCConnector?
    
    private let HOST = "prod.vidyo.io"
    
    /* Get a valid token. It is recommended that you create short lived tokens on your applications server and then pass it down here.
     * For details on how to get a token check out - https://static.vidyo.io/latest/docs/VidyoConnectorDeveloperGuide.html#tokens */
    private let VIDYO_TOKEN = "REPLACE_WITH_YOUR_TOKEN"
    
    var displayName     = "Demo User"
    var resourceID      = "demoRoom"
    
    private  var micMuted        = false
    private var cameraMuted     = false
    
    private var hasDevicesSelected = false
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder :aDecoder)
    }
    
    // MARK: - ViewController lifecycle events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        connector = VCConnector(UnsafeMutableRawPointer(&vidyoView),
                                viewStyle: .default,
                                remoteParticipants: 4,
                                logFileFilter: UnsafePointer("info@VidyoClient info@VidyoConnector warning"),
                                logFileName: UnsafePointer(""),
                                userData: 0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onOrientationChanged),
                                               name: .UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground),
                                               name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.refreshUI()
        
        connector?.connect(HOST,
                           token: VIDYO_TOKEN,
                           displayName: displayName,
                           resourceId: resourceID,
                           connectorIConnect: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        connector?.disable()
        connector = nil
    }
    
    // MARK: - NotificationCenter observers: UI application lifecycle events
    
    @objc func willEnterForeground() {
        guard let connector = connector else {
            return
        }
        
        connector.setMode(.foreground)
        
        if !hasDevicesSelected {
            connector.selectDefaultCamera()
            connector.selectDefaultMicrophone()
            connector.selectDefaultSpeaker()
            
            hasDevicesSelected = true
        }
        
        connector.setCameraPrivacy(cameraMuted)
    }
    
    @objc func didEnterBackground() {
        guard let connector = connector else {
            return
        }
        
        if isInCallState() {
            connector.setCameraPrivacy(true)
        } else {
            connector.select(nil as VCLocalCamera?)
            connector.select(nil as VCLocalMicrophone?)
            connector.select(nil as VCLocalSpeaker?)
            
            hasDevicesSelected = false
        }
        
        connector.setMode(.background)
    }
    
    @objc func onOrientationChanged() {
        self.refreshUI();
    }
    
    // MARK: - IConnect delegate methods
    
    func onSuccess() {
        print("Connection Successful")
    }
    
    func onFailure(_ reason: VCConnectorFailReason) {
        print("Connection failed \(reason)")
        closeConference()
    }
    
    func onDisconnected(_ reason: VCConnectorDisconnectReason) {
        print("Call Disconnected")
        closeConference()
    }
    
    // MARK: - UI Actions
    
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
        if isInCallState() {
            connector?.disconnect()
        } else {
            closeConference()
        }
    }
    
    // MARK: - Refresh renderer
    
    private func refreshUI() {
        DispatchQueue.main.async {
            [weak self] in
            
            guard let this = self else {
                fatalError("Can't maintain self reference.")
            }
            
            this.connector?.showView(at: UnsafeMutableRawPointer(&this.vidyoView),
                                     x: 0,
                                     y: 0,
                                     width: UInt32(this.vidyoView.frame.size.width),
                                     height: UInt32(this.vidyoView.frame.size.height))
        }
    }
    
    // MARK: Private functions
    
    private func isInCallState() -> Bool {
        if let connector = connector {
            let state = connector.getState()
            return state != .idle || state != .ready
        }
        
        return false
    }
    
    private func closeConference() {
        DispatchQueue.main.async {
            [weak self] in
            
            guard let this = self else {
                fatalError("Can't maintain self reference.")
            }
            
            this.dismiss(animated: true, completion: nil)
        }
    }
}
