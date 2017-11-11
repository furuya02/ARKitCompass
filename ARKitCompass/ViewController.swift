//
//  ViewController.swift
//  ARKitCompass
//
//  Created by . SIN on 2017/11/11.
//  Copyright © 2017年 SAPPOROWORKS. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    var compassNode: SCNNode? = nil
    var locationManager: CLLocationManager!
    var angle: Double = -1

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.showsStatistics = true
        sceneView.scene = SCNScene()
        sceneView.autoenablesDefaultLighting = true
        
        if let compassScene = SCNScene(named: "art.scnassets/Compass.scn") {
            if let node = compassScene.rootNode.childNode(withName: "compass", recursively: true) {
                compassNode = node
                sceneView.scene.rootNode.addChildNode(node)
            }
        }
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
        angle = -1
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let camera = sceneView.pointOfView else { return }
        let position = SCNVector3(x: 0, y: -1.5, z: 0) // 偏差(自分を中心に、1.5m下方)
        compassNode?.position = camera.convertPosition(position, to: nil) // カメラ位置からの偏差に変換する
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("ユーザーはこのアプリケーションに関してまだ選択を行っていません")
            locationManager.requestWhenInUseAuthorization() // 起動中のみの取得許可を求める
            break
        case .denied:
            print("ローケーションサービスの設定が「無効」になっています (ユーザーによって、明示的に拒否されています）")
            // 「設定 > プライバシー > 位置情報サービス で、位置情報サービスの利用を許可して下さい」を表示する
            break
        case .restricted:
            print("このアプリケーションは位置情報サービスを使用できません(ユーザによって拒否されたわけではありません)")
            // 「このアプリは、位置情報を取得できないために、正常に動作できません」を表示する
            break
        case .authorizedAlways:
            print("常時、位置情報の取得が許可されています。")
            // 位置情報取得の開始処理
            break
        case .authorizedWhenInUse:
            print("起動時のみ、位置情報の取得が許可されています。")
            locationManager.headingFilter = kCLHeadingFilterNone
            locationManager.headingOrientation = .portrait
            locationManager.startUpdatingHeading()
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if angle == -1 { // コンパスの回転を初期化する
            angle = newHeading.magneticHeading
            compassNode?.rotation = SCNVector4(0, 1, 0, (angle / 180) * Double.pi)
        }
    }
}
