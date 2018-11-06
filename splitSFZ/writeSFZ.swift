//
//  writeSFZ.swift
//  splitSFZ
//
//  Created by rob luca on 03/11/2018.
//  Copyright © 2018 rob luca. All rights reserved.
//

import AVFoundation
import Cocoa

let header = ["// simple sfz Used for adapting sfz files with the .wav data",
              "// in the *global* or group* defenition"]

class SFZWriter {
    var globalPath = ""     //let user give the place
    var dialogResult : [URL]? = nil
    var dirResult : URL? = nil
    
    
    
    init(){
        //get global Path
        
    }
    
    //get the name of the sfz File
    func getFile(){
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a .sfz file";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = true;
        dialog.allowedFileTypes        = ["sfz"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            dialogResult = dialog.urls // Pathname of the file
        } else {
            //cancelled
            return
        }
    }
    
    // get the name of the directory to save the sfzand the samples
    func getDir(){
        let ddialog = NSOpenPanel()
        ddialog.title                   = "Choose a directory";
        ddialog.canChooseFiles          = false
        ddialog.canChooseDirectories    = true;
        ddialog.canCreateDirectories    = true;
        ddialog.allowsMultipleSelection = false;
        ddialog.message = "choose directory"
        ddialog.prompt = "select"
        
        if (ddialog.runModal() == NSApplication.ModalResponse.OK) {
            dirResult = ddialog.url // Pathname of the directory
        } else {
            //cancelled
            return
        }
        
        do {
            globalPath = try String(contentsOf: dirResult!)
        } catch {
            debugPrint("url not correct")
        }
        debugPrint("firstfase got:")
       
        if globalPath == "" {
            globalPath = dirResult!.absoluteString.replacingOccurrences(of: "file:", with: "", options: NSString.CompareOptions.literal, range: nil)
        }
         debugPrint("\( globalPath)")
       // startConversion()
    }
    
    //start the conversion only if there are sfz file(s) and a place to save
    func startConversion(){
        var sfz : SFZ?
        var samplePath = ""
        var sampleName = ""

        if dialogResult == nil || globalPath == ""{
            debugPrint("no items")
            let alert = NSAlert()
            alert.messageText = "Warning!"
            alert.informativeText = "No file(s) or directory for saving selected!"
            alert.alertStyle = NSAlert.Style.warning
            alert.addButton(withTitle: "OK")
            //alert.addButton(withTitle: "Cancel")
            _ = alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
            return
        }
        
        // for every file selected
        for Path in dialogResult! {
                print("file: \(Path.absoluteString)")
                //split up and get the fileName from the path
            var path = Path.absoluteString.replacingOccurrences(of: "file:", with: "", options: NSString.CompareOptions.literal, range: nil)
         /*   do {
                path=try String(contentsOf: Path)
            } catch {
                debugPrint("no path")
                return
            } */
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
                progress(message: "reading "+fileName )
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
            // check filename for occurrence of subdir
            // can happen, if so the subdir must be connected tot the path
            if sampleName.contains("/") {
                let names = sampleName.split(separator: "/")
                samplePath.append(String(names[0])+"/")
                sampleName = String(names[1])
            }
            if sampleName == "" || samplePath == "" {
                // maybe samplename in the group defenition? do not handle now
                break
            }
            
            
            progress(message: "reading sample"+sampleName)
            // oke have a path and filename and sfz data structure
            // get a buffer with audiodata
            let (buffer,_) = loadWaveFile(Opath: samplePath, fileName: sampleName)
            if buffer != nil {
                convertSFZ(sfz: sfz!, buffer: buffer!)
            }
    
        } //for path in result
       //ready
        
    }
    var samplecounter = 0
    func convertSFZ(sfz:SFZ,buffer:AVAudioPCMBuffer){
        
        //create a directory for the samples
        let dir = sfz.sfzName.replacingOccurrences(of: ".sfz", with: "_smpl", options: NSString.CompareOptions.literal, range: nil)
        if !makeDir(dir: dir ) {
            debugPrint("could not make sample directory")
            return
        }
        
        //adapt control:
        // if sample in control remove form there
        sfz.control.samplePath = dir+"/"
        
        //adapt global
        sfz.global.sample = ""
        
        sfz.global.samplePath =  dir+"/" //makesure dir samples is made in globalpath
        //MAKE sure the smple dir is defined here!
        // where are the groups??
        //var groups : [groupData?]
        
        progress(message: "start creating regions")
        // check if there are individual groups **************************************************
        if sfz.groups.count > 0 {
            for  n in 0..<sfz.groups.count {
                for r in 0..<sfz.groups[n]!.regions.count {
                 _=writeRegion(region: &sfz.groups[n]!.regions[r], buffer: buffer, path: sfz.global.samplePath)
                }
            } // end group
        } else
            // if there are master chuncks **************************************************
        if sfz.masters.count > 0 {
            for master in sfz.masters {
                for n in 0..<master!.groups.count {
                    for r in 0..<master!.groups[n].regions.count {
                        _=writeRegion(region: &master!.groups[n].regions[r], buffer: buffer, path: sfz.global.samplePath)
                    }
                }
            }//end master
        } else
        // or just regions **************************************************
        if sfz.regions.count > 0 {
        for n in 0..<sfz.regions.count{
            //the samplename from the pitch
            _=writeRegion(region: &sfz.regions[n],buffer:buffer,path: sfz.global.samplePath)
            } //end region
        }else { debugPrint("error reading data, found no groups master or regions")}
        // now save the .sfz file
        if !saveSFZ(sfz:sfz) {
            debugPrint("could not save file : \(sfz.sfzName)")
        }
        samplecounter = 0 //reset if used
    }
    
    //replace the lines with this

    private func writeRegion(region: inout regionData?,buffer:AVAudioPCMBuffer,path:String)->Bool{
        if createMultipleSamples {
            samplecounter += 1
            region!.sample = String((region?.pitch)!)+String(samplecounter)+".wav"
        } else {
            region!.sample = String((region?.pitch)!)+".wav"
        }
        
        let bufferstart = Int((region?.startPoint)!)
        let bufferend = Int(region!.endPoint)

        // reset loop_points
        if (region?.loopstart)! > -1 { region?.loopstart -= (region?.startPoint)!}
        if (region?.loopend)! > -1 { region?.loopend -= (region?.startPoint)!}
        region?.loopend -= 1 //??? sforzando error
        
        //reset start end endpoints
        region?.endPoint -= (region?.startPoint)!
        region?.startPoint = 0
        
        if fileExists(fileName: path+(region?.sample)!) && !createMultipleSamples {
            return true
        }
        //create the sample
        let regionBuffer=copyBuffer(buffer: buffer, startPoint:bufferstart , endPoint:bufferend )
        //save the audioFile to the sample directory
        return saveBufferToFile(buffer: regionBuffer!, fileName: (region?.sample)!, samplePath: path)
    }
    
    func copyBuffer(buffer: AVAudioPCMBuffer,startPoint: Int,endPoint:Int)->AVAudioPCMBuffer?{
        let bLength = Int(endPoint-startPoint)
        let bufferLength = AVAudioFrameCount(bLength)
        let regionBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity:   bufferLength)
        
        // check kind of data we are dealing with
        let step : Int = buffer.format.isInterleaved ? 2 : 1
        if buffer.int16ChannelData != nil {
            var bufferPointer : UnsafeMutablePointer<Int16> = buffer.int16ChannelData!.pointee
            bufferPointer += startPoint
            var regionBufferPointer : UnsafeMutablePointer<Int16> = regionBuffer!.int16ChannelData!.pointee
            for _ in 0..<bLength/step {
                regionBufferPointer.pointee = bufferPointer.pointee
                regionBufferPointer += step
                bufferPointer += step
            }
        } else if buffer.floatChannelData != nil {
            var bufferPointer : UnsafeMutablePointer<Float> = buffer.floatChannelData!.pointee
            bufferPointer += startPoint
            var regionBufferPointer : UnsafeMutablePointer<Float> = regionBuffer!.floatChannelData!.pointee
            for _ in 0..<bLength/step {
                regionBufferPointer.pointee = bufferPointer.pointee
                regionBufferPointer += step
                bufferPointer += step
            }
        } else if buffer.int32ChannelData != nil {
            var bufferPointer : UnsafeMutablePointer<Int32> = buffer.int32ChannelData!.pointee
            bufferPointer += startPoint
            var regionBufferPointer : UnsafeMutablePointer<Int32> = regionBuffer!.int32ChannelData!.pointee
            for _ in 0..<bLength/step {
                regionBufferPointer.pointee = bufferPointer.pointee
                regionBufferPointer += step
                bufferPointer += step
            }
        }
        regionBuffer?.frameLength = bufferLength
      return regionBuffer
    }
    
   private func saveBufferToFile(buffer: AVAudioPCMBuffer,fileName: String, samplePath:String)->Bool{
        let settings : [String:Any] =
            [AVFormatIDKey:kAudioFormatLinearPCM,
             AVSampleRateKey:NSNumber(value: Float( buffer.format.sampleRate)),
             AVNumberOfChannelsKey:NSNumber(value: Int( buffer.format.channelCount)),
             AVLinearPCMBitDepthKey:NSNumber(value: 16),
             AVLinearPCMIsBigEndianKey:false,
             AVLinearPCMIsFloatKey:false,
             AVEncoderAudioQualityKey:AVAudioQuality.high]
    
        let url = URL(string: globalPath+samplePath+fileName)
        debugPrint("save file : \((url?.absoluteString)!)")
        
        do {
            let file = try AVAudioFile(forWriting: url!, settings: settings, commonFormat: buffer.format.commonFormat, interleaved: buffer.format.isInterleaved)
            try file.write(from: buffer)
        } catch {
            debugPrint("could not write file")
            return false
        }
    debug(message:"saved file : \((url?.absoluteString)!)")
    return true
    }
    
    
   private func saveSFZ(sfz:SFZ)->Bool{
        var content = ""
    
    progress(message: "writing :"+sfz.sfzName)
        for str in header {
            content.append(str+"\n")
        }
        content.append("\n")
        let control = sfz.control.toStringArray()
        let global = sfz.global.toStringArray()
       
        for str in control {
            content.append(str+"\n")
        }
         content.append("\n")
        
        for str in global {
            content.append(str+"\n")
        }
        content.append("\n")
        if sfz.masters.count > 0 { //read this out
            for master in sfz.masters {
                let master_strings = master!.toStringArray()
                for str in master_strings {
                    content.append(str+"\n")
                }
                content.append("\n")
                for group in master!.groups {
                    let gr = group.toStringArray()
                    for str in gr {
                        content.append(str+"\n")
                    }
                     content.append("\n")
                    for region in (group.regions) {
                        let reg = region!.toStringArray()
                        for str in reg {
                            content.append(str+"\n")
                        }
                    }
                }
            }
        } else if sfz.groups.count > 0 {
            for group in sfz.groups {
                let gr = group?.toStringArray()
                for str in gr! {
                    content.append(str+"\n")
                }
                 content.append("\n")
                for region in (group?.regions)! {
                    let reg = region!.toStringArray()
                    for str in reg {
                        content.append(str+"\n")
                    }
                     content.append("\n")
                }
            }
        }
        
       
        
        let file = globalPath+sfz.sfzName
        //open file for writing
        do {
            // Write contents to file
            try content.write(toFile: file, atomically: false, encoding: String.Encoding.ascii)
        }
        catch let error as NSError {
            debugPrint("error saving sfz \(error.localizedDescription)")
            return false
        }
        return true
    }
    
   private func makeDir(dir: String)->Bool{
        //allways in the directory the user pointed to
        let directory = URL(fileURLWithPath: globalPath)
        let nPath = directory.appendingPathComponent(dir)
        let fileManager = FileManager.default
        do {
            try fileManager.createDirectory(at: nPath, withIntermediateDirectories: false, attributes: nil)
        }
        catch {
            debugPrint("no directory")
            return false
        }
        return true
    }
    
   private func fileExists(fileName: String)->Bool{
        //let url = URL(string: globalPath+fileName)
            let fileManager = FileManager.default
            return fileManager.fileExists(atPath: globalPath+fileName)
    }
}


