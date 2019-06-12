//
//  CustomViewController.swift
//  CustomLayoutSample
//
//  Copyright © 2017 Vidyo. All rights reserved.
//

import UIKit

class CustomViewController: UIViewController, VCConnectorIConnect,
    
    // Remote devices
    VCConnectorIRegisterRemoteCameraEventListener,
    VCConnectorIRegisterRemoteMicrophoneEventListener,
    
    // Local devices
    VCConnectorIRegisterLocalCameraEventListener,
    VCConnectorIRegisterLocalMicrophoneEventListener,
    VCConnectorIRegisterLocalSpeakerEventListener,
    
    // Participant events
    VCConnectorIRegisterParticipantEventListener {

    // MARK: - Properties and variables
    
    @IBOutlet var remoteViews: UIView!
    @IBOutlet var selfView: UIView!
    
    @IBOutlet weak var micButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    
    private var connector: VCConnector?
    
    private var remoteViewsMap:[String:UIView] = [:]
    private var numberOfRemoteViews = 0

    private var micMuted            = false
    private var cameraMuted         = false
    private var expandedSelfView    = false
    
    private static let MAX_REMOTE_PARTICIPANT = 4
    private let HOST = "prod.vidyo.io"

    /* Get a valid token. It is recommended that you create short lived tokens on your applications server and then pass it down here.
     * For details on how to get a token check out - https://static.vidyo.io/latest/docs/VidyoConnectorDeveloperGuide.html#tokens */
    private let VIDYO_TOKEN = "REPLACE_WITH_YOUR_TOKEN"
    
    var displayName     = "Demo User"
    var resourceID      = "demoRoom"
    
    private var hasDevicesSelected = false

    // Remember selected local camera reference
    private var lastSelectedCamera: VCLocalCamera?
    
    // MARK: - Viewcontroller override methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        selfView.frame.size.width   = UIScreen.main.bounds.size.width / 4
        selfView.frame.size.height  = UIScreen.main.bounds.size.height / 4
        
        selfView.layer.borderColor  = UIColor.black.cgColor
        selfView.layer.borderWidth  = 1.0
        
        // Setting tap gesture on the self view
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.toggleSelfView))
        selfView.addGestureRecognizer(tap)
        
        // Create VidyoIO connector object
        connector = VCConnector(nil, // For custom handling of views, set this to nil
                                viewStyle: .default, // Passing default,
                                remoteParticipants: 15, // This argument does not have any meaning in a custom layout.
                                logFileFilter: UnsafePointer("info@VidyoClient info@VidyoConnector warning"),
                                logFileName: UnsafePointer(""),
                                userData: 0)
        
        // When For custom view we need to register to all the device events
        if connector != nil {
            connector?.registerLocalCameraEventListener(self)
            connector?.registerRemoteCameraEventListener(self)
            connector?.registerLocalSpeakerEventListener(self)
            connector?.registerLocalMicrophoneEventListener(self)
            connector?.registerParticipantEventListener(self)
        }
        
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
        
        self.connector?.connect(HOST,
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
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - NotificationCenter UI application lifecycle events
    
    @objc func willEnterForeground() {
        guard let connector = connector else {
            return
        }
        
        connector.setMode(.foreground)
        
        if !hasDevicesSelected {
            connector.selectDefaultMicrophone()
            connector.selectDefaultSpeaker()
            
            hasDevicesSelected = true
        }
        
        hideShowPreview(cameraMuted)
    }
    
    @objc func didEnterBackground() {
        guard let connector = connector else {
            return
        }
        
        // Release mic and speaker if not on a call
        if !isInCallingState() {
            connector.select(nil as VCLocalMicrophone?)
            connector.select(nil as VCLocalSpeaker?)
            
            hasDevicesSelected = false
        }
        
        hideShowPreview(true /* always mute camera stream for background mode */)

        connector.setMode(.background)
    }
    
    @objc func onOrientationChanged() {
        self.refreshUI()
    }
    
    // MARK: Custom gesture recognizer selector
    
    @objc func toggleSelfView() {
        self.expandedSelfView = !self.expandedSelfView
        
        UIView.animate(withDuration: 0.5, animations: {
            if self.expandedSelfView {
                self.selfView.frame.size.width  = UIScreen.main.bounds.size.width / 2
                self.selfView.frame.size.height = UIScreen.main.bounds.size.height / 2
            } else {
                self.selfView.frame.size.width  = UIScreen.main.bounds.size.width / 4
                self.selfView.frame.size.height = UIScreen.main.bounds.size.height / 4
            }
            self.selfView.frame.origin.x = UIScreen.main.bounds.size.width - self.selfView.frame.size.width - 10
            self.selfView.frame.origin.y = UIScreen.main.bounds.size.height - self.selfView.frame.size.height - 60
            self.connector?.showView(at: UnsafeMutableRawPointer(&self.selfView),
                                     x: 0,
                                     y: 0,
                                     width: UInt32(self.selfView.frame.size.width),
                                     height: UInt32(self.selfView.frame.size.height))
        }, completion:nil)
    }
    
    // MARK: - IConnect delegate methods
    
    func onSuccess() {
        print("Connection Successful.")
    }
    
    func onFailure(_ reason: VCConnectorFailReason) {
        print("Connection failed \(reason)")
        
        closeConference()
    }
    
    func onDisconnected(_ reason: VCConnectorDisconnectReason) {
        print("Call Disconnected")
        
        closeConference()
    }
    
    // MARK: - IRegisterParticipantEventListener delegate methods
    
    func onParticipantLeft(_ participant: VCParticipant!) {
        
    }
    
    func onParticipantJoined(_ participant: VCParticipant!) {
        
    }
    
    func onLoudestParticipantChanged(_ participant: VCParticipant!, audioOnly: Bool) {
        
    }
    
    func onDynamicParticipantChanged(_ participants: NSMutableArray!) {
                
    }
    
    // MARK: - IRegisterLocalSpeakerEventListener delegate methods
    
    func onLocalSpeakerAdded(_ localSpeaker: VCLocalSpeaker!) {
        
    }
    
    func onLocalSpeakerRemoved(_ localSpeaker: VCLocalSpeaker!) {
        
    }
    
    func onLocalSpeakerSelected(_ localSpeaker: VCLocalSpeaker!) {
        
    }
    
    func onLocalSpeakerStateUpdated(_ localSpeaker: VCLocalSpeaker!, state: VCDeviceState) {
        
    }
    
    // MARK: - IRegisterLocalMicrophoneEventListener delegate methods
    
    func onLocalMicrophoneAdded(_ localMicrophone: VCLocalMicrophone!) {
        
    }
    
    func onLocalMicrophoneRemoved(_ localMicrophone: VCLocalMicrophone!) {
        
    }
    
    func onLocalMicrophoneSelected(_ localMicrophone: VCLocalMicrophone!) {
        
    }
    
    func onLocalMicrophoneStateUpdated(_ localMicrophone: VCLocalMicrophone!, state: VCDeviceState) {
        
    }
    
    // MARK: - IRegisterRemoteMicrophoneEventListener delegate methods

    func onRemoteMicrophoneAdded(_ remoteMicrophone: VCRemoteMicrophone!, participant: VCParticipant!) {
        
    }
    
    func onRemoteMicrophoneRemoved(_ remoteMicrophone: VCRemoteMicrophone!, participant: VCParticipant!) {
        
    }
    
    func onRemoteMicrophoneStateUpdated(_ remoteMicrophone: VCRemoteMicrophone!, participant: VCParticipant!, state: VCDeviceState) {
        
    }
    
    // MARK: - IRegisterLocalCameraEventListener delegate methods
    
    func onLocalCameraRemoved(_ localCamera: VCLocalCamera!) {
        DispatchQueue.main.async {
            [weak self] in
            
            guard let this = self else {
                print("Can't maintain self reference.")
                return
            }
            
            this.selfView.isHidden = true
        }
    }
    
    func onLocalCameraAdded(_ localCamera: VCLocalCamera!) {
    }
    
    func onLocalCameraSelected(_ localCamera: VCLocalCamera!) {
        if (localCamera != nil) {
            self.lastSelectedCamera = localCamera
            
            DispatchQueue.main.async {
                [weak self] in
                
                guard let this = self else {
                    print("Can't maintain self reference.")
                    return
                }
                
                this.selfView.isHidden = false
                this.connector?.assignView(toLocalCamera: UnsafeMutableRawPointer(&this.selfView),
                                     localCamera: localCamera,
                                     displayCropped: true,
                                     allowZoom: false)
                this.connector?.showViewLabel(UnsafeMutableRawPointer(&this.selfView),
                                        showLabel: false)
                this.connector?.showView(at: UnsafeMutableRawPointer(&this.selfView),
                                   x: 0,
                                   y: 0,
                                   width: UInt32(this.selfView.bounds.size.width),
                                   height: UInt32(this.selfView.bounds.size.height))
            }
        }
    }
    
    func onLocalCameraStateUpdated(_ localCamera: VCLocalCamera!, state: VCDeviceState) {
    }
    
    // MARK: - IRegisterRemoteCameraEventListener delegate methods
    
    func onRemoteCameraAdded(_ remoteCamera: VCRemoteCamera!, participant: VCParticipant!) {
        numberOfRemoteViews += 1
        DispatchQueue.main.async {
            [weak self] in
            
            guard let this = self else {
                print("Can't maintain self reference.")
                return
            }
            
            var newRemoteView = UIView()
            newRemoteView.layer.borderColor = UIColor.black.cgColor
            newRemoteView.layer.borderWidth = 1.0
            this.remoteViews.addSubview(newRemoteView)
            this.remoteViewsMap[participant.getId()] = newRemoteView
            this.connector?.assignView(toRemoteCamera: UnsafeMutableRawPointer(&newRemoteView),
                                       remoteCamera: remoteCamera,
                                       displayCropped: true,
                                       allowZoom: true)
            this.connector?.showViewLabel(UnsafeMutableRawPointer(&newRemoteView),
                                          showLabel: false)
            
            // Adding custom UILabel to show the participant name
            let newParticipantNameLabel = UILabel()
            newParticipantNameLabel.text = participant.getName()
            newParticipantNameLabel.textColor = UIColor.white
            newParticipantNameLabel.textAlignment = .center
            newParticipantNameLabel.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            newParticipantNameLabel.shadowOffset = CGSize(width: 1, height: 1)
            newParticipantNameLabel.font = newParticipantNameLabel.font.withSize(14)
            newRemoteView.addSubview(newParticipantNameLabel)
            
            this.refreshUI()
        }
    }
    
    func onRemoteCameraRemoved(_ remoteCamera: VCRemoteCamera!, participant: VCParticipant!) {
        numberOfRemoteViews -= 1
        DispatchQueue.main.async {
            [weak self] in
            
            guard let this = self else {
                print("Can't maintain self reference.")
                return
            }
            
            let remoteView = this.remoteViewsMap.removeValue(forKey: participant.getId())
            for view in (remoteView?.subviews)!{
                view.removeFromSuperview()
            }
            remoteView?.removeFromSuperview()
        
            this.refreshUI()
        }
    }
    
    func onRemoteCameraStateUpdated(_ remoteCamera: VCRemoteCamera!, participant: VCParticipant!, state: VCDeviceState) {
        
    }

    // MARK: - UI Actions
    
    @IBAction func cameraClicked(_ sender: Any) {
        cameraMuted = !cameraMuted
        self.cameraButton.setImage(UIImage(named: cameraMuted ? "cameraOff.png" : "cameraOn.png"), for: .normal)
        
        hideShowPreview(cameraMuted)
    }
    
    @IBAction func micClicked(_ sender: Any) {
        micMuted = !micMuted
        self.micButton.setImage(UIImage(named: micMuted ? "microphoneOff.png" : "microphoneOn.png"), for: .normal)
        connector?.setMicrophonePrivacy(micMuted)
    }
    
    @IBAction func callClicked(_ sender: Any) {
        if isInCallingState() {
            connector?.disconnect()
        } else {
            closeConference()
        }
    }
    
    // MARK: - Class methods
    
    private func refreshUI() {
        DispatchQueue.main.async {
            
            // Updating local (self) view
            if self.expandedSelfView {
                self.selfView.frame.size.width  = UIScreen.main.bounds.size.width / 2
                self.selfView.frame.size.height = UIScreen.main.bounds.size.height / 2
            } else {
                self.selfView.frame.size.width  = UIScreen.main.bounds.size.width / 4
                self.selfView.frame.size.height = UIScreen.main.bounds.size.height / 4
            }
            
            self.selfView.frame.origin.x = UIScreen.main.bounds.size.width - self.selfView.frame.size.width - 10
            self.selfView.frame.origin.y = UIScreen.main.bounds.size.height - self.selfView.frame.size.height - 60
            
            self.connector?.showView(at: UnsafeMutableRawPointer(&self.selfView),
                                     x: 0,
                                     y: 0,
                                     width: UInt32(self.selfView.frame.size.width),
                                     height: UInt32(self.selfView.frame.size.height))
            
            
            // Updating remote views
            let refFrames   = RemoteViewLayout.getTileFrames(numberOfTiles: self.numberOfRemoteViews)
            var index       = 0
            for var remoteView in self.remoteViewsMap.values {
                let refFrame        = refFrames[index] as! CGRect
                remoteView.frame    = refFrame
                self.connector?.showView(at: UnsafeMutableRawPointer(&remoteView),
                                         x: 0,
                                         y: 0,
                                         width: UInt32(refFrame.size.width),
                                         height: UInt32(refFrame.size.height))
                
                // updating label location
                for subview in remoteView.subviews
                {
                    if let item = subview as? UILabel
                    {
                        item.frame = CGRect(x: 0,
                                            y: 10,
                                            width: remoteView.frame.width,
                                            height: 20)
                    }
                }
                
                index += 1
                if index >= CustomViewController.MAX_REMOTE_PARTICIPANT {
                    // Showing max 4 remote participants
                    break
                }
            }
        }
    }
    
    private func hideShowPreview(_ cameraMuted: Bool) {
        connector?.setCameraPrivacy(cameraMuted)
        self.selfView.isHidden = cameraMuted
        
        if (cameraMuted) {
            /* This action is mandatory because camera access is restricted in background.
             * Camera should be released whenever we are in call state or not.
             * Specific case for custom layouts since privacy is not shutting down local steam. */
            connector?.setCameraPrivacy(true)
            connector?.select(nil as VCLocalCamera?)
            // Will release camera. You have to reassing it back later on.
            connector?.hideView(UnsafeMutableRawPointer(&self.selfView))
        } else {
            // Reselect local camera. Will trigger onLocalCameraSelected accordingly.
            if lastSelectedCamera != nil {
                connector?.select(lastSelectedCamera)
            }
        }
    }
    
    private func isInCallingState() -> Bool {
        if let connector = connector {
            let state = connector.getState()
            return state != .idle && state != .ready
        }
        
        return false
    }
    
    private func closeConference() {
        DispatchQueue.main.async {
            [weak self] in
            
            guard let this = self else {
                print("Can't maintain self reference.")
                return
            }
            
            this.dismiss(animated: true, completion: nil)
        }
    }
}
