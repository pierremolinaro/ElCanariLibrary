#! /usr/bin/swift

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

import Foundation

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   FOR PRINTING IN COLOR
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

let BLACK   = "\u{001B}[0;30m"
let RED     = "\u{001B}[0;31m"
let GREEN   = "\u{001B}[0;32m"
let YELLOW  = "\u{001B}[0;33m"
let BLUE    = "\u{001B}[0;34m"
let MAGENTA = "\u{001B}[0;35m"
let CYAN    = "\u{001B}[0;36m"
let ENDC    = "\u{001B}[0;0m"
let BOLD    = "\u{001B}[0;1m"
//let UNDERLINE = "\033[4m"
let BOLD_MAGENTA = BOLD + MAGENTA
let BOLD_BLUE = BOLD + BLUE
let BOLD_GREEN = BOLD + GREEN
let BOLD_RED = BOLD + RED

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   runCommand
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

func runCommand (_ command : [String]) {
  let cmd = command [0]
  let args = [String] (command.dropFirst ())
  var str = "+ " + cmd
  for s in args {
    str += " " + s
  }
  print (BOLD_MAGENTA + str + ENDC)
  let task = Process.launchedProcess (launchPath:cmd, arguments:args)
  task.waitUntilExit ()
  let status = task.terminationStatus
  if status != 0 {
    print (BOLD_RED + "Error \(status)" + ENDC)
    exit (status)
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   runCommandAndGetDataOutput
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

func runCommandAndGetDataOutput (_ command : [String]) -> Data {
  let cmd = command [0]
  let args = [String] (command.dropFirst ())
  var str = "+ " + cmd
  for s in args {
    str += " " + s
  }
  print (BOLD_MAGENTA + str + ENDC)
  let task = Process ()
  task.launchPath = cmd
  task.arguments = args
  let pipe = Pipe ()
  task.standardOutput = pipe
  task.standardError = pipe
  let fileHandle = pipe.fileHandleForReading
  task.launch ()
  // print (" launch")
  var data = Data ()
  var hasData = true
  while hasData {
    let newData = fileHandle.availableData
    // print ("  \(newData.count)")
    hasData = newData.count > 0
    data.append (newData)
  }
  task.waitUntilExit ()
  // print (" completed")
  fileHandle.closeFile ()
  let status = task.terminationStatus
  if status != 0 {
    print (BOLD_RED + "Error \(status)" + ENDC)
    exit (status)
  }
  return data
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   runCommandAndGetStringOutput
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

func runCommandAndGetStringOutput (_ command : [String]) -> String {
  let data = runCommandAndGetDataOutput (command)
  return String (data: data, encoding: .utf8)!
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   Data extension for computing SHA1
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

extension Data {
    public func sha1Hash () -> Data {
        let transform = SecDigestTransformCreate (kSecDigestSHA1, 0, nil)
        SecTransformSetAttribute (transform, kSecTransformInputAttributeName, self as CFTypeRef, nil)
        return SecTransformExecute (transform, nil) as! Data
    }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   Computing sha1 of a file
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

func shaOfFile (withBlobSHA inSHA: String) -> String {
  let data = runCommandAndGetDataOutput (["/usr/bin/git", "show", inSHA])
  var s = ""
  for byte in data.sha1Hash () {
    s += "\(String (byte, radix:16, uppercase: false))"
  }
  return s
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   loadJsonFile
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

func loadJsonFile (filePath : String) -> Any {
  do{
    let data = try Data (contentsOf: URL (fileURLWithPath:filePath))
    return try JSONSerialization.jsonObject (with:data)
  }catch let error {
    print (RED + "Error \(error) while processing \(filePath) file" + ENDC)
    exit (1)
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   get fromDictionary
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

func get (_ inObject: Any, _ key : String, _ line : Int) -> Any {
  if let dictionary = inObject as? NSDictionary {
    if let r = dictionary [key] {
      return r
    }else{
      print (RED + "line \(line) : no \(key) key in dictionary" + ENDC)
      exit (1)
    }
  }else{
    print (RED + "line \(line) : object is not a dictionary" + ENDC)
    exit (1)
  }
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
//   getString fromDictionary
//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

func getString (_ inObject: Any, _ key : String, _ line : Int) -> String {
  if let dictionary = inObject as? NSDictionary {
    let r = dictionary [key]
    if r == nil {
      print (RED + "line \(line) : no \(key) key in dictionary" + ENDC)
      exit (1)
    }else if let s = r as? String {
      return s
    }else{
      print (RED + "line \(line) : \(key) key value is not a string" + ENDC)
      exit (1)
    }
  }else{
    print (RED + "line \(line) : object is not a dictionary" + ENDC)
    exit (1)
  }
}


//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————

//-------------------- Get script absolute path
let scriptDir = URL (fileURLWithPath:CommandLine.arguments [0]).deletingLastPathComponent ().path
print ("scriptDir \(scriptDir)")
//-------------------- Set script absolute path as current directory
let fm = FileManager ()
fm.changeCurrentDirectoryPath (scriptDir)
//-------------------- Make temporary directory
let temporaryDir = NSTemporaryDirectory ()
print ("Temporary dir \(temporaryDir)")
//-------------------- Get last commit SHA
let lastCommitJSONFile = temporaryDir + "/lastCommit.json"
runCommand ([
  "/usr/bin/curl",
  "-L", "https://api.github.com/repos/pierremolinaro/ElCanari-Library/branches", "-o", lastCommitJSONFile
])
let array = loadJsonFile (filePath: lastCommitJSONFile) as! [Any]
let dictionary = get (array [0], "commit", #line)
let sha = getString (dictionary, "sha", #line)
print ("Last branch SHA: \(sha)")
//-------------------- Explore files corresponding to this commit
runCommand (["/usr/bin/git", "ls-tree", "-r", sha])
let fileListString = runCommandAndGetStringOutput (["/usr/bin/git", "ls-tree", "-r", sha])
let descriptorArray = fileListString.components (separatedBy:"\n")
var plist = [[String : String]] ()
for descriptor in descriptorArray {
  let t = descriptor.components (separatedBy:"\t")
  if t.count == 2 {
    let filePath = t[1]
    let ext = (filePath as NSString).pathExtension
    if (ext == "ElCanariArtwork") || (ext == "ElCanariFont") {
      let c = t [0].components (separatedBy:" ")
      let blobSHA = c[2]
      let fileSHA = shaOfFile (withBlobSHA: blobSHA)
      print ("BLOB SHA \(blobSHA), file SHA \(fileSHA), file \(filePath)")
      var d = [String : String] ()
      d ["name"] = filePath
      d ["fileSHA"] = fileSHA
      plist.append (d)
    }
  }
}
//--------------- Write plist
let plistFile = scriptDir + "/library.plist"
do{
  let plistData = try PropertyListSerialization.data (fromPropertyList: plist,
    format:PropertyListSerialization.PropertyListFormat.binary,
    options:0
  )
  try plistData.write(to: URL (fileURLWithPath: plistFile), options: .atomic)
}catch let error {
  print (BOLD_RED + "PLIST error \(error) + ENDC")
}

//——————————————————————————————————————————————————————————————————————————————————————————————————————————————————————
