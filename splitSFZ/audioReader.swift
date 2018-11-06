//
//  audioReader.swift
//  splitSFZ
//
//  Created by rob luca on 01/11/2018.
//  Copyright © 2018 rob luca. All rights reserved.
//

//
//  readAudio.swift
//  mySynth
//
//  Created by rob luca on 01/11/2018.
//  Copyright © 2018 rob luca. All rights reserved.
//

import Foundation
import AVFoundation
/*
 IT is quite easy actually. Load the whole file into memory. Each .wav file is a riff file. The riff files are the windows "multimedia" files and they consist of several chunks.
 The header is as follows:
 offset(hex) value
 0000 'R','I','F','F'
 0004 size of the next chunk (int)
 0008 'W','A','V','E','f','m','t',' ' (don't forget the space!)
 0010 size of the WAVEFORMATEX structure
 0014 the WAVEFORMATEX structure (at the moment it is 18 bytes)
 0026 'd','a','t','a',' ',';' (again, don't forget the space char!)
 002c the raw data.
 The WAVEFORMATEX structure is self-explanatory and it is described in the MSDN library.
 You can copy the header and only change the chunk sizes for the different files you will be creating and then copy the appropriate ammount of raw data into the file. Simple!
 Tom
 */
func loadWave(){
    let bundle = Bundle.main
    let path = bundle.path(forResource: "Sounds/samples/tenor/tenor_smpl", ofType: ".wav")
    var json:AnyObject
    //var error:NSError?
    do {
        let data:NSData = try NSData(contentsOfFile: path!)
        json = try JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.allowFragments) as AnyObject
    } catch {
        print("problem opening file \(error.localizedDescription)")
        return
    }
    // JSONObjectWithData returns AnyObject so the first thing to do is to downcast this to a known type
    if let nsDictionaryObject = json as? NSDictionary {
        if let swiftDictionary = nsDictionaryObject as Dictionary? {
            print(swiftDictionary)
        }
    }
    else if let nsArrayObject = json as? NSArray {
        if let swiftArray = nsArrayObject as Array? {
            print(swiftArray)
        }
    }
}

func loadWave2(){
    let bundle = Bundle.main
    let path = bundle.path(forResource: "Sounds/samples/tenor/tenor_smpl", ofType: ".wav")
    let file: FileHandle? = FileHandle(forReadingAtPath: path!)
    
    if file != nil {
        // Read all the data
        let data = file?.readDataToEndOfFile()
        
        // Close the file
        file?.closeFile()
        
        // Convert our data to string
        let bytes =  (data?[(data?.startIndex)!..<(data?.index((data?.startIndex)!, offsetBy: 4))!])!
        let str = NSString(data: bytes, encoding: String.Encoding.utf8.rawValue)
        print(str!)
    }
    else {
        print("Ooops! Something went wrong!")
    }
}

func loadWaveFile(Opath: String, fileName: String)->(AVAudioPCMBuffer?,AVAudioFormat?){
    //let bundle = Bundle.main
    //let path = bundle.path(forResource: "Sounds/samples/tenor/tenor_smpl", ofType: ".wav")
    let path = Opath+fileName
    debugPrint("got path: \(path)")
    let url = URL(string: path)
    var file : AVAudioFile!
    do {
        file = try AVAudioFile(forReading: url!) //URL(fileURLWithPath: path, isDirectory: false))
    } catch {
        print("opening file error \(error.localizedDescription)")
        return (nil,nil)
    }
    print("file.type \(file.fileFormat)")
    let format=AVAudioFormat(commonFormat: file.processingFormat.commonFormat, sampleRate: file.processingFormat.sampleRate, channels: file.processingFormat.channelCount, interleaved: file.processingFormat.isInterleaved)
    

    
    let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(file.length))
   
    
    do {
        try file.read(into: buffer!)
    } catch {
        print("error reading buffer \(error.localizedDescription)")
    }
    
    //testfile(path: Opath, fileName: fileName, regionBuffer: buffer, format: format)
    return (buffer,format)
}

func testfile(path: String,fileName: String, regionBuffer: AVAudioPCMBuffer?, format: AVAudioFormat?) {
let settings : [String:Any] =
    [AVFormatIDKey:kAudioFormatLinearPCM,
     AVSampleRateKey:NSNumber(value: Float( (format?.sampleRate)!)),
     AVNumberOfChannelsKey:NSNumber(value: Int( (format?.channelCount)!)),
     AVLinearPCMBitDepthKey:NSNumber(value: 16),
     AVLinearPCMIsBigEndianKey:false,
     AVLinearPCMIsFloatKey:false,
     AVEncoderAudioQualityKey:AVAudioQuality.high]
 let nfilename = fileName+"A"
 let npath=path+nfilename
  
let url = URL(string: npath)
do {
    let file = try AVAudioFile(forWriting: url!, settings: settings, commonFormat: (format?.commonFormat)!, interleaved: (format?.isInterleaved)!)
    try file.write(from: regionBuffer!)
} catch {
    debugPrint("could not write file")
}
}
