//
//  ViewController.swift
//  splitSFZ
//
//  Created by rob luca on 01/11/2018.
//  Copyright © 2018 rob luca. All rights reserved.
//

import Cocoa
import AVFoundation

var createMultipleSamples = true
var debugWin : NSScrollView?
var messageLabel : NSTextField?
class ViewController: NSViewController {
    var writer : SFZWriter!
    @IBOutlet weak var debugblock: NSScrollView!
    
    @IBOutlet weak var mess: NSTextField!
    @IBOutlet weak var checksavekind: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        writer = SFZWriter()
        debugblock.documentView!.insertText("select one or more files and a directory for saving \n")
  debugWin = debugblock
        messageLabel = mess
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    var sampleName = ""
    var samplePath = ""
    var sfz : SFZ?
    
    /* ************************** get the sfz structure, from there the sampleName and Path */
    @IBAction func select(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .sfz file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["sfz"];
        
        
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.urls // Pathname of the file
            
            
            if (result.count > 0) {
                for path in result {
                    print("file: \(path.absoluteString)")
                    //split up and get the fileName from the path
                    var path = path.absoluteString
                    var ind = path.index(before: path.endIndex)
                    while path[ind] != "/" {
                        ind = path.index(before: ind)
                        if ind == path.startIndex {
                            debugPrint("fileName  reading error")
                            return
                        }
                    }
                    let fileName = String(path[path.index(after: ind)..<path.endIndex])
                    path = path.replacingOccurrences(of: fileName, with: "", options: NSString.CompareOptions.literal, range: nil)
                    
                    // for now let the defaul sample path be the place where the sfz was found
                    samplePath = path
                    //create a sfzdata structure
                    let sfzData = SFZdata()
                    sfz = sfzData.getData(folderPath: path, sfzFileName: fileName)
                    if sfz == nil {
                        return
                    }
                    debugPrint("found sfzdata")
                    // check where the sample file is
                    // can be in control global or maybe group
                    // go top down not yet
                    
                    if sfz?.control.samplePath != "" {
                        debugPrint("control samplePath in \((sfz?.control.samplePath)!)")
                        if sfz?.control.samplePath == "../" {
                            var ind = path.index(path.endIndex, offsetBy: -2)
                            while path[ind] != "/" {
                                ind = path.index(before: ind)
                                if ind == path.startIndex {
                                    debugPrint("fileName  reading error")
                                    return
                                }
                            }
                            samplePath = String(path[path.startIndex..<path.index(after: ind)])
                            debugPrint("samplePath = \(samplePath)")
                        } else {
                            samplePath = path+(sfz?.control.samplePath)!
                            debugPrint("samplePath = \(samplePath)")
                        }
                    } else
                            if sfz?.global.samplePath != "" {
                                debugPrint("global sample in \((sfz?.global.samplePath)!)")
                                if sfz?.global.samplePath == "../" {
                                    var ind = path.index(path.endIndex, offsetBy: -2)
                                    while path[ind] != "/" {
                                        ind = path.index(before: ind)
                                        if ind == path.startIndex {
                                            debugPrint("fileName  reading error")
                                            return
                                        }
                                    }
                                    samplePath = String(path[path.startIndex..<path.index(after: ind)])
                                    debugPrint("samplePath = \(samplePath)")
                                
                                } else {
                                    samplePath = path+(sfz?.global.samplePath)!
                                    debugPrint("samplePath = \(samplePath)")
                                }
                        
                    }
                    // what if group contains the data? then nothing to do
                    if sfz?.global.sample != "" {
                        debugPrint("global sample in \((sfz?.global.sample)!)")
                        sampleName = (sfz?.global.sample)!
                    }
                } //for path in result
            } //result > 0
        } else {
            // User clicked on "Cancel"
            return
        }
        // check filename for occurrence of subdir
        // can happen, if so the subdir must be connected tot the path
        if sampleName.contains("/") {
            let names = sampleName.split(separator: "/")
            samplePath.append(String(names[0])+"/")
            sampleName = String(names[1])
        }
        debugPrint("sample path \(samplePath) name \(sampleName) ")
    }
    
    @IBAction func load(_ sender: Any) {
        // load the data:
       let (buffer,format) = loadWaveFile(Opath: samplePath, fileName: sampleName)
       // have the sfz
        //for group in (sfz?.group)!{
          //  for region in (group?.regions)! {
        guard let group = sfz?.groups[0] else {
            debugPrint("no group in sfz file")
            return
        }

        // what if data is interleaved : every second Int = channeldata so:
        let step : Int = (buffer?.format.isInterleaved)! ? 2 : 1
        let region = group.regions[0]
                //let bLength = Int(region.endPoint*Float32(step)-region.startPoint*Float32(step))
        let bLength = Int(region!.endPoint-region!.startPoint)
                let bufferLength = AVAudioFrameCount(bLength)
                let regionBuffer = AVAudioPCMBuffer(pcmFormat: (buffer?.format)!, frameCapacity:   bufferLength)

        // check kind of data we are dealing with
        
        if buffer?.int16ChannelData != nil {
            var bufferPointer : UnsafeMutablePointer<Int16> = buffer!.int16ChannelData!.pointee
            var regionBufferPointer : UnsafeMutablePointer<Int16> = regionBuffer!.int16ChannelData!.pointee
            for _ in 0..<bLength/step {
                regionBufferPointer.pointee = bufferPointer.pointee
                regionBufferPointer += step
                bufferPointer += step
            }
        } else if buffer?.floatChannelData != nil {
            var bufferPointer : UnsafeMutablePointer<Float> = buffer!.floatChannelData!.pointee
            var regionBufferPointer : UnsafeMutablePointer<Float> = regionBuffer!.floatChannelData!.pointee
            for _ in 0..<bLength/step {
                regionBufferPointer.pointee = bufferPointer.pointee
                regionBufferPointer += step
                bufferPointer += step
            }
        } else if buffer?.int32ChannelData != nil {
            var bufferPointer : UnsafeMutablePointer<Int32> = buffer!.int32ChannelData!.pointee
            var regionBufferPointer : UnsafeMutablePointer<Int32> = regionBuffer!.int32ChannelData!.pointee
            for _ in 0..<bLength/step {
                regionBufferPointer.pointee = bufferPointer.pointee
                regionBufferPointer += step
                bufferPointer += step
            }
        }
        
        
        let regionName = String(region!.pitch)
        let path = samplePath+regionName+".wav"
        
        let settings : [String:Any] =
        [AVFormatIDKey:kAudioFormatLinearPCM,
         AVSampleRateKey:NSNumber(value: Float( (format?.sampleRate)!)),
         AVNumberOfChannelsKey:NSNumber(value: Int( (format?.channelCount)!)),
         AVLinearPCMBitDepthKey:NSNumber(value: 16),
         AVLinearPCMIsBigEndianKey:false,
         AVLinearPCMIsFloatKey:false,
         AVEncoderAudioQualityKey:AVAudioQuality.high]

         regionBuffer?.frameLength = bufferLength
         debugPrint("got path: \(path)")
         let url = URL(string: path)

         do {
            let file = try AVAudioFile(forWriting: url!, settings: settings, commonFormat: (format?.commonFormat)!, interleaved: (format?.isInterleaved)!)
            try file.write(from: regionBuffer!)
         } catch {
            debugPrint("could not write file")
         }

      debugPrint("file \(path) written")
    }
    
    @IBAction func getFile(_ sender: Any) {
        writer.getFile()
    }
    
    @IBAction func getDir(_ sender: Any) {
        writer.getDir()
    }
    @IBAction func startConversion(_ sender: Any) {
        writer.startConversion()
    }
    
    @IBAction func saveMultiple(_ sender: NSButton) {
        createMultipleSamples = sender.state == .on ? true : false
    }
}


func debug(message:String){
    debugWin?.documentView!.insertNewline(nil)
    debugWin?.documentView!.insertText(message)
    debugWin?.setNeedsDisplay((debugWin?.bounds)!)
}

func progress(message:String){
    messageLabel?.stringValue = message
    messageLabel?.setNeedsDisplay((messageLabel?.bounds)!)
}
