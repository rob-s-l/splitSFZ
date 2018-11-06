//
//  readSFZ.swift
//  splitSFZ
//
//  Created by rob luca on 01/11/2018.
//  Copyright © 2018 rob luca. All rights reserved.
//

import Foundation


class regionData {
    var lovel: Int32 = -1 //not set, use group
    var hivel: Int32 = -1
    var lokey: Int32 = -1
    var hikey: Int32 = -1
    var pitch: Int32 = -1
    var tune: Int32 = 0
    var transpose: Int32 = 0
    var loopmode: String = ""
    var loopstart: Float32 = -1
    var loopend: Float32 = -1
    var startPoint: Float32 = 0
    var endPoint: Float32 = 0
    var sample: String = ""
    var label: String = ""
    init(){
    }
    
    func toStringArray()->[String]{
        var strings = [String]()
        strings.append("<region>")
        if label != "" {
            strings.append("region_label="+label)
        }
        if lovel >= 0  && hivel >= 0 {
            strings.append(String(format:"lovel=%i hivel=%i",lovel, hivel))
        }
        if lokey >= 0 && hikey >= 0 {
            strings.append(String(format:"lokey=%i hikey=%i",lokey, hikey)
            )
        }
        if pitch > 0 {
            strings.append(String(format:"pitch_keycenter=%i",pitch))
        }
        if tune != 0 {
            strings.append(String(format: "tune=%i", tune))
        }
        if transpose != 0 {
            strings.append(String(format: "transpose=%i", transpose))
        }
        strings.append(String(format: "offset=%.0f end=%.0f",startPoint,endPoint))
        strings.append(String(format: "loop_start=%.0f loop_end=%.0f", loopstart,loopend))
        if loopmode != "" {
            strings.append("loop_mode="+loopmode)
        }
        strings.append("sample="+sample)
        
        return strings
    }
}
class groupData {
    var lovel: Int32 = -1 //not set use global
    var hivel: Int32 = -1
    var lokey: Int32 = 0
    var hikey: Int32 = 127
    var pitch: Int32 = 60
    var loopmode: String = ""
    var sample: String = ""
    var regions = [regionData?]()
    init(){
    }
    //only save "right" values
    func toStringArray()->[String]{
        var strings = [String]()
        strings.append("<group>")
        if lovel >= 0 {
            strings.append(String(format:"lovel=%i hivel=%i",lovel, hivel))
        }
        if loopmode != "" {
            strings.append("loop_mode="+loopmode)
        }
        //sample is brought to region
        return strings
    }
}

class masterData {
    var lovel: Int32 = -1
    var hivel: Int32 = -1
    var groups = [groupData]()
    init(){
        
    }
    func toStringArray()->[String]{
        var strings = [String]()
        strings.append("<master>")
        if lovel >= 0 {
            strings.append(String(format:"lovel=%i hivel=%i",lovel, hivel))
        }
        return strings
    }
}

// not implemented
enum  ampKeys  : String {
    typealias RawValue = String
    case attack = "ampeg_attack",hold = "ampeg_hold",decay = "ampeg_decay", sustain = "ampeg_sustain",release = "ampeg_release", delay = "ampeg_delay"
}
enum filterKeys : String {
    typealias RawValue = String
    case attack = "attack",hold = "hold",decay = "decay", sustain = "sustain",release = "release", cutoff = "cutoff" , frequency = "frequency", resonance = "resonance"
}

enum filterTypes : String {
    typealias RawValue = String
    case lowpass1 = "lpf_1p", highpass1 = "hpf_1p",lowpass2 = "lpf_2p", highpass2 = "hpf_2p", bandpass2 = "bpf_2",  bandrejection2 = "brf_2p"
}

struct filterData {
    var type = ""
    var data = [String:Float]()
}
typealias filter = filterData
// to here

class globalData {
    var samplePath = ""
    var lovel: Int32 = 0
    var hivel: Int32 = 127
    var sample: String = ""
   // var groups = [groupData]()          //different types have groups or masters with groups
   // var masters = [masterData]()
    //ampdata?
    var ampdata = [String:Float]()
    //filterdata?
    var filters = [filter]()
    init(){
    }
    
    func toStringArray()->[String]{
        var strings = [String]()
        strings.append("<global>")
        
        return strings
    }
}

class controlData {
    var samplePath = ""
    var controls = [UInt8:UInt8]()
    init(){}
    
    func toStringArray()->[String]{
        var strings = [String]()
        strings.append("<control>")
        strings.append("default_path="+samplePath)
        for (key,control) in controls {
            strings.append(String(format: "set_cc%i=%i",key,control))
        }
        
        return strings
    }
}

class SFZ {
    var sfzName = ""
    var baseURL : URL!
    var control = controlData()
    var global = globalData()
    var masters = [masterData?]()
    var groups = [groupData?]()
    var regions = [regionData?]()  // regions can occur on their own, in group or in master ?
    init(){
        //
    }
}

class SFZdata {
    var sfzChuncks = [String:SFZ]()
    
    init(){
        
    }
    
    func getData(folderPath: String, sfzFileName: String)->SFZ?{
        let sfzdata = sfzChuncks[sfzFileName]
        if sfzdata != nil {
            return sfzdata
        }
        
        return parseSFZ(folderPath:folderPath,sfzFileName:sfzFileName)
    }
    
    func parseSFZ(folderPath: String, sfzFileName: String)->SFZ? {
        //let globalName = "<global>"
        let groupName = "<group>"
        let regionName = "<region>"
        var filePosition : String.Index
        var chunck = ""
        var data: String
        let sfz = SFZ()
        
        //stopAllVoices()
        //unloadAllSamples()
        
        let baseURL = URL(fileURLWithPath: folderPath)
        // debugPrint("parse: \(baseURL.absoluteString)")
        let sfzURL = baseURL.appendingPathComponent(sfzFileName)
        do {
            data = try String(contentsOf: sfzURL, encoding: .ascii)
        }catch {
            debugPrint("file not found \(sfzFileName)")
            return nil
        }
        
        sfz.sfzName = sfzFileName
        filePosition = data.startIndex
        while filePosition != data.endIndex {
            chunck = findHeader(data: data,dataPointer: &filePosition)
            
            switch chunck {
            case "<control>":
                //only  read the default_path
                let controldata = readChunck(data: data, dataPointer: &filePosition)
                let trimmed = String(controldata.trimmingCharacters(in: .whitespacesAndNewlines))
                sfz.control = readControl(controlChunck: trimmed)
                break
            case "<global>":
                //get end of gobal and read data
                let globaldata = readChunck(data: data, dataPointer: &filePosition)
                let trimmed = String(globaldata.trimmingCharacters(in: .whitespacesAndNewlines))
                sfz.global = readGlobal(globalChunck: trimmed)!
                break
            case "<master>":
                let masterdata = readChunck(data: data, dataPointer: &filePosition)
                let trimmed = String(masterdata.trimmingCharacters(in: .whitespacesAndNewlines))
                let myMaster = readMaster(masterChunck: trimmed)
                    chunck = findHeader(data: data, dataPointer: &filePosition)
                    while chunck == groupName {
                        //this master has groups
                        let groupdata = readChunck(data: data, dataPointer: &filePosition)
                        let trimmed = String(groupdata.trimmingCharacters(in: .whitespacesAndNewlines))
                        let mygroup = readGroup(groupChunck: trimmed)
                        chunck = findHeader(data: data, dataPointer: &filePosition)
                        while chunck == regionName {
                            //read region and append
                            let regiondata = readChunck(data: data, dataPointer: &filePosition)
                            let trimmed = String(regiondata.trimmingCharacters(in: .whitespacesAndNewlines))
                            let myRegion = readRegion(regionChunck: trimmed)
                            mygroup?.regions.append(myRegion)
                            chunck = findHeader(data: data, dataPointer: &filePosition)
                            }
                        myMaster?.groups.append(mygroup!)
                        }
                        if chunck != groupName && filePosition != data.endIndex {
                        //back to before header if ! endoffile
                            filePosition = data.index(filePosition, offsetBy: -(chunck.count))
                        }
                    sfz.masters.append(myMaster)
            break
            case "<group>":
                //get end of group and read data
                //first read this one the
                
                let groupdata = readChunck(data: data, dataPointer: &filePosition)
                let trimmed = String(groupdata.trimmingCharacters(in: .whitespacesAndNewlines))
                let mygroup = readGroup(groupChunck: trimmed)
                chunck = findHeader(data: data, dataPointer: &filePosition)
                while chunck == regionName {
                    //read region and append
                    let regiondata = readChunck(data: data, dataPointer: &filePosition)
                    let trimmed = String(regiondata.trimmingCharacters(in: .whitespacesAndNewlines))
                    let myRegion = readRegion(regionChunck: trimmed)
                    mygroup?.regions.append(myRegion)
                    chunck = findHeader(data: data, dataPointer: &filePosition)
                }
                if chunck != regionName && filePosition != data.endIndex {
                    //back to before header if ! endoffile
                    filePosition = data.index(filePosition, offsetBy: -(chunck.count))
                }
                sfz.groups.append(mygroup)
                break
            // case region without group ? ignore?
            case "<region":
                let regiondata = readChunck(data: data, dataPointer: &filePosition)
                let trimmed = String(regiondata.trimmingCharacters(in: .whitespacesAndNewlines))
                let myRegion = readRegion(regionChunck: trimmed)
                sfz.regions.append(myRegion)
                break
            default:
                //ignore
                break
            }
        }
        sfz.baseURL = URL(fileURLWithPath: folderPath)
        sfzChuncks.updateValue(sfz, forKey: sfzFileName)
        return sfz
    }
    
    //the read gives a problem if in a commented line is written <anything>
    //maybe change to split on "\n" and skip commented lines etc
    //anyway should be rewritten
    func findHeader(data:String, dataPointer:inout String.Index)->(String) {
        if dataPointer == data.endIndex {
            return ("")
        }
        while  dataPointer != data.endIndex {
            if data[dataPointer] == "<" { break }
            dataPointer = data.index(after: dataPointer)
        }
        if dataPointer == data.endIndex {
            return ("")
        }
        let start = dataPointer
        while dataPointer != data.endIndex {
            if  data[dataPointer] == ">"  { break }
            dataPointer = data.index(after: dataPointer)
        }
        dataPointer = data.index(after: dataPointer)
        if dataPointer == data.endIndex {
            return ("")
        }
        
        return (String(data[start..<dataPointer]))
    }
    
    func readChunck(data:String,dataPointer:inout String.Index)->String{
        var readData = ""
        if dataPointer == data.endIndex { return readData }
        while  dataPointer != data.endIndex {
            if data[dataPointer] == "<" {
                break
            } else {
                readData.append(data[dataPointer])
                dataPointer = data.index(after: dataPointer)
            }
        }
        if dataPointer == data.endIndex {return readData }
        if data[dataPointer] == "<" {
            dataPointer = data.index(before: dataPointer)
        }
        return readData
    }
    
    func readControl(controlChunck: String)->controlData {
        let controldata = controlData()
        
        for part in controlChunck.components(separatedBy: .whitespacesAndNewlines){
            if part.hasPrefix("default_path") {
                controldata.samplePath = part.components(separatedBy: "=")[1]
            } else if part.hasPrefix("set_cc") {
                var s = String(part)
                s = s.replacingOccurrences(of: "set_cc", with: "", options: NSString.CompareOptions.literal, range: nil)
                    let key = s.components(separatedBy: "=")[0]
                    let value = s.components(separatedBy: "=")[1]
                    controldata.controls.updateValue(UInt8(value)!, forKey: UInt8(key)!)
            }
        }
        // for now only read the samplePath and controlcommands
        return controldata
    }
    
    func readGlobal(globalChunck:String)->globalData?{
        let globaldata = globalData()
        var samplestring = ""
        var global = globalChunck
        for part in globalChunck.components(separatedBy: .newlines){
            if part.hasPrefix("sample=") {
                samplestring = part
                break
            }
        }
        if samplestring == "" {
            //check for structure
            if global.contains("sample=") {
                //get it out
                var pointer = global.startIndex
                var offset = global.index(pointer, offsetBy: 6, limitedBy: global.endIndex)
                var s = ""
                while offset != global.endIndex {
                    s = String(global[pointer..<offset!])
                    if s.contains("sample=") {break}
                    pointer = global.index(after: pointer)
                    offset = global.index(pointer, offsetBy: 6, limitedBy: global.endIndex)
                    
                }
                if s.contains("sample=") {
                    //read to end
                    samplestring = String(global[pointer..<global.endIndex])
                }
            }
        }
        if samplestring != "" {
            globaldata.sample = samplestring.components(separatedBy: "sample=")[1].replacingOccurrences(of: "\\", with: "/")
            global = global.replacingOccurrences(of: samplestring, with: "", options: NSString.CompareOptions.literal, range: nil)
        }
        
        for part in global.components(separatedBy: .whitespacesAndNewlines) {
            if part == "" || part.hasPrefix("//") {
                // ignore blank lines and comment lines
                continue
            }
            if part.hasPrefix("lovel") {
                globaldata.lovel = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("hivel") {
                globaldata.hivel = Int32(part.components(separatedBy: "=")[1])!
            }  else if part.hasPrefix("default_path") {
                debugPrint("samplepth \(part)")
                globaldata.samplePath = part.components(separatedBy: "=")[1].replacingOccurrences(of: "\\", with: "/")
            }
        }
        return globaldata
    }
    
    func readMaster(masterChunck:String)->masterData?{
        let masterdata = masterData()
        let master = masterChunck
        for part in master.components(separatedBy: .whitespacesAndNewlines) {
            if part == "" || part.hasPrefix("//") {
                // ignore blank lines and comment lines
                continue
            }
            if part.hasPrefix("lovel") {
                masterdata.lovel = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("hivel") {
                masterdata.hivel = Int32(part.components(separatedBy: "=")[1])!
            }
        
        }
        return masterdata
    }
    
    func readGroup(groupChunck:String)->groupData?{
        let groupdata = groupData()
        var samplestring = ""
        var group = groupChunck
        for part in groupChunck.components(separatedBy: .newlines){
            if part.hasPrefix("sample") {
                samplestring = part
            }
        }
        if samplestring == "" {
            //check for structure
            if group.contains("sample") {
                //get it out
                var pointer = group.startIndex
                var offset = group.index(pointer, offsetBy: 6, limitedBy: group.endIndex)
                var s = ""
                while offset != group.endIndex {
                    s = String(group[pointer..<offset!])
                    if s.contains("sample") {break}
                    pointer = group.index(after: pointer)
                    offset = group.index(pointer, offsetBy: 6, limitedBy: group.endIndex)
                    
                }
                if s.contains("sample") {
                    //read to end
                    samplestring = String(group[pointer..<group.endIndex])
                }
            }
        }
        if samplestring != "" {
            groupdata.sample = samplestring.components(separatedBy: "sample=")[1].replacingOccurrences(of: "\\", with: "/")
            group = group.replacingOccurrences(of: samplestring, with: "", options: NSString.CompareOptions.literal, range: nil)
        }
        
        for part in group.components(separatedBy: .whitespacesAndNewlines) {
            if part == "" || part.hasPrefix("//") {
                // ignore blank lines and comment lines
                continue
            }
            if part.hasPrefix("lovel") {
                groupdata.lovel = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("hivel") {
                groupdata.hivel = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("lokey") {
                groupdata.lokey = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("hikey") {
                groupdata.hikey = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("pitch_keycenter") {
                groupdata.pitch = Int32(part.components(separatedBy: "=")[1])!
            }else if part.hasPrefix("loop_mode") {
                groupdata.loopmode = part.components(separatedBy: "=")[1]
            }
        }
        return groupdata
    }
    
    func readRegion(regionChunck:String)->regionData{
        let regiondata = regionData()
        var samplestring = ""
        var labelstring = ""
        var region = regionChunck
        for part in regionChunck.components(separatedBy: .newlines){
            if part.hasPrefix("sample") {
                samplestring = part
            }
            else if part.contains("region_label") {
                labelstring = part
            }
        }
        // this for formats in wich ther are no newlines between region elements
        if samplestring == "" {
            //check for structure
            if region.contains("sample") {
                //get it out
                var pointer = region.startIndex
                var offset = region.index(pointer, offsetBy: 6, limitedBy: region.endIndex)
                var s = ""
                while offset != region.endIndex {
                    s = String(region[pointer..<offset!])
                    if s.contains("sample") {break}
                    pointer = region.index(after: pointer)
                    offset = region.index(pointer, offsetBy: 6, limitedBy: region.endIndex)
                    
                }
                if s.contains("sample") {
                    //read to end
                    samplestring = String(region[pointer..<region.endIndex])
                }
            }
        }
        if samplestring != "" {
            regiondata.sample = samplestring.components(separatedBy: "sample=")[1].replacingOccurrences(of: "\\", with: "/")
            region = region.replacingOccurrences(of: samplestring, with: "", options: NSString.CompareOptions.literal, range: nil)
        }
        if labelstring != "" {
            regiondata.label = labelstring.components(separatedBy: "=")[1]
        }
        for part in region.components(separatedBy: .whitespacesAndNewlines) {
            if part == "" || part.hasPrefix("//") {
                // ignore blank lines and comment lines
                continue
            }
            if part.hasPrefix("lovel") {
                regiondata.lovel = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("hivel") {
                regiondata.hivel = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("key=") {
                regiondata.pitch = Int32(part.components(separatedBy: "=")[1])!
                regiondata.lokey = regiondata.pitch
                regiondata.hikey = regiondata.pitch
            }else if part.hasPrefix("transpose") {
                regiondata.transpose = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("tune") {
                regiondata.tune = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("lokey") { // sometimes on one line
                regiondata.lokey = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("hikey") {
                regiondata.hikey = Int32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("pitch_keycenter") {
                regiondata.pitch = Int32(part.components(separatedBy: "=")[1])!
            }  else if part.hasPrefix("loop_mode") {
                regiondata.loopmode = part.components(separatedBy: "=")[1]
            } else if part.hasPrefix("loop_start") {
                regiondata.loopstart = Float32(part.components(separatedBy: "=")[1])!
            } else if part.hasPrefix("loop_end") {
                regiondata.loopend = Float32(part.components(separatedBy: "=")[1])!
            }else if part.hasPrefix("offset") {
                regiondata.startPoint = Float32(part.components(separatedBy: "=")[1])!
            }
            else if part.hasPrefix("end") {
                regiondata.endPoint = Float32(part.components(separatedBy: "=")[1])!
            }
        }
        return regiondata
    }
}
