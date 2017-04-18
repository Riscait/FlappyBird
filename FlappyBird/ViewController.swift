//
//  ViewController.swift
//  FlappyBird
//
//  Created by 村松龍之介 on 2017/04/17.
//  Copyright © 2017年 ryunosuke.muramatsu. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // SKViewに型を変換する
        let skView = self.view as! SKView
        
        // FPSを表示
        skView.showsFPS = true
        
        // ノードの数を表示
        skView.showsNodeCount = true
        
        // ビューと同じサイズでシーンを作成
        let scene = GameScene(size: skView.frame.size)
        
        // ビューにシーンを表示する
        skView.presentScene(scene)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // ステータスバーを非表示
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }
    
}

