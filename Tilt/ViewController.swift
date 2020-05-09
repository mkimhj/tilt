//
//  ViewController.swift
//  Tilt
//
//  Created by Maruchi Kim on 5/8/20.
//  Copyright © 2020 Maruchi Kim. All rights reserved.
//

import UIKit
import CoreMotion

struct Bias {
    var ax = 0.0
    var ay = 0.0
    var az = 0.0
    var gx = 0.0
    var gy = 0.0
    var gz = 0.0
}

struct Variance {
    var ax = 0.0
    var ay = 0.0
    var az = 0.0
    var gx = 0.0
    var gy = 0.0
    var gz = 0.0
}

class ViewController: UIViewController {

    @IBOutlet weak var accelLabel: UILabel!
    @IBOutlet weak var gyroLabel: UILabel!
    @IBOutlet weak var fusedLabel: UILabel!
    
    let motion = CMMotionManager()
    
    func startAccelAndGyro() {
       // Make sure the accelerometer hardware is available.
        if (self.motion.isAccelerometerAvailable && self.motion.isGyroAvailable) {
            self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
            self.motion.gyroUpdateInterval = 1.0 / 60.0
            
            self.motion.startAccelerometerUpdates()
            self.motion.startGyroUpdates()

            Timer.scheduledTimer(timeInterval: (1.0/60.0),
                               target: self,
                               selector: #selector(ViewController.runLoop),
                               userInfo: nil,
                               repeats: true)
       }
    }
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startAccelAndGyro()
    }
    
    func getBias(ax: Double, ay: Double, az: Double, gx: Double, gy: Double, gz: Double) -> Bias {
        struct bias {
            static var axFirst = 0.0
            static var ayFirst = 0.0
            static var azFirst = 0.0
            static var axTotal = 0.0
            static var ayTotal = 0.0
            static var azTotal = 0.0
            static var gxTotal = 0.0
            static var gyTotal = 0.0
            static var gzTotal = 0.0
            static var totalReadings = 0.0
        }
        
        // capture first reading
        if (bias.totalReadings == 0.0) {
            bias.axFirst = ax
            bias.ayFirst = ay
            bias.azFirst = az
        }
        bias.totalReadings += 1.0
        bias.axTotal += (ax - bias.axFirst)
        bias.ayTotal += (ay - bias.ayFirst)
        bias.azTotal += (az - bias.azFirst)
        bias.gxTotal += gx
        bias.gyTotal += gy
        bias.gzTotal += gz
    
        NSLog("BIAS ax:%f ay:%f az:%f gx:%f gy:%f gz:%f", bias.axTotal / bias.totalReadings, bias.ayTotal / bias.totalReadings, bias.azTotal / bias.totalReadings, bias.gxTotal / bias.totalReadings, bias.gyTotal / bias.totalReadings, bias.gzTotal / bias.totalReadings)

        var returnBias = Bias()
        returnBias.ax = bias.axTotal / bias.totalReadings
        returnBias.ay = bias.ayTotal / bias.totalReadings
        returnBias.az = bias.azTotal / bias.totalReadings
        returnBias.gx = bias.gxTotal / bias.totalReadings
        returnBias.gy = bias.gyTotal / bias.totalReadings
        returnBias.gz = bias.gzTotal / bias.totalReadings
        
        return returnBias
    }
    
    func getVariance(ax: Double, ay: Double, az: Double, gx: Double, gy: Double, gz: Double) -> Variance {
        struct variance {
            static var axM = 0.0
            static var axS = 0.0
            static var ayM = 0.0
            static var ayS = 0.0
            static var azM = 0.0
            static var azS = 0.0
            static var gxM = 0.0
            static var gxS = 0.0
            static var gyM = 0.0
            static var gyS = 0.0
            static var gzM = 0.0
            static var gzS = 0.0
            static var totalReadings = 0.0
        }
        
        variance.totalReadings += 1.0
        
        // VARIANCE
        let tmp_axM = variance.axM
        variance.axM += (ax - tmp_axM) / variance.totalReadings
        variance.axS += (ax - tmp_axM) * (ax - variance.axM)
        
        let tmp_ayM = variance.ayM
        variance.ayM += (ay - tmp_ayM) / variance.totalReadings
        variance.ayS += (ay - tmp_ayM) * (ay - variance.ayM)
        
        let tmp_azM = variance.azM
        variance.azM += (az - tmp_azM) / variance.totalReadings
        variance.azS += (az - tmp_azM) * (az - variance.azM)
        
        let tmp_gxM = variance.gxM
        variance.gxM += (gx - tmp_gxM) / variance.totalReadings
        variance.gxS += (gx - tmp_gxM) * (gx - variance.gxM)
        
        let tmp_gyM = variance.gyM
        variance.gyM += (gy - tmp_gyM) / variance.totalReadings
        variance.gyS += (gy - tmp_gyM) * (gy - variance.gyM)
        
        let tmp_gzM = variance.gzM
        variance.gzM += (gz - tmp_gzM) / variance.totalReadings
        variance.gzS += (gz - tmp_gzM) * (gz - variance.gzM)
        
        NSLog("VARIANCE ax:%f ay:%f az:%f gx:%f gy:%f gz:%f", variance.axS / variance.totalReadings, variance.ayS / variance.totalReadings, variance.azS / variance.totalReadings, variance.gxS / variance.totalReadings, variance.gyS / variance.totalReadings, variance.gzS / variance.totalReadings)
        
        var returnVariance = Variance()
        returnVariance.ax = variance.axS / variance.totalReadings
        returnVariance.ay = variance.ayS / variance.totalReadings
        returnVariance.az = variance.azS / variance.totalReadings
        returnVariance.gx = variance.gxS / variance.totalReadings
        returnVariance.gy = variance.gyS / variance.totalReadings
        returnVariance.gz = variance.gzS / variance.totalReadings
        return returnVariance
    }
    
    @objc func runLoop() {
        struct accelTilt {
            static var x = 0.0
            static var y = 0.0
            static var z = 0.0
        }
        
        struct gyroTilt {
            static var x = 0.0
            static var y = 0.0
            static var z = 0.0
        }
        
        struct fusedTilt {
            static var alpha = 0.02
            static var x = 0.0
            static var y = 0.0
            static var z = 0.0
        }
        
        struct time {
            static var lastTimeMs = 0.0
        }
        
        if let aData = self.motion.accelerometerData {
            if let gData = self.motion.gyroData {
                let ax = aData.acceleration.x
                let ay = aData.acceleration.y
                let az = aData.acceleration.z
                let gx = gData.rotationRate.y // swap these
                let gy = -1*gData.rotationRate.x // swap these
                let gz = gData.rotationRate.z

//                SAMPLE
//                NSLog("ax:%f ay:%f az:%f gx:%f gy:%f gz:%f", ax, ay, az, gx, gy, gz)
                
//                var bias = getBias(ax: ax, ay: ay, az: az, gx: gx, gy: gy, gz: gz)
//                var variance = getVariance(ax: ax, ay: ay, az: az, gx: gx, gy: gy, gz: gz)

                accelTilt.x = atan(ax / sqrt(pow(ay,2) + pow(az,2))) * 180 / Double.pi
                accelTilt.y = atan(ay / sqrt(pow(ax,2) + pow(az,2))) * 180 / Double.pi
                accelTilt.z = atan(sqrt(pow(ax,2) + pow(ay,2)) / az) * 180 / Double.pi
                
                gyroTilt.x += gx
                gyroTilt.y += gy
                gyroTilt.z += gz
                
                fusedTilt.x = (1 - fusedTilt.alpha) * (fusedTilt.x + gx) + (fusedTilt.alpha) * (accelTilt.x)
                fusedTilt.y = (1 - fusedTilt.alpha) * (fusedTilt.y + gy) + (fusedTilt.alpha) * (accelTilt.y)
                
                let aTilt = sqrt(pow(accelTilt.x, 2) + pow(accelTilt.y, 2))
                let gTilt = sqrt(pow(gyroTilt.x, 2) + pow(gyroTilt.y, 2))
                let fTilt = sqrt(pow(fusedTilt.x, 2) + pow(fusedTilt.y, 2))
                
                if ((CACurrentMediaTime() - time.lastTimeMs) > 0.25) {
                    NSLog("%2.3f | %2.3f | %2.3f", aTilt, gTilt, fTilt)
                    time.lastTimeMs = CACurrentMediaTime()
                }
                            
                accelLabel.text  = String(format:"%.2f", aTilt)
                gyroLabel.text  = String(format:"%.2f", gTilt)
                fusedLabel.text  = String(format:"%.2f", fTilt)
            }
        }
    }
}

