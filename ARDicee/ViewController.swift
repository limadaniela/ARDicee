//
//  ViewController.swift
//  ARDicee
//
//  Created by D L on 2023-01-11.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var diceArray = [SCNNode]()
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        
        cube.materials = [material]
        
        //node is a point in space
        let node = SCNNode()
        node.position = SCNVector3(0, 0.1, -0.5)
        
        node.geometry = cube
        
        //to add a childNode to rootNode in 3D scene
        sceneView.scene.rootNode.addChildNode(node)
        
        sceneView.autoenablesDefaultLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        //to enable horizontal detection in configuration
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //to detect touches in the screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //to check if touch does indeed contain an object
        if let touch = touches.first {
            //to detect touch location
            let touchLocation = touch.location(in: sceneView)
            //to convert touch location into 3D location inside our scene
            guard let query = sceneView.raycastQuery(from: touchLocation, allowing: .existingPlaneInfinite, alignment: .any) else {
                return
            }
            let result = sceneView.session.raycast(query)
            
            if let hitResult = result.first {
                // Create dicee
                let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
                
                // diceNode to create a 3D position to put dicee
                if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
                    diceNode.position = SCNVector3(
                        x: hitResult.worldTransform.columns.3.x,
                        y: hitResult.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                        z: hitResult.worldTransform.columns.3.z
                    )
                    
                    diceArray.append(diceNode)
                    
                    sceneView.scene.rootNode.addChildNode(diceNode)
                    
                    roll(dice: diceNode)
                }
            }
        }
    }
    
    func rollAll() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    func roll(dice: SCNNode) {
        //to randomly rotate the dicee along x and z axis
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        
        //multiply by 5 so the rotation looks more realistic
        dice.runAction(SCNAction.rotateBy(x: CGFloat(randomX * 5), y: 0, z: CGFloat(randomZ * 5), duration: 0.5))
    }
    
    //when pressing refresh it will roll all the dices
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    //when shaking the phone it will roll all the dices 
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    @IBAction func removeAllDice(_ sender: UIBarButtonItem) {
        
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    
    //when detecting a new horizontal surface, this func will give it a width and a height which is an AR anchor
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if anchor is ARPlaneAnchor {
            //planeAnchor is now equal to the anchor that we get back from the delegate method
            let planeAnchor = anchor as! ARPlaneAnchor
            //to convert the dimensions of anchor into a ScenePlane
            let plane = SCNPlane(width: CGFloat(planeAnchor.planeExtent.width), height: CGFloat(planeAnchor.planeExtent.height))
            let planeNode = SCNNode()
            //y is zero because is a flat horizontal plane
            planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
            //to convert the plane from vertical to horizontal
            //to rotate by 90 degrees, we need half pi radians
            planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
            let gridMaterial = SCNMaterial()
            gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [gridMaterial]
            planeNode.geometry = plane
            node.addChildNode(planeNode)
            
        } else {
            return
        }
    }
}

