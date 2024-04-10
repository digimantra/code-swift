import UIKit
import BNBSdkApi
import BNBSdkCore
import AVFoundation
import Lottie
//import Zip
enum CameraSide{
    case front
    case back
}

class ARVideoImplementationSample: UIViewController {
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var effectView: EffectPlayerView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var loaderView: UIView!
    @IBOutlet weak var animationContainer: UIView!
    
    
    private var player:Player?
    private let frontCameraDevice = CameraDevice(cameraMode: .FrontCameraSession, captureSessionPreset: .hd1280x720)
    private let backCameraDevice = CameraDevice(cameraMode: .BackCameraSession, captureSessionPreset: .hd1280x720)
    private var videoOutput: Video!
    private var effect:BNBEffect?
    private var fileURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent("video_\(Date()).mp4")
    private var downloadTask:URLSessionDownloadTask?
    private var destination: URL?
    var effectModel:EffectListModel?
    @objc var videoID:String = ""
    @objc var delegate:((URL?) -> ())?
    private var avPlayer:AVPlayer?
    private var currentCamera:CameraSide = .front
    private var animationView: LottieAnimationView?
    private var audioLevel : Float = 0.0
    private var rightBarItemBtn:UIBarButtonItem?
    override func viewDidLoad() {
        super.viewDidLoad()
        rightBarItemBtn = self.navigationItem.rightBarButtonItem
        setProgressView()
        setLoaderView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showLoader()
        addAppStateObserver()
        loadEffect(effectName: "")
        loadPlayerView(cameraDevice: frontCameraDevice)
        listenVolumeButton()
        //        _ = player?.load(effect: "", sync: true)
        //        if let url = URL(string: effectModel?.fileUrl ?? ""){
        //            download(url: url)
        //        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        avPlayer = nil
        player = nil
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @IBAction func tapCameraButton(_ sender: Any) {
        showLoader()
        if currentCamera == .front{
            loadPlayerView(cameraDevice: backCameraDevice)
            cameraButton.image = UIImage(named: "back_camera_icon")
            currentCamera = .back
        }else if currentCamera == .back{
            loadPlayerView(cameraDevice: frontCameraDevice)
            cameraButton.image = UIImage(named: "front_camera_icon")
            currentCamera = .front
        }
        listenVolumeButton()
        self.recordButton.setImage(UIImage(named: "shutter_video"), for: .normal)
        
    }
    @IBAction func closeCamera(_ sender: UIBarButtonItem) {
        stopRecording()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func pushRecordButton(_ sender: UIButton) {
        self.navigationItem.rightBarButtonItem = nil
        loadEffectFromID()
        if videoOutput.state == .stopped {
            videoOutput.record(url: self.fileURL, size: player?.size ?? CGSize()) { [weak self] state in
                guard let self = self else { return }
                
                switch state {
                case .recording, .paused:
                    self.progressBar.progress = 0.0
                    self.progressBar.isHidden = false
                    self.recordButton.setImage(UIImage(named: "stop_video"), for: .normal)
                case .stopped, .processing:
                    self.recordButton.setImage(UIImage(named: "shutter_video"), for: .normal)
                    self.navigationItem.rightBarButtonItem = self.rightBarItemBtn
                @unknown default:
                    break
                }
            } onFinished: {[weak self] success, error in
                guard let weakSelf = self else {return}
                weakSelf.loadEffect(effectName: "")
                weakSelf.progressBar.isHidden = true
                let outputDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let outputFileURL = outputDirectory.appendingPathComponent("MyRecording_\(Date()).mp4")
                print("OutputURl -2-> \(outputFileURL)")
                do {
                    if FileManager.default.fileExists(atPath: outputFileURL.path){
                        try FileManager.default.removeItem(atPath: outputFileURL.path)
                    }
                    try FileManager.default.moveItem(at: weakSelf.fileURL, to: outputFileURL)
                } catch {
                    print("Error moving file: \(error.localizedDescription)")
                }
                
                
                let alert = UIAlertController(title: "Video Recording", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel,handler: { action in
                    weakSelf.delegate?(outputFileURL)
                }))
                if let error = error, !success {
                    // show video recording error
                    alert.message = error.localizedDescription
                } else {
                    // propose to save recorded video
                    alert.message = "Would you like to save recorded video in gallery?"
                    alert.addAction(UIAlertAction(title: "Save", style: .default) {  action in
                        weakSelf.delegate?(outputFileURL)
                        weakSelf.saveVideoToGallery(fileURL: outputFileURL.relativePath)
                    })
                }
                weakSelf.present(alert, animated: true, completion: nil)
            } onProgress: { [weak self] duration in
                let time = round(duration)
                let minutes = Int(time) / 60
                let seconds = Int(time) % 60
                let text = String(format: "%02d : %02d", minutes, seconds)
                print("Video recording in progress: \(text)")
                
                if let time = self?.avPlayer?.currentItem?.currentTime(), let duration = self?.avPlayer?.currentItem?.duration{
                    if duration.seconds.isFinite && time.seconds.isFinite{
                        let currentTime =  Int(CMTimeGetSeconds(time))
                        let duration = Int(CMTimeGetSeconds(duration))
                        print("Video recording in progress: CurrentTime \(currentTime)")
                        print("Video recording in progress: Duration \(duration)")
                        print("Video recording in progress: Division \(Float(currentTime) / Float(duration))")
                        self?.progressBar.progress = Float(currentTime) / Float(duration)
                        if currentTime == duration{
                            self?.videoOutput.stop()
                        }
                    }
                    
                }
                
            }
        } else {
            stopRecording()
        }
    }
    private func addAppStateObserver(){
        NotificationCenter.default.addObserver(self, selector: #selector(stopRecording), name: UIApplication.willResignActiveNotification, object: nil)
    }
    @objc private func stopRecording(){
        showLoader()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){ [weak self] in
            self?.hideLoader()
            self?.videoOutput.stop()
        }
    }
    private func listenVolumeButton(){
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(
                .playback, mode: .default, options: .mixWithOthers)
        } catch {
            print("Error")
        }
    }
    
    private func setProgressView(){
        progressBar.progress = 0
        progressBar.transform = progressBar.transform.scaledBy(x: 1, y: 1.5)
        progressBar.layer.cornerRadius = 2
        progressBar.clipsToBounds = true
        progressBar.layer.sublayers![1].cornerRadius = 2
        progressBar.subviews[1].clipsToBounds = true
        progressBar.progressTintColor = UIColor(red: 0.91, green: 0.26, blue: 0.35, alpha: 1.00)
        progressBar.isHidden = true
    }

    
    private func loadPlayerView(cameraDevice:CameraDevice){
        videoOutput = nil
        player = nil
        videoOutput = Video(cameraDevice: cameraDevice)
        cameraDevice.start()
        effectView.layoutIfNeeded()
        player = Player()
        player?.use(input: Camera(cameraDevice: cameraDevice), outputs: [effectView, videoOutput])
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.hideLoader()
        }
        
    }
    //MARK: -- AV PLayer setup
    private func setupAVPlayer(directory:String){
        
        if let directoryURL = Bundle.main.url(forResource: "effects", withExtension: nil) {
            let subdirectoryURL = directoryURL.appendingPathComponent(directory)
            let videoUrl = subdirectoryURL.appendingPathComponent("videos")
            do {
                let contents = try FileManager.default.contentsOfDirectory(at: videoUrl, includingPropertiesForKeys: nil, options: [])
                if contents.count > 0{
                    let videoURL = contents[0]
                    avPlayer = AVPlayer(playerItem: AVPlayerItem(url:videoURL))
                    avPlayer?.volume = 0.0
                    avPlayer?.play()
                    
                }
            } catch {
                print("Error accessing subdirectory: \(error)")
            }
        } else {
            print("Directory not found in bundle.")
        }
    }
    private func saveVideoToGallery(fileURL: String) {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(fileURL) {
            UISaveVideoAtPathToSavedPhotosAlbum(fileURL, nil, nil, nil)
        }
    }
    
    private func loadEffectFromID(){
        switch(videoID){
        case "658e564058dec2871e8502c7":
            loadEffect(effectName: "LearnColorsEffect")
            setupAVPlayer(directory: "LearnColorsEffect")
        case "658e560958dec2871e8502c4":
            loadEffect(effectName: "ShapesEffect")
            setupAVPlayer(directory: "ShapesEffect")
        case "658e53e358dec2871e8502a1":
            loadEffect(effectName: "ZooAnimalEffect")
            setupAVPlayer(directory: "ZooAnimalEffect")
        case "658e53ae58dec2871e85029e":
            loadEffect(effectName: "NumberEffect")
            setupAVPlayer(directory: "NumberEffect")
        case "658e518758dec2871e850287":
            loadEffect(effectName: "AbcEffect")
            setupAVPlayer(directory: "AbcEffect")
        default:
            loadEffect(effectName: "LearnColorsEffect")
            setupAVPlayer(directory: "LearnColorsEffect")
        }
    }
    
    private func loadEffect(effectName:String = ""){
        _ = self.player?.load(effect: effectName, sync: true)
        self.player?.volume = 1
    }
    
}

extension ARVideoImplementationSample:URLSessionDownloadDelegate{
    
    
    func download(url:URL) {
        
        do {
            let directory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            destination = directory
                .appendingPathComponent(url.lastPathComponent)
            
            
            if destination != nil{
                if FileManager.default.fileExists(atPath: destination?.path ?? "") {
                    loadEffect()
                    return
                }
            }
            
            let configuration = URLSessionConfiguration.default
            let operationQueue = OperationQueue()
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
            
            downloadTask = session.downloadTask(with: url)
            downloadTask?.resume()
        }catch{
            print("Exception occured whil downloading -> \(error.localizedDescription)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        let percentDownloaded = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        print("DownloadPercent-->\(percentDownloaded)")
        DispatchQueue.main.async {
            
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("DownloadedUrl-->\(location)")
        do{
            if let destination = destination{
                try FileManager.default.moveItem(at: location, to: destination)
                //                let _ = try Zip.quickUnzipFile(destination)
                loadEffect()
            }
        }catch{
            print("DownloadedUrl-exception->\(error.localizedDescription)")
        }
    }
    
}

extension ARVideoImplementationSample{
    private func showLoader(){
        loaderView.isHidden = false
        animationView?.play()
    }
    
    private func hideLoader(){
        loaderView.isHidden = true
        animationView?.stop()
    }
    
    private func setLoaderView(){
        animationView = .init(name: "loading")
        if let animationView = animationView{
            animationView.contentMode = .scaleToFill
            animationView.loopMode = .loop
            animationView.center = CGPoint(x: animationView.frame.midX, y: animationView.frame.midY)
            animationContainer.addSubview(animationView)
        }
    }
}
