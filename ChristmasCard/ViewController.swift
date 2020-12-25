/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var audioPlayer:AVAudioPlayer = AVAudioPlayer()
    
    var nowPage = 0
    
    var animationTime = 0.0
    
    var originalPos = SCNVector3()
    
    var animationDuration = 0.5
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    /// A serial queue for thread safety when modifying the SceneKit node graph.
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        let session = AVAudioSession.sharedInstance()
        do{
        //            启动音频会话的管理，此时会阻断后台音乐的播放
                    try session.setActive(true)
        //            设置音频操作类别，标示该应用仅支持音频的播放
            try session.setCategory(AVAudioSession.Category.playback)
        //            设置应用程序支持接受远程控制事件
                    UIApplication.shared.beginReceivingRemoteControlEvents()
                    
        //            定义一个字符常量，描述声音文件的路经
                    let path = Bundle.main.path(forResource: "BGM", ofType: "m4a")
        //            将字符串路径，转换为网址路径
                    let soudUrl = URL(fileURLWithPath: path!)
        //            对音频播放对象进行初始化，并加载指定的音频文件
                    try audioPlayer = AVAudioPlayer(contentsOf: soudUrl)
                    audioPlayer.prepareToPlay()
        //            设置音频播放对象的音量大小/
                    audioPlayer.volume = 1.0
        //            设置音频的播放次数，-1为无限循环
                    audioPlayer.numberOfLoops = 1
                } catch{
                    print(error)
                }
    
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true


        
        // Start the AR experience
        resetTracking()
	}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let button = self.createButton(title: "翻页", height: 0, action: #selector(ViewController.buttonTapNext))
        button.backgroundColor = UIColor(red: CGFloat(194)/CGFloat(255), green: CGFloat(35)/CGFloat(255), blue: CGFloat(35)/CGFloat(255), alpha: 0.5)
        button.setTitle("翻页", for: .normal)
        self.sceneView.addSubview(button)

    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}

    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true

    /// Creates a new AR configuration to run on the `session`.
    /// - Tag: ARReferenceImage-Loading
	func resetTracking() {
        
        nowPage = 0
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("Look around to detect images", inSeconds: 7.5, messageType: .contentPlacement)
	}

    // MARK: - ARSCNViewDelegate (Image detection results)
    /// - Tag: ARImageAnchor-Visualizing
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let referenceImage = imageAnchor.referenceImage
        self.nowPage = 0

        updateQueue.async {
            
            let cardSurfaceNode = self.createPlaneNode(size: CGSize(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height), rotation: 0, contents: UIImage(named: "surface.png")!)
            cardSurfaceNode.opacity = 1
            cardSurfaceNode.name = "surface@"
            
            let allcontent11 = self.createPlaneNode(size: CGSize(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height), rotation: 0, contents: UIImage(named: "allcontent1.1.png")!)
            allcontent11.name = "allcontent1.1@"

            let allcontent12 = self.createPlaneNode(size: CGSize(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height), rotation: 0, contents: UIImage(named: "allcontent1.2.png")!)
            allcontent12.name = "allcontent1.2@"
//            cardSurfaceBackNode.opacity = 1
            
            let allcontent21 = self.createPlaneNode(size: CGSize(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height), rotation: 0, contents: UIImage(named: "allcontent2.1.png")!)
            allcontent21.name = "allcontent2.1@"
            
            let allcontent22 = self.createPlaneNode(size: CGSize(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height), rotation: 0, contents: UIImage(named: "allcontent2.2.png")!)
            allcontent22.name = "allcontent2.2@"
            
            let cardContentBackNode = self.createPlaneNode(size: CGSize(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height), rotation: 0, contents: UIImage(named: "contentback.png")!)
            cardContentBackNode.name = "contentback@"

            
            let cardContentBack1Node = self.createPlaneNode(size: CGSize(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height), rotation: 0, contents: UIImage(named: "contentback1.png")!)
            cardContentBack1Node.name = "contentback1@"

            /*
             `SCNPlane` is vertically oriented in its local coordinate space, but
             `ARImageAnchor` assumes the image is horizontal in its local space, so
             rotate the plane to match.
             */
            cardContentBack1Node.eulerAngles.x = -.pi / 2
            cardContentBackNode.eulerAngles.x = .pi / 2
            allcontent22.eulerAngles.x = -.pi / 2
            allcontent21.eulerAngles.x = .pi / 2
            allcontent12.eulerAngles.x = -.pi / 2
            allcontent11.eulerAngles.x = .pi / 2
//            cardSurfaceBackNode.eulerAngles.z = cardSurfaceBackNode.eulerAngles.z - .pi / 4
            cardSurfaceNode.eulerAngles.x = -.pi / 2
            
            let cardnode = SCNNode();
            cardnode.transform = node.transform
            cardnode.name = "card"
            node.name = "picture"
            
            cardnode.addChildNode(cardContentBack1Node)
            cardnode.addChildNode(cardContentBackNode)
            cardnode.addChildNode(allcontent22)
            cardnode.addChildNode(allcontent21)
            cardnode.addChildNode(allcontent12)
            cardnode.addChildNode(allcontent11)
            cardnode.addChildNode(cardSurfaceNode)
            self.sceneView.scene.rootNode.addChildNode(cardnode)
        }

        DispatchQueue.main.async {
//            let imageName = referenceImage.name ?? ""

            self.statusViewController.cancelAllScheduledMessages()
            self.statusViewController.showMessage("找到贺卡啦！")
            self.audioPlayer.play()

        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let picnode = sceneView.scene.rootNode.childNode(withName: "picture", recursively: true) else{
            return
        }
        if simd_equal(simd_float3(picnode.position), simd_float3(originalPos))==false{
            originalPos = picnode.position
            animationTime = time
        }
        guard let cardnode = sceneView.scene.rootNode.childNode(withName: "card", recursively: true) else{
            return
        }
        cardnode.runAction(SCNAction.move(to: picnode.position, duration: animationDuration))
        
        let passedTime = time - animationTime
        var t = min(Float(passedTime/50), 1)
        // Applying curve function to time parameter to achieve "ease out" timing
        t = sin(t * .pi * 0.5)

        cardnode.simdWorldOrientation = simd_slerp(picnode.simdWorldOrientation, cardnode.simdWorldOrientation, t)

    }
    
    func createButton(title : String, height : CGFloat, action: Selector)->UIButton{
        let button = UIButton(frame: CGRect(x: self.sceneView.bounds.size.width/2-100, y: self.sceneView.bounds.size.height-height, width: 200, height: 100))
        button.layer.cornerRadius = 10
        button.addTarget(self, action: action, for: UIControl.Event.touchUpInside)
        return button
    }

    func createPlaneNode(size: CGSize, rotation: Float, contents: Any?) -> SCNNode {
        let plane = SCNPlane(width: size.width, height: size.height)
        plane.cornerRadius = size.width/CGFloat(50)
    //    plane.b
        plane.firstMaterial?.diffuse.contents = contents
        let planeNode = SCNNode(geometry: plane)
        
        planeNode.eulerAngles.x = rotation
        
        return planeNode
    }

    @objc func buttonTapNext(){
        switch nowPage {
        case 0:
            nowPage+=1
            guard let node1 = self.sceneView.scene.rootNode.childNode(withName: "surface@", recursively: true) else{
                return
            }
            let node2 = self.sceneView.scene.rootNode.childNode(withName: "allcontent1.1@", recursively: true)!
            node1.runAction(SCNAction.rotate(by:  .pi, around: SCNVector3(0,0,1), duration: 10))
            node2.runAction(SCNAction.rotate(by:  .pi, around: SCNVector3(0,0,1), duration: 10))
            break
        case 1:
            nowPage+=1
            guard let node1 = self.sceneView.scene.rootNode.childNode(withName: "allcontent1.2@", recursively: true) else{
                return
            }
            let node2 = self.sceneView.scene.rootNode.childNode(withName: "allcontent2.1@", recursively: true)!
            node1.runAction(SCNAction.rotate(by:  .pi-0.01, around: SCNVector3(0,0,1), duration: 10))
            node2.runAction(SCNAction.rotate(by:  .pi-0.01, around: SCNVector3(0,0,1), duration: 10))
            break
        case 2:
            nowPage+=1
            guard let node1 = self.sceneView.scene.rootNode.childNode(withName: "allcontent2.2@", recursively: true) else{
                return
            }
            let node2 = self.sceneView.scene.rootNode.childNode(withName: "contentback@", recursively: true)!
            node1.runAction(SCNAction.rotate(by:  .pi-0.02, around: SCNVector3(0,0,1), duration: 10))
            node2.runAction(SCNAction.rotate(by:  .pi-0.02, around: SCNVector3(0,0,1), duration: 10))
            break
        default:
            DispatchQueue.main.async {
                self.statusViewController.showMessage("没法翻页喔")
            }

        }
        
    }
}
