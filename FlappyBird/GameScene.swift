//
//  GameScene.swift
//  FlappyBird
//
//  Created by 村松龍之介 on 2017/04/17.
//  Copyright © 2017年 ryunosuke.muramatsu. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var scrollNode: SKNode!
    var wallNode: SKNode!
    var bird: SKSpriteNode!
    var fish: SKSpriteNode!
    
    
    // 衝突判定カテゴリー
    let birdCategory: UInt32 = 1 << 0       // 00000000000000000000000000000001
    let groundCategory: UInt32 = 1 << 1     // 00000000000000000000000000000010
    let wallCategory: UInt32 = 1 << 2       // 00000000000000000000000000000100
    let scoreCategory: UInt32 = 1 << 3      // 00000000000000000000000000001000
    let fishCategory: UInt32 = 1 << 4      // 00000000000000000000000000010000
    
    
    // スコア用
    var score = 0
    var scoreLabelNode: SKLabelNode!
    var bestScoreLabelNode: SKLabelNode!
    var itemScore = 0
    var itemScoreLabelNode: SKLabelNode!
    
    let userDefaults: UserDefaults = UserDefaults.standard
    
    // BGM
    let bgm = SKAction.playSoundFileNamed("ゆかいな日常.mp3", waitForCompletion: true)
    
    // 効果音
    let meow = SKAction.playSoundFileNamed("猫01.mp3", waitForCompletion: true)
    let meow2 = SKAction.playSoundFileNamed("にゃあ.mp3", waitForCompletion: true)
    
    // SKView上にシーンが表示された時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        // BGMをループして再生
        let loopBgm = SKAction.repeatForever(bgm)
        self.run(loopBgm)
        
        // 重力を設定
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)
        physicsWorld.contactDelegate = self
        
        // 背景色を設定
        backgroundColor = UIColor(colorLiteralRed: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        // スクロールするスプライトの親ノード
        scrollNode = SKNode()
        addChild(scrollNode)
        
        // 壁用のノード
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        // 秋刀魚用のノード
        fish = SKSpriteNode()
        scrollNode.addChild(fish)
        
        // 各種スプライトを生成する処理をメソッドに分割
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupFish()
        setupScoreLabel()
    }
    
    // SKPhysicsCintactDelegateのメソッド。衝突した時に呼ばれる
    func didBegin(_ contact: SKPhysicsContact) {
        // ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0 {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            // スコア用の物体と衝突した
            print("ScoreUP!")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            // ベストスコアか確認する
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()
                print("BestScore!!")
            }
        } else if (contact.bodyA.categoryBitMask & fishCategory) == fishCategory || (contact.bodyB.categoryBitMask & fishCategory) == fishCategory {
            // アイテムと接触した
            print("ItemGet!")
            itemScore += 1
            itemScoreLabelNode.text = "Item:\(itemScore)"
            self.run(meow2)
            fish.removeAllChildren()
        } else {
            // 地面と衝突した
            print("GameOver!")
            self.run(meow)
            
            // スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion:{
                self.bird.speed = 0
            })
        }
    }
    
    // 画面をタップした時に呼ばれる
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed > 0 {
            // 鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
        
            // 鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 35))
        } else if bird.speed == 0 {
            restart()
        }
    }
    
    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"
        itemScore = 0
        itemScoreLabelNode.text = "Item:\(itemScore)"
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.zRotation = 0.0
        
        wallNode.removeAllChildren()
        fish.removeAllChildren()
        
        bird.speed = 1
        scrollNode.speed = 1
    }
    
    func setupGround() {
        // 地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = SKTextureFilteringMode.nearest
        
        // 必要な枚数を計算
        let needNumber = 2.0 + (frame.size.width / groundTexture.size().width)
        
        // スクロールするアクションを作成
        // 左方向に画像一枚分スクロールさせるアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5.0)
        
        // 元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール -> 元の位置 -> 左にスクロール と無限に繰り替えるアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround, resetGround]))
        
        // groundのスプライトを配置する
        stride(from: 0.0, to: needNumber, by: 1.0).forEach { i in
            // テクスチャーを指定してスプライトを作成する
            let sprite = SKSpriteNode(texture: groundTexture)
        
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height / 2)
        
            // スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            // 物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            
            // 衝突のカテゴリーを設定
            sprite.physicsBody?.categoryBitMask = groundCategory
            
            // 衝突の時に動かないように設定
            sprite.physicsBody?.isDynamic = false
            
            // シーンにスプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud() {
        // 雲の画像を呼び込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = SKTextureFilteringMode.nearest
        
        // 必要な枚数を計算
        let needCloudNumber = 2.0 + (frame.size.width / cloudTexture.size().width)
        
        // スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20.0)
        
        // 元の位置に戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0.0)
        
        // 左にスクロール -> 元の位置 -> 左にスクロール と無限に繰り替えるアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud, resetCloud]))
        
        // スプライトを配置する
        stride(from: 0.0, to: needCloudNumber, by: 1.0).forEach {i in
            // テクスチャーを指定してスプライトを作成する
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 // 一番後ろに配置
            
            // スプライトの表示する位置を指定する
            sprite.position = CGPoint(x: i * sprite.size.width, y: size.height - cloudTexture.size().height / 2)
            
            // スプライトにアニメーションを設定
            sprite.run(repeatScrollCloud)
            
            // スプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
    func setupWall() {
        // 壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = SKTextureFilteringMode.linear // 当たり判定を行うので画質優先
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        // 画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4.0)
        
        // 自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall, removeWall])
        
        // 壁を生成するアクションを作成
        let createWallAnimation = SKAction.run ({
            // 壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0.0)
            wall.zPosition = -50.0 // 雲より手前、地面より奥
            
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2

            // 壁のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 4

            // 下の壁のY軸の下限
            let under_wall_lowest_y = UInt32(center_y - wallTexture.size().height / 2 - random_y_range / 2)

            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform(UInt32(random_y_range))

            // Y軸の下限にランダムな値を足して、下の壁のY座標を決定
            let under_wall_y = CGFloat(under_wall_lowest_y + random_y)
            
            // キャラが通り抜ける隙間の長さ
            let slit_length = self.frame.size.height / 4
            
            // 下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0.0, y: under_wall_y)
            wall.addChild(under)
            
            // スプライトに物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            under.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないよう設定
            under.physicsBody?.isDynamic = false
            
            // 上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0.0, y: under_wall_y + wallTexture.size().height + slit_length)
            wall.addChild(upper)
            
            // スプライトに物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            upper.physicsBody?.categoryBitMask = self.wallCategory
            
            // 衝突の時に動かないように設定
            upper.physicsBody?.isDynamic = false
            
            // スプライトにアクションを設定する
            wall.run(wallAnimation)
            
            // スコアに加点するためのノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + self.bird.size.width / 2, y: self.frame.size.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            self.wallNode.addChild(wall)
        })
        
        // 次の壁作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2.0)
        
        // 壁を作成 -> 待ち時間 -> 壁を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation, waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func  setupBird() {
        // 鳥の画像を２種類読み込む
        let birdTextureA = SKTexture(imageNamed: "BalloonCat_a60")
        birdTextureA.filteringMode = SKTextureFilteringMode.linear
        let birdTextureB = SKTexture(imageNamed: "BalloonCat_b60")
        birdTextureB.filteringMode = SKTextureFilteringMode.linear
        
        // ２種類のテクスチャーを交互に変更するアニメーションを作成
        let texturesAnimation = SKAction.animate(with: [birdTextureA, birdTextureB], timePerFrame: 0.6)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        // スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        // 物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        
        // 衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        // 衝突のカテゴリー設定
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        // アニメーションを設定
        bird.run(flap)
        
        // スプライトを追加する
        addChild(bird)
    }
    
    func setupFish() {
        // 秋刀魚の画像を読み込む
        let fishTexture = SKTexture(imageNamed: "Fish")
        fishTexture.filteringMode = SKTextureFilteringMode.linear // 当たり判定を行うので画質優先
        
        // 移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + fishTexture.size().width * 4)
        
        // 画面外まで移動するアクションを作成
        let moveFish = SKAction.moveBy(x: -movingDistance, y: 0, duration: 5.2)
        
        // 自身を取り除くアクションを作成
        let removeFish = SKAction.removeFromParent()
        
        // 2つのアニメーションを順に実行するアクションを作成
        let fishAnimation = SKAction.sequence([moveFish, removeFish])
        
        // 秋刀魚を生成するアクションを作成
        let createFishAnimation = SKAction.run ({
            // 画面のY軸の中央値
            let center_y = self.frame.size.height / 2
            
            // 秋刀魚のY座標を上下ランダムにさせるときの最大値
            let random_y_range = self.frame.size.height / 8
            
            // 秋刀魚のY軸の下限
            let fish_lowest_y = UInt32(center_y - fishTexture.size().height / 2 - random_y_range / 2)
            
            // 1〜random_y_rangeまでのランダムな整数を生成
            let random_y = arc4random_uniform(UInt32(random_y_range))
            
            // Y軸の下限にランダムな値を足して、秋刀魚のY座標を決定
            let fish_y = CGFloat(fish_lowest_y + random_y)
            
            // 秋刀魚のスプライトを作成
            let fish = SKSpriteNode(texture: fishTexture)
            fish.position = CGPoint(x: self.frame.size.width + fishTexture.size().width * 3, y: fish_y)
            fish.zPosition = -20
            
            // スプライトに物理演算を設定
            fish.physicsBody = SKPhysicsBody(rectangleOf: fishTexture.size())
            fish.physicsBody?.categoryBitMask = self.fishCategory
            fish.physicsBody?.contactTestBitMask = self.birdCategory
            
            // 衝突の時に動かないよう設定
            fish.physicsBody?.isDynamic = false
            
            // スプライトにアクションを設定する
            fish.run(fishAnimation)
            
            self.fish.addChild(fish)
        })
        
        // 次の秋刀魚作成までの待ち時間のアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 8.0)
        
        // 秋刀魚を作成 -> 待ち時間 -> 秋刀魚を作成を無限に繰り替えるアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createFishAnimation, waitAnimation]))
        
        // スプライトにアクションを設定する
        fish.run(repeatForeverAnimation)

    }

    
    func setupScoreLabel() {
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 30)
        scoreLabelNode.zPosition = 100 // 一番手前に表示
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        scoreLabelNode.text = "Score:\(score)"
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")
        bestScoreLabelNode.text = "Best Score:\(bestScore)"
        self.addChild(bestScoreLabelNode)

        itemScore = 0
        itemScoreLabelNode = SKLabelNode()
        itemScoreLabelNode.fontColor = UIColor.black
        itemScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        itemScoreLabelNode.zPosition = 100
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        itemScoreLabelNode.text = "Item:\(itemScore)"
        self.addChild(itemScoreLabelNode)
    }
}
