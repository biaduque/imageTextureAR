//
//  ViewController.swift
//  POCTestModels
//
//  Created by João Pimenta on 02/06/22.
//

import UIKit
import RealityKit
import SceneKit
import ARKit
import PhotosUI


class ViewController: UIViewController, ARSessionDelegate {
    
    
    
    @IBOutlet var arView: ARView!
    
    // materiais pro modelo
    var material = SimpleMaterial()
    var anchorEntity = AnchorEntity()
    var modelEntity = ModelEntity()
    var planeMesh = MeshResource.generatePlane(width: 0.5, height: 0.5,cornerRadius: 0.06)
    // imagem para o modelo
    var imagePicker: ImagePicker!
    var newPhoto = "defaultImage"
    var photo = "defaultImage" {
        didSet { self.photo = newPhoto } 
    }
    
    //Label que mostra o tempo
    //usar isHidden para não mostrar
    @IBOutlet weak var countdownLabel: UILabel!
    
    //criando timer
    var timer: Timer = Timer()
    //variavel para setar o tempo inicial
    var timeLeft: Int = 5
    //variavel para verificar acionamento do botão
    var buttonPressed: Bool = false
    
    @IBOutlet weak var feedbackView: UIView!
    @IBOutlet weak var feedbackLabel: UIButton!
    
    
    override func viewDidLoad() {
        countdownLabel.isHidden = true
        feedbackLabel.isHidden = true
        super.viewDidLoad()
        let boxAnchor = try! Experience.loadCena()
        arView.scene.anchors.append(boxAnchor)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        arView.session.delegate = self
        arView.session.run(config)
        imagePicker = ImagePicker(presentationController: self, delegate: self)

    }
    
    func setMaterialToPhoto() {
        let createFace = CreateFace()
        self.material = createFace.createFace(photo: self.newPhoto)
        self.modelEntity = ModelEntity(mesh: self.planeMesh,
                                       materials: [self.material])
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        self.anchorEntity.removeChild(modelEntity)
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                
                self.anchorEntity = AnchorEntity(anchor: planeAnchor)
                arView.scene.anchors.append(self.anchorEntity)
            }
        }
        self.setMaterialToPhoto()
        anchorEntity.addChild(modelEntity)
    }
   
    @IBAction func clickButton(_ sender: Any) {

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        let takeImage = ARPhotoManager()
        takeImage.takePhoto(view: self.arView)
        takeImage.feedBackScreen(view: self.feedbackView)
        takeImage.feedBackLabel(button: self.feedbackLabel)


    }
    
    @IBAction func addPhoto(_ sender: Any) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        let photos = PHPhotoLibrary.authorizationStatus()
            if photos == .notDetermined {
                PHPhotoLibrary.requestAuthorization({status in
                    if status != .denied{
                       print("Acesso permitido")
                    } else {
                       print("Acesso nao permitido")
                    }
                })
            }
        else {
            self.imagePicker.present(from: sender as! UIView)
        }
    }
    
    @IBAction func countdownButton(_ sender: Any) {
        countdownLabel.isHidden = false
        //aplicando HapticFeedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        //funçao de contagem regressiva para foto
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
    }
    
    @objc func timerCounter() -> Void{
        if timeLeft > 1 {
            timeLeft -= 1
        }
        else {
            timer.invalidate()
            timeLeft = 5
            countdownLabel.isHidden = true
            let takeImage = ARPhotoManager()
            takeImage.takePhoto(view: self.arView)
            takeImage.feedBackScreen(view: self.feedbackView)
            takeImage.feedBackLabel(button: self.feedbackLabel)
        }
        var textNumber = String(timeLeft)
        countdownLabel.text = textNumber
    }
    
    
    
}

extension ViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        PhotoManager.deleteImage(path: photo)
        self.newPhoto = PhotoManager.saveToFiles(image: image)
        let createFace = CreateFace()
        self.material = createFace.createFace(photo: self.newPhoto)
        self.modelEntity.model?.materials = [self.material]
        
    }
}
