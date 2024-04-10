//
//  SwiftSample.swift
//

import UIKit
import Nuke

class SwiftSample: UIViewController {

    //MARK: Outlets
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var crossButton: UIButton!
    @IBOutlet weak var playGameBtn: UIButton!
    @IBOutlet weak var challengeNameBtn: UIButton!
    @IBOutlet weak var challengeDatesBtn: UIButton!
    @IBOutlet weak var challengeCollection: UICollectionView!
    @IBOutlet weak var challengeDetailView: UIView!
    @IBOutlet weak var challengeDetailTableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var dropDownButton: UIButton!
    @IBOutlet weak var scrollBarBgView: UIView!
    @IBOutlet weak var mainScrollView: UIScrollView!
    @IBOutlet weak var claimRewardBtn: UIButton!
    @IBOutlet weak var challengeView: UIView!
    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var activeDayDescLabel: UILabel!
    @IBOutlet weak var totalPlayedLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var claimedBonusView: UIView!
    @IBOutlet weak var unClaimedBonusView: UIView!
    @IBOutlet weak var bonusStackViewHeight: NSLayoutConstraint!
    @IBOutlet weak var claimedRewardVal: UILabel!
    @IBOutlet weak var unclaimedRewardVal: UILabel!
    @IBOutlet weak var claimRewardBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var claimRewardBtnTopHeight: NSLayoutConstraint!
    @IBOutlet weak var challengeImage: UIImageView!
    @IBOutlet weak var aggregateDescriptionLabel: UILabel!
    @IBOutlet weak var challengeDateBtnBg: UIView!
    @IBOutlet weak var challengeActivateBtn: UIButton!
    @IBOutlet weak var dayWiseProgressView: UIProgressView!
    @IBOutlet weak var dayWiseProgressContainer: UIView!
    @IBOutlet weak var dayWiseProgressLabel: UILabel!
    @IBOutlet weak var snackBarBgView: UIView!
    @IBOutlet weak var snackDescritption: UILabel!
    @IBOutlet weak var tooltipMainView: UIView!
    @IBOutlet weak var tooltipBgView: UIView!
    @IBOutlet weak var tooltipLabel: UILabel!
    @IBOutlet weak var infoBtn: UIButton!
    @IBOutlet weak var failedView: UIView!
    @IBOutlet weak var loaderBgView: UIView!
    @IBOutlet weak var collectionTopConstraint: NSLayoutConstraint!
    
    //MARK: Variables
    var customScrollBar:SwiftyVerticalScrollBar?
    var challengeDetail:[String:Any]?
    var activeDay:Int = 0
    var dayInfo:[[String:Any]] = [[:]]
    var claimedBonus:Int = 0
    var unClaimedBonus:Int = 0
    var campaignId:Int = 0
    var challengeStatus:String = ""
    var challengeType:String = ""
    var aggregateDesc:String = ""
    var activeDayAction:String = ""
    var chunkType:String = ""
    var unClaimData:(count:Int,day:Int) = (0,-1)
    var isOpted:Bool = false
    var firstWord:String = ""
    var hoursDiff:Int = 0
    var activeDayStatus:String = ""
    var activeDayReward:String = ""
    var pointVal:Int = 0
    var activatedCampaignId:Int = 0
    //MARK: Presenters
    let challengePresenter = ChallengePresenter(challengesService: ChallengesService())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        setDelegates()
        loaderBgView.isHidden = false
        getChallenges()
        
//        if Device.isDebug(){
//            self.getMockData()
//        }
    }
    override func viewDidLayoutSubviews() {
        customScrollBar?.frame = CGRect(x: 0, y: 0, width: self.scrollBarBgView.frame.width , height: self.scrollBarBgView.bounds.size.height)
    }
    //MARK: Actions
    @IBAction func tapCrossBtn(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapChallengeDetail(_ sender: Any) {
        if challengeDetailTableView.isHidden{
            
            sendChallengeDetailDetailEvent()
            
            dropDownButton.imageView?.transform = CGAffineTransformMakeRotation(.pi)
            challengeDetailTableView.isHidden = false
            if challengeType == "aggregate"{
                aggregateDescriptionLabel.text = aggregateDesc
                tableViewHeight.constant = 20
                challengeDetailTableView.reloadData()
            }else{
                setTableViewHeight(tableView: challengeDetailTableView, tableHeightConstraint: tableViewHeight)
            }
        }else{
            aggregateDescriptionLabel.text = ""
            challengeDetailTableView.isHidden = true
            tableViewHeight.constant = 0
            challengeDetailTableView.reloadData()
            dropDownButton.imageView?.transform = .identity
        }
    }
    @IBAction func tapPlayGameBtn(_ sender: UIButton) {
        if let title = sender.titleLabel?.text{
            if title == "CLAIM REWARDS"{
                if challengeType == "staged"{
                    callClaimDayBonusAPI(day: unClaimData.day, campaignId: campaignId)
                }else{
                    callClaimDayBonusAPI(campaignId: campaignId)
                }
            }else {
                performAfterDelay(delay: 0.1) {
                    NotificationCenter.default.post(name: NSNotification.Name(Constants.NavigateChallengeCTA), object: nil, userInfo: ["cta":sender.titleLabel?.text ?? ""])
                    
                }
                
                self.navigationController?.popViewController(animated: true)
            }
        }
        sendChallengeDetailCTAEvent(cta:sender.titleLabel?.text ?? "")
    }
    @IBAction func tapChallengeAcitvateBtn(_ sender: Any) {
        if let challengeDetail = challengeDetail{
            let campaignId = challengeDetail["campaign_id"] as? Int ?? 0
            SKActivityIndicator.show()
            ChallengeDataModel.sharedInstance.postData.removeAll()
            var postData:[String:Any] = [:]
            postData["campaign_id"] = campaignId
            postData["player_segment"] = "default"
            postData["event"] = "opt-in"
            postData["user_id"] = GameData.sharedInstance.game_LoginUserAccountId
            ChallengeDataModel.sharedInstance.postData = postData
            challengePresenter.activateChallenge()
        }
    }
    @IBAction func tapInfoBtn(_ sender: Any) {
        if tooltipMainView.isHidden{
            tooltipMainView.isHidden = false
            performAfterDelay(delay: 5) { [weak self] in
                self?.tooltipMainView.isHidden = true
            }
        }
    }
    
    //MARK: User defined functions
    func setUI(){
        challengeDetailTableView.isHidden = true
        challengeActivateBtn.isHidden = true
        tableViewHeight.constant = 0
        aggregateDescriptionLabel.text =  ""
        snackBarBgView.alpha = 0
        tooltipMainView.isHidden = true
        infoBtn.isHidden = true
        failedView.isHidden = true
        customScrollBar = SwiftyVerticalScrollBar(frame: CGRect.zero, targetScrollView: mainScrollView)
        if let customScrollBar = customScrollBar{
            self.scrollBarBgView.addSubview(customScrollBar)
        }
        
        performAfterDelay(delay: 0.1) {
            SwiftSampleUIControls.setUIViewBg(view: self.headerView,
                                              isGradient: true,gradientColors: [UIColor(hexFromString: "#2E2E2E"),
                                                                                UIColor(hexFromString: "#1B1B1B")])
            SwiftSampleUIControls.setUIButtonBg(view: self.challengeActivateBtn,
                                                imageName: "chevron_right",
                                                title: "ACTIVATE CHALLENGE",
                                                font: UIFont(name: "Roboto", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .regular),
                                                tintColor: UIColor.white,
                                                cornerRadius: 12,
                                                backgroundColor: UIColor(hexFromString: "#4AAC1B"),
                                                isGradientBorder: true,
                                                borderColors: [UIColor(hexFromString: "#4ECC11"),UIColor(hexFromString: "#355F22")],
                                                borderWidth: 2,
                                                borderGradientStartPoint: CGPoint(x: 0, y: 0.5),
                                                borderGradientEndPoint: CGPoint(x: 0, y: 1))
        }
        SwiftSampleUIControls.setUIButtonBg(view: crossButton,
                                            imageName: "closeWhiteIcon",
                                            cornerRadius: 16,
                                            backgroundColor: UIColor(hexFromString: "#292929"))
        
        
        SwiftSampleUIControls.setUIButtonBg(view: challengeNameBtn,
                                            title: "7 DAY CHALLENGE",
                                            font: UIFont(name: "Montserrat-Bold", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .bold),
                                            tintColor: UIColor.black,
                                            cornerRadius: 4,
                                            backgroundColor: UIColor(hexFromString: "#FFD232"))
        SwiftSampleUIControls.setUIViewBg(view: challengeDateBtnBg,
                                          cornerRadius: 4,
                                          backgroundColor: UIColor(hexFromString: "#2E2E2E"))
        SwiftSampleUIControls.setUIViewBg(view: failedView,
                                          cornerRadius: 4,
                                          backgroundColor: UIColor.red)
        SwiftSampleUIControls.setUIButtonBg(view: challengeDatesBtn,
                                            title: "21st–27th June 2023",
                                            font: UIFont(name: "Roboto-Medium", size: 10) ?? UIFont.systemFont(ofSize: 10, weight: .semibold),
                                            tintColor: UIColor.white,
                                            backgroundColor: .clear)
        
        SwiftSampleUIControls.setUIViewBg(view: challengeDetailView,
                                          cornerRadius: 4,
                                          backgroundColor: UIColor(hexFromString: "#111111"))
        SwiftSampleUIControls.setUIViewBg(view: scrollBarBgView,
                                          cornerRadius:4,
                                          backgroundColor: UIColor(hexFromString: "#252525"))
        SwiftSampleUIControls.setUIViewBg(view: snackBarBgView,
                                          cornerRadius: 8,
                                          backgroundColor: UIColor(hexFromString: "#4AAC1B"))
        SwiftSampleUIControls.setUIViewBg(view: tooltipBgView,
                                          cornerRadius: 8,
                                          backgroundColor: UIColor(hexFromString: "#292929"),
                                          borderColors: [UIColor(hexFromString: "#2E2E2E")],
                                          borderWidth: 2)
        
    }
    @objc func tapToolTipBg(_ sender: UITapGestureRecognizer){
        tooltipMainView.isHidden = true
    }
    func setPlayGameBtn(title:String){
        playGameBtn.isHidden = false
        playGameBtn.removeSubLayers(removeBorderOnly: true)
        SwiftSampleUIControls.setUIButtonBg(view: playGameBtn,
                                            imageName: "arrow_forward_white",
                                            title: title,
                                            font: UIFont(name: "Montserrat-Bold", size: 14) ?? UIFont.systemFont(ofSize: 14, weight: .bold),
                                            tintColor: UIColor.white,
                                            cornerRadius: 22,
                                            backgroundColor: UIColor(hexFromString: "#4AAC1B"),
                                            isGradientBorder: true,
                                            borderColors: [UIColor(hexFromString: "#4ECC11"),UIColor(hexFromString: "#355F22")],
                                            borderWidth: 2,
                                            borderGradientStartPoint: CGPoint(x: 0, y: 0.5),
                                            borderGradientEndPoint: CGPoint(x: 0, y: 1))
    }
    func updatePlayGameBtn(){
        switch activeDayAction{
        case "win","wager","play","net_win":
            setPlayGameBtn(title: "PLAY GAME")
        case "deposit":
            setPlayGameBtn(title: "ADD CASH")
        default:
            setPlayGameBtn(title: "PLAY GAME")
        }
    }
    func setDelegates(){
        
        challengePresenter.attachView(view: self)
        
        challengeCollection.delegate = self
        challengeCollection.dataSource = self
        
        challengeDetailTableView.delegate = self
        challengeDetailTableView.dataSource = self
        
        challengeDetailTableView.reloadData()
        
        
    }
    func getChallenges(){
        SKActivityIndicator.show()
        challengePresenter.getChallengeList()
    }
    
    func setDetails(){
        if let challengeDetail = challengeDetail{
            dayInfo.removeAll()
            if let image = challengeDetail["detail_page_image"] as? String,let url = URL(string: image){
                Nuke.loadImage(with: url, into: challengeImage)
            }
            
            
            // Setting Title
            let title = challengeDetail["title"] as? String ?? ""
            pointVal = Int(challengeDetail["point"] as? Double ?? 0)
            tooltipLabel.text = "1 point = ₹\(pointVal)"
            if pointVal > 1{
                infoBtn.isHidden = false
            }else{
                infoBtn.isHidden = true
            }
            challengeNameBtn.setTitle(title.uppercased(), for: .normal)
            
            //Handling Start Date
            let startDateStr = challengeDetail["challenge_starttime"] as? String ?? ""
            let startDate = Constants.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss", date: startDateStr) ?? Date()
            
            let startTime = Constants.getFormattedDateString(format: "hh:mm a", date: startDate)
            let startDay = Constants.getFormattedDateString(format: "dd", date: startDate)
            let startMonth = Constants.getFormattedDateString(format: "MMM", date: startDate)
            let startYear = Constants.getFormattedDateString(format: "yyyy", date: startDate)
            

            //Handling End Date
            let endDateStr = challengeDetail["challenge_endtime"] as? String ?? ""
            let endDate = Constants.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss", date: endDateStr) ?? Date()
            
            let endTime = Constants.getFormattedDateString(format: "hh:mm a", date: endDate)
            let endDay = Constants.getFormattedDateString(format: "dd", date: endDate)
            let endMonth = Constants.getFormattedDateString(format: "MMM", date: endDate)
            let endYear = Constants.getFormattedDateString(format: "yyyy", date: endDate)
            

            
            
            guard let type = challengeDetail["type"] as? String else {
                return
            }
            self.challengeType = type
            let reward = challengeDetail["reward"] as? String ?? ""
           
            challengeStatus = challengeDetail["status"] as? String ?? ""
            isOpted = challengeDetail["is_opted"] as? Bool ?? false
            
            claimRewardBtn.isHidden = true
            claimRewardBtnHeight.constant = 0
            claimRewardBtnTopHeight.constant = 0
            
            if type == "staged"{
                challengeView.isHidden = false
                progressContainerView.isHidden = true
                if let dayInfo = challengeDetail["days_info"] as? [[String:Any]]{
                    calculateRewardAmount(dayInfo:dayInfo)
                    self.dayInfo = dayInfo
                    if dayInfo.count > 0,let chunkType = dayInfo[0]["chunk_type"] as? String{
                        self.chunkType = chunkType
                    }
                }
                setActiveDayDescription()
                unClaimData = getUnClaimedRewardCount(challenge: challengeDetail)

                if unClaimData.count > 0 && unClaimData.day == activeDay{
                    playGameBtn.isHidden = true
                }else if challengeStatus != "completed"{
                    updatePlayGameBtn()
                }else{
                    playGameBtn.isHidden = true
                }
                challengeCollection.reloadData()
                challengeDetailTableView.reloadData()
            }else if type == "aggregate"{
                activeDayDescLabel.text = challengeDetail["description"] as? String ?? ""
                aggregateDesc = challengeDetail["description"] as? String ?? ""
                challengeView.isHidden = true
                progressContainerView.isHidden = false
                calculateAggregateRewardAmount(challengeDetail:challengeDetail)
                let totalGames = challengeDetail["max_action_value"] as? Double ?? 0.0
                let completedGames = challengeDetail["completed_action_value"] as? Double ?? 0.0
                activeDayAction = challengeDetail["challenge_action"] as? String ?? ""
                let activeDayActionText = challengeDetail["challenge_action_text"] as? String ?? ""
                
                let _ = challengeDetail["title"] as? String ?? ""
                
                totalPlayedLabel.text = getProgressDesc(action: activeDayAction,actionText:activeDayActionText,maxVal:Int(totalGames),completedVal:Int(ceil(completedGames)))
                let progress:Double = completedGames / totalGames
                progressView.progress = Float(progress)
                dayWiseProgressContainer.isHidden = true
                
                if progressView.progress >= 1.0 && reward != "claimed" {
                    setPlayGameBtn(title: "CLAIM REWARDS")
                }else if reward != "claimed"{
                    updatePlayGameBtn()
                }else if reward == "claimed"{
                    playGameBtn.isHidden = true
                }
            }
            let challengeDateTitle:String = "\(startDay) \(startMonth) \(startYear) \(startTime) - \(endDay) \(endMonth) \(endYear) \(endTime)"
            
            challengeDatesBtn.setTitle(challengeDateTitle, for: .normal)
            claimedBonusView.isHidden = false
            unClaimedBonusView.isHidden = false
            if isOpted{
                challengeActivateBtn.isHidden = true
                challengeDateBtnBg.isHidden = false
                if claimedBonus == 0 && unClaimedBonus == 0{
                    bonusStackViewHeight.constant = 0
                    collectionTopConstraint.constant = 12
                }else{
                    collectionTopConstraint.constant = 24
                    bonusStackViewHeight.constant = 40
                }
                if claimedBonus == 0{
                    claimedBonusView.isHidden = true
                }
                if unClaimedBonus == 0{
                    unClaimedBonusView.isHidden = true
                }
                if type == "aggregate" && progressView.progress < 1.0{
                    bonusStackViewHeight.constant = 0
                    collectionTopConstraint.constant = 12
                    claimedBonusView.isHidden = true
                    unClaimedBonusView.isHidden = true
                }else{
                    collectionTopConstraint.constant = 24
                }
            }else{
                challengeActivateBtn.isHidden = false
                challengeDateBtnBg.isHidden = true
                claimedBonusView.isHidden = true
                bonusStackViewHeight.constant = 0
                claimedBonusView.isHidden = true
                unClaimedBonusView.isHidden = true
                dayWiseProgressContainer.isHidden = true
                playGameBtn.isHidden = true
            }
            
            if challengeStatus == "completed"{
                challengeDateBtnBg.isHidden = false
                failedView.isHidden = true
                if ((type == "staged" && unClaimData.count > 0) || (type == "aggregate" && reward != "claimed")){
                    activeDayDescLabel.text = "\(title) successfully completed. Claim rewards"
                }else{
                    activeDayDescLabel.text = "\(title) successfully completed."
                }
                challengeDatesBtn.setTitle("Completed", for: .normal)
            }else if challengeStatus == "failed"{
                challengeDateBtnBg.isHidden = true
                failedView.isHidden = false
                playGameBtn.isHidden = true
            }else if (challengeStatus == "active" || (challengeStatus == "pending" && isOpted)) && activeDayStatus == "completed" && activeDayReward == "claimed"{
                playGameBtn.isHidden = true
            }
        }
        loaderBgView.isHidden = true
    }
    func setActiveDayDescription(){
        activeDayDescLabel.text = ""
        dayWiseProgressContainer.isHidden = true
        for day in dayInfo{
            if let dayNo = day["day"] as? Int{
                let chunkStartTimeStr = day["challenge_starttime"] as? String ?? ""
                let chunkStartTime = Constants.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss", date: chunkStartTimeStr) ?? Date()
                
                let chunkEndTimeStr = day["challenge_endtime"] as? String ?? ""
                let chunkEndTime = Constants.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss", date: chunkEndTimeStr) ?? Date()
                let currentDate:Date = Date().toLocalTime()
                Constants.printToConsole("StartTime -> \(chunkStartTime)")
                Constants.printToConsole("EndTime -> \(chunkStartTime)")
                Constants.printToConsole("CurrentTime -> \(currentDate)")
                if chunkStartTime <= currentDate && chunkEndTime > currentDate {  activeDay = dayNo }
                if chunkType == "day"{
                    firstWord = "Day"
                }else if chunkType == "hour"{
                    hoursDiff = (Calendar.current.dateComponents([.hour], from: chunkStartTime, to: chunkEndTime).hour ?? 0)
                    if hoursDiff > 1{
                        firstWord = "Step"
                    }else{
                        firstWord = "Hour"
                    }
                    
                }
                challengeDetailTableView.reloadData()
                if activeDay == dayNo {
                    activeDayStatus = day["status"] as? String ?? ""
                    activeDayReward = day["reward"] as? String ?? ""
                    if let desc = day["description"] as? String{
                        if  activeDayStatus == "pending"{
                            activeDayDescLabel.text = "\(firstWord) \(dayNo) - \(desc)"
                        }else{
                            activeDayDescLabel.text = "\(firstWord) \(dayNo) - Milestone reached."
                        }
                    }
                    if let maxActionValue = day["max_action_value"] as? Double,
                       let completedActionValue = day["completed_action_value"] as? Double{
                        dayWiseProgressView.isHidden = false
                        let progress:Double = completedActionValue / maxActionValue
                        dayWiseProgressView.progress = Float(progress)
                        
                        if let action = day["challenge_action"] as? String,let actionText = day["challenge_action_text"] as? String {
                            activeDayAction = action
                            dayWiseProgressLabel.text = getProgressDesc(action: action,actionText: actionText,maxVal:Int(maxActionValue),completedVal:Int(ceil(completedActionValue)))
                        }
                        
                        if completedActionValue > 0 && activeDayReward != "claimed" {
                            dayWiseProgressContainer.isHidden = false
                        }else{
                            dayWiseProgressContainer.isHidden = true
                        }
                        
                    }else{
                        dayWiseProgressContainer.isHidden = true
                    }
                }else if !isOpted && dayNo == 1{
                    let desc = day["description"] as? String ?? ""
                    activeDayDescLabel.text = "\(firstWord) \(dayNo) - \(desc)"
                }
            }
        }
    }
    func getProgressDesc(action:String,actionText:String,maxVal:Int,completedVal:Int) -> String{
        
        switch action{
        case "play":
            if pointVal > 1{
                return "\(completedVal) of \(maxVal) points achieved"
            }else{
                return "\(completedVal) of \(maxVal) games completed"
            }
        case "win":
            if pointVal > 1{
                return "\(completedVal) of \(maxVal) points achieved"
            }else{
                return "\(completedVal) of \(maxVal) games won"
            }
        case "net_win":
            if pointVal > 1{
                return "\(completedVal) of \(maxVal) points achieved"
            }else{
                return "₹\(completedVal) of ₹\(maxVal) won"
            }
        case "wager":
            if pointVal > 1{
                return "\(completedVal) of \(maxVal) points achieved"
            }else{
                return "₹\(completedVal) of ₹\(maxVal) wagered"
            }
        case "deposit":
            if actionText == "cash"{
                return "₹\(completedVal) of ₹\(maxVal) deposited"
            }else{
                return "\(completedVal) of \(maxVal) times deposited"
            }
        default:
            return "\(completedVal) of \(maxVal) games completed"
        }
    }
    func calculateRewardAmount(dayInfo:[[String:Any]]){
        claimedBonus = 0
        unClaimedBonus = 0
        
        for day in dayInfo{
            if let status = day["status"] as? String,status == "completed"{
                if let rewardAmnt = day["reward_amount"] as? [[String:Any]]{
                    for rewardObj in rewardAmnt{
                        let reward = day["reward"] as? String ?? ""
                        
                        if let bonusInr = rewardObj["Bonus_INR"] as? [String:Any],
                           let cashInr = bonusInr["Cash_INR"] as? Double{
                           let cashInrInt = Int(cashInr)
                            if reward == "claimed"{
                                claimedBonus += cashInrInt
                            }else{
                                unClaimedBonus += cashInrInt
                            }
                        }
                        if let bonusInr = rewardObj["HeldBonus_INR"] as? [String:Any],
                           let cashInr = bonusInr["Cash_INR"] as? Double{
                           let cashInrInt = Int(cashInr)
                            if reward == "claimed"{
                                claimedBonus += cashInrInt
                            }else{
                                unClaimedBonus += cashInrInt
                            }
                        }
                    }
                }
            }
        }
        
        claimedRewardVal.text = "₹\(claimedBonus)"
        unclaimedRewardVal.text = "₹\(unClaimedBonus)"
        
    }
    func calculateAggregateRewardAmount(challengeDetail:[String:Any]){
        claimedBonus = 0
        unClaimedBonus = 0
        
        if let rewardAmnt = challengeDetail["reward_amount"] as? [[String:Any]]{
            for rewardObj in rewardAmnt{
                let reward = challengeDetail["reward"] as? String ?? ""
                
                if let bonusInr = rewardObj["Bonus_INR"] as? [String:Any],
                   let cashInr = bonusInr["Cash_INR"] as? Double{
                    let cashInrInt = Int(cashInr)
                    if reward == "claimed"{
                        claimedBonus += cashInrInt
                    }else{
                        unClaimedBonus += cashInrInt
                    }
                }
                if let bonusInr = rewardObj["HeldBonus_INR"] as? [String:Any],
                   let cashInr = bonusInr["Cash_INR"] as? Double{
                    let cashInrInt = Int(cashInr)
                    if reward == "claimed"{
                        claimedBonus += cashInrInt
                    }else{
                        unClaimedBonus += cashInrInt
                    }
                }
            }
        }
        
        claimedRewardVal.text = "₹\(claimedBonus)"
        unclaimedRewardVal.text = "₹\(unClaimedBonus)"
        
    }
    
    func showSnackBar(campaignId:Int){
        
        if let challengeDetail = challengeDetail,let title = challengeDetail["title"] as? String{
            snackDescritption.text = "Your \(title) is successfully activated"
            UIView.animate(withDuration: 2, delay: 0) {
                self.snackBarBgView.alpha = 1
                self.hideSnackBar()
            }
        }
    }
    func hideSnackBar(){
        
        performAfterDelay(delay: 3) {
            UIView.animate(withDuration: 2, delay: 0) {
                self.snackBarBgView.alpha = 0
            }
        }
    }
}

//MARK: Seven Day CollectionView
extension ChallengeDetailVC:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dayInfo.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ChallengeCollectionCell", for: indexPath) as? ChallengeCollectionCell
        if let cell = cell{
            cell.claimedView.isHidden = true
            cell.failExpireView.isHidden = true
            cell.claimView.isHidden = true
            cell.timerView.isHidden = true
            cell.timerAnimView.isHidden = true
            
            let day = dayInfo[indexPath.row]
            let dayVal = day["day"] as? Int ?? 0
            let status = day["status"] as? String ?? ""
            let reward = day["reward"] as? String ?? ""
            
            let startDateStr = day["challenge_starttime"] as? String ?? ""
            let endDateStr = day["challenge_endtime"] as? String ?? ""
            
            let startDate = Constants.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss", date: startDateStr) ?? Date()
            let endDate = Constants.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss", date: endDateStr) ?? Date()

            let remainingTime = Constants.getRemainingTime(endDate:endDate,isDetail: true)
            
            //Setting bonus values
            setBonusValues(cell:cell,day:day)
            
            cell.dayNameLabel.textColor = UIColor(hexFromString: "Grey6E")
            if chunkType == "day"{
                cell.dayNameLabel.text = "Day \(dayVal)"
            }else{
//                let hoursDiff = (Calendar.current.dateComponents([.hour], from: startDate, to: endDate).hour ?? 0)
                let seconds = day["chunk_duration"] as? Int ?? 0
                let minutes = seconds / 60
                let hours = minutes / 60
                cell.dayNameLabel.text = "\(hours) hour"
                
            }
            for subView in cell.dotAnimationView.subviews{
                cell.dotAnimationView.willRemoveSubview(subView)
                subView.removeFromSuperview()
            }
            for subView in cell.giftAnimationView.subviews{
                cell.giftAnimationView.willRemoveSubview(subView)
                subView.removeFromSuperview()
            }
            cell.claimBtn.setImage(UIImage(named: "claim_check"), for: .normal)
            cell.claimBtn.setTitle("", for: .normal)
            
            if dayVal == activeDay && status == "pending" && isOpted{
                cell.dayNameLabel.textColor = UIColor(red: 1.00, green: 0.82, blue: 0.20, alpha: 1.00)
                cell.claimBtn.isHidden = true
                if chunkType != "day"{
                    cell.timerAnimView.isHidden = false
                    SwiftSampleUIControls.setAnimationView(view:cell.timerAnimView,jsonName:"timer_glass_anim",scaleX: 2.3,scaleY: 2.3)
                }
                
                
                SwiftSampleUIControls.setAnimationView(view:cell.dotAnimationView,jsonName:"dot")
                cell.timerView.backgroundColor = .clear
                cell.timerView.isHidden = false
                cell.timerLabel.text = "\(remainingTime) left"
            }else if dayVal == activeDay && status == "completed"{
                
                cell.dayNameLabel.textColor = UIColor(red: 1.00, green: 0.82, blue: 0.20, alpha: 1.00)
                if reward == "claimed"{
                    cell.claimedView.isHidden = false
                    cell.claimBtn.setImage(UIImage(named: "claim_check"), for: .normal)
                    cell.claimBonusBtn.setTitleColor(UIColor.white, for: .normal)
                    cell.claimBonusBtn.tintColor = UIColor.green
                    cell.unClaimedBonusBtn.setTitleColor(UIColor.white, for: .normal)
                    cell.unClaimedBonusBtn.tintColor = UIColor.systemYellow
                }else{
                    cell.claimView.isHidden = false
                    SwiftSampleUIControls.setAnimationView(view:cell.giftAnimationView,jsonName:"reward")
                    cell.claimBtn.setImage(nil, for: .normal)
                    cell.claimBtn.setTitle("Claim", for: .normal)
                    cell.claimBtn.tag = indexPath.row
                    cell.claimBtn.addTarget(self, action: #selector(tapClaimDayBonusBtn(_:)), for: .touchUpInside)
                    cell.claimBtn.setTitleColor(UIColor(named: "Green4E"), for: .normal)
                }
            }else if status == "pending"{
                if dayVal < activeDay{
                    cell.claimBtn.setImage(UIImage(named: "flag_grey16"), for: .normal)
                }else{
                    cell.claimBtn.setImage(UIImage(named: "flag_white16"), for: .normal)
                }
            }else if status == "expired"{
                cell.failExpireView.isHidden = false
                cell.failExpireLabel.text = "Expired"
                cell.claimBtn.setImage(UIImage(named: "flag_grey16"), for: .normal)
            }else if status == "failed"{
                cell.failExpireView.isHidden = false
                cell.failExpireLabel.text = "Failed"
                cell.claimBtn.setImage(UIImage(named: "closeRedIcon"), for: .normal)
                
            }else if status == "completed"{
                cell.dayNameLabel.textColor = UIColor.white
                if reward == "unclaimed"{
                    cell.claimView.isHidden = false
                    SwiftSampleUIControls.setAnimationView(view:cell.giftAnimationView,jsonName:"reward")
                    cell.claimBtn.setImage(nil, for: .normal)
                    cell.claimBtn.setTitle("Claim", for: .normal)
                    cell.claimBtn.tag = indexPath.row
                    cell.claimBtn.addTarget(self, action: #selector(tapClaimDayBonusBtn(_:)), for: .touchUpInside)
                    cell.claimBtn.setTitleColor(UIColor(named: "Green4E"), for: .normal)
                }else{
                    cell.claimedView.isHidden = false
                    cell.claimBtn.setImage(UIImage(named: "claim_check"), for: .normal)
                    cell.claimBonusBtn.setTitleColor(UIColor.white, for: .normal)
                    cell.claimBonusBtn.tintColor = UIColor.green
                    
                    cell.unClaimedBonusBtn.setTitleColor(UIColor.white, for: .normal)
                    cell.unClaimedBonusBtn.tintColor = UIColor.systemYellow
                }
            }
            
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { timer in
                cell.bgView.removeSubLayers(removeBorderOnly: true)
                if (self.challengeStatus == "active" || (self.challengeStatus == "pending" && self.isOpted)) && dayVal == self.activeDay{
                    self.setSelectedBgView(view: cell.bgView)
                }else{
                    self.setDeSelectedBgView(view: cell.bgView)
                }
            }
        }
        return cell ?? UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let day = dayInfo[indexPath.row]
        let dayVal = day["day"] as? Int ?? 0
        let status = day["status"] as? String ?? ""
        if dayVal == activeDay && isOpted{
            return CGSize(width: 80, height: 140)
        }else{
            return CGSize(width: 65, height: 140)
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? ChallengeCollectionCell{
            if cell.claimBtn.isEnabled && cell.claimBtn.titleLabel?.text == "Claim"{
                tapClaimDayBonusBtn(cell.claimBtn)
            }
        }
    }
    @objc func tapClaimDayBonusBtn(_ sender: UIButton) {
        let day = dayInfo[sender.tag]["day"] as? Int ?? -1
        callClaimDayBonusAPI(day: day, campaignId: campaignId)
    }
    func callClaimDayBonusAPI(day:Int? = nil,campaignId:Int){
        ChallengeDataModel.sharedInstance.postData.removeAll()
        var postData:[String:Any] = [:]
        postData["player_segment"] = "default"
        postData["event"] = "claim"
        postData["campaign_id"] = campaignId
        if let day = day{
            postData["day"] = day
        }
        ChallengeDataModel.sharedInstance.postData = postData
        challengePresenter.claimChallengeDayBonus()
    }
    func setBonusValues(cell:ChallengeCollectionCell,day:[String:Any]){
       
        cell.claimBonusBtn.setTitleColor(UIColor(hexFromString: "Grey6E"), for: .normal)
        cell.claimBonusBtn.tintColor = UIColor(hexFromString: "Grey6E")
        
        cell.unClaimedBonusBtn.setTitleColor(UIColor(hexFromString: "Grey6E"), for: .normal)
        cell.unClaimedBonusBtn.tintColor = UIColor(hexFromString: "Grey6E")
        cell.claimBonusBtn.isHidden = true
        cell.unClaimedBonusBtn.isHidden = true
        cell.claimBonusBtnHeight.constant = 0
        if let rewardAmnt = day["reward_amount"] as? [[String:Any]]{
            for rewardObj in rewardAmnt{
                
                if let bonusInr = rewardObj["Bonus_INR"] as? [String:Any],
                   let cashInr = bonusInr["Cash_INR"] as? Double,cashInr != 0.0{
                    let intInr = Int(cashInr)
                    cell.claimBonusBtn.setTitle("₹\(intInr)", for: .normal)
                    cell.claimBonusBtn.isHidden = false
                    cell.claimBonusBtnHeight.constant = 12
                }
                if let bonusInr = rewardObj["HeldBonus_INR"] as? [String:Any],
                   let cashInr = bonusInr["Cash_INR"] as? Double,cashInr != 0.0{
                    let intInr = Int(cashInr)
                    cell.unClaimedBonusBtn.setTitle("₹\(intInr)", for: .normal)
                    cell.unClaimedBonusBtn.isHidden = false
                }
            }
        }
    }
    func setSelectedBgView(view:UIView){
        SwiftSampleUIControls.setUIViewBg(view: view,
                                          cornerRadius: 2,
                                          backgroundColor: UIColor(hexFromString: "#111111"),
                                          isGradientBorder:true,
                                          borderColors: [UIColor(hexFromString: "#4ECC11"),
                                                         UIColor(hexFromString: "#355F22")],
                                          borderWidth: 2)
    }
    
    func setDeSelectedBgView(view:UIView){
        SwiftSampleUIControls.setUIViewBg(view: view,
                                          cornerRadius: 2,
                                          backgroundColor: UIColor(hexFromString: "#111111"),
                                          isGradientBorder:true,
                                          borderColors: [UIColor(hexFromString: "#2C2C2C"),
                                                         UIColor(hexFromString: "#1A1A1A")],
                                          borderWidth: 2)
    }
    
}

//MARK: Challenge Detail TableView

extension ChallengeDetailVC:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dayInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChallengeDetailTableCell") as? ChallengeDetailTableCell
        if let cell = cell{
            if indexPath.row == 0 {
                cell.headerView.isHidden = false
                cell.headerViewHeight.constant = 12
            }else{
                cell.headerView.isHidden = true
                cell.headerViewHeight.constant = 0
            }
            let count = indexPath.row + 1
            if count < 10{
                
                cell.counterLabel.text = "0\(count)"
            }else{
                cell.counterLabel.text = "\(count)"
            }
            cell.dayTitle.text = firstWord
            cell.actionLabel.text = dayInfo[indexPath.row]["task"] as? String ?? ""
            cell.rewardLabel.text = dayInfo[indexPath.row]["reward_description"] as? String ?? ""
        }
        return cell ?? UITableViewCell()
    }
}

//MARK: Get Challenge from List API
extension ChallengeDetailVC:ChallengeProtocol{
    func getMockData(){
        
        getChallengeSucces(resultVal: Constants.challengMockData, apiType: "getChallenge")
    }
    func getChallengeSucces(resultVal: [String : Any],apiType:String) {
        SKActivityIndicator.dismiss()
        if apiType == "getChallenge"{
            guard let challengeList = resultVal["challenges"] as? [[String:Any]] else {
                return
            }
            for challenge in challengeList{
                let id = challenge["campaign_id"] as? Int ?? 0
                if campaignId == id{
                    self.challengeDetail = challenge
                }
            }
            performAfterDelay(delay: 0.1) {
                self.setDetails()
            }
            if activatedCampaignId != 0{
                sendChallengeActivateEvent()
            }
        
        }else if apiType == "claimDayBonus"{
            if let result = resultVal["result"] as? [String:Any]{
                let campaignId = result["campaign_id"] as? Int ?? 0
                
                getChallenges()
                showChallengeCongratsPopup(campaignId:campaignId)
                
            }
        }else if apiType == "activateChallenge"{
            SKActivityIndicator.dismiss()
            if let result = resultVal["result"] as? [String:Any]{
                let campaignId = result["campaign_id"] as? Int ?? 0
                activatedCampaignId = campaignId
                showSnackBar(campaignId:campaignId)
                getChallenges()
            }
        }
    }
    
    func getChallengeFailed(errorVal: [String : Any],apiType:String) {
        SKActivityIndicator.dismiss()
        if apiType == "activateChallenge"{
            AppDelegate.appDelegateShareInstance.showCommonAlertForAllControllers(imageName: Constants.logoImageName, message: "Please check after some time")
        }else{
            if let result: [String: Any] =  errorVal["error"] as? [String: Any], let message = result["message"] as? String {
                AppDelegate.appDelegateShareInstance.showCommonAlertForAllControllers(imageName: Constants.logoImageName, message: message)
            } else if let exception = errorVal["exception"] as? String {
                AppDelegate.appDelegateShareInstance.showCommonAlertForAllControllers(imageName: Constants.logoImageName, message: exception)
            } else {
                AppDelegate.appDelegateShareInstance.showCommonAlertForAllControllers(imageName: Constants.logoImageName, message: Constants.someThingWrong)
            }
        }
    }
    
    func showChallengeCongratsPopup(campaignId:Int){
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "ChallengeCongratsPopup") as? ChallengeCongratsPopup{
            vc.view.backgroundColor = UIColor.clear
            if UIDevice.current.systemVersion.compare("13.0") == .orderedAscending{
                
                vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                vc.modalTransitionStyle = .crossDissolve
                
                if let popoverController = vc.popoverPresentationController {
                    popoverController.sourceView = self.view
                    popoverController.sourceRect = CGRect(x: 10, y: 5, width: 0, height: 0)
                    popoverController.permittedArrowDirections = .any
                    popoverController.backgroundColor = UIColor.clear
                    
                }
            }
            let challengeDesc = getDescription()
            vc.challengeInfo = challengeDesc
            sendClaimRewardEvent(campaignId: campaignId,challengeDesc:challengeDesc)
            self.present(vc, animated: true)
        }
    }
    
    func getDescription() -> ChallengeInfo?{
        let dayNum = ChallengeDataModel.sharedInstance.postData["day"] as? Int ?? 0
        var challengeInfo = ChallengeInfo()
        
        guard let challengeDetail = challengeDetail else { return nil }
        guard let title = challengeDetail["title"] as? String else { return nil}
        guard let type = challengeDetail["type"] as? String else { return nil}
        guard let campaignId = challengeDetail["campaign_id"] as? Int else { return nil}
        let challengeId = challengeDetail["challenge_id"] as? Int ?? 0
        let daysInfo = challengeDetail["days_info"] as? [[String:Any]] ?? []
        var firstWord:String = ""
        challengeInfo.challengeId = challengeId
        challengeInfo.campaignId = campaignId
        challengeInfo.type = type
        challengeInfo.title = title
        challengeInfo.startDate = challengeDetail["challenge_starttime"] as? String ?? ""
        challengeInfo.endDate = challengeDetail["challenge_endtime"] as? String ?? ""
        if type == "staged"{
            for day in daysInfo{
                let currentDay = day["day"] as? Int ?? 0
                if dayNum == currentDay{
                    let chunkType = day["chunk_type"] as? String ?? ""
                    let chunkStartTimeStr = day["challenge_starttime"] as? String ?? ""
                    let chunkStartTime = Constants.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss", date: chunkStartTimeStr) ?? Date()
                    
                    let chunkEndTimeStr = day["challenge_endtime"] as? String ?? ""
                    let chunkEndTime = Constants.getFormattedDate(format: "yyyy-MM-dd'T'HH:mm:ss", date: chunkEndTimeStr) ?? Date()
                    let hoursDiff = (Calendar.current.dateComponents([.hour], from: chunkStartTime, to: chunkEndTime).hour ?? 0)
                    if chunkType == "hour"{
                        if hoursDiff > 1{
                            firstWord = "Step"
                        }else{
                            firstWord = "Hour"
                        }
                    }else{
                        firstWord = "Day"
                    }
                    if let rewardAmnt = day["reward_amount"] as? [[String:Any]]{
                        for rewardObj in rewardAmnt{
                            
                            if let bonusInr = rewardObj["Bonus_INR"] as? [String:Any],
                               let cashInr = bonusInr["Cash_INR"] as? Double{
                                let intCash = Int(cashInr)
                                challengeInfo.bonus = String(intCash)
                            }
                            if let bonusInr = rewardObj["HeldBonus_INR"] as? [String:Any],
                               let cashInr = bonusInr["Cash_INR"] as? Double{
                                let intCash = Int(cashInr)
                                challengeInfo.heldBonus = String(intCash)
                            }
                        }
                    }
                }
            }
        }else{
            if let rewardAmnt = challengeDetail["reward_amount"] as? [[String:Any]]{
                for rewardObj in rewardAmnt{
                    
                    if let bonusInr = rewardObj["Bonus_INR"] as? [String:Any],
                       let cashInr = bonusInr["Cash_INR"] as? Double{
                        let intCash = Int(cashInr)
                        challengeInfo.bonus = String(intCash)
                    }
                    if let bonusInr = rewardObj["HeldBonus_INR"] as? [String:Any],
                       let cashInr = bonusInr["Cash_INR"] as? Double{
                        let intCash = Int(cashInr)
                        challengeInfo.heldBonus = String(intCash)
                    }
                }
            }
        }
        if type == "staged"{
            challengeInfo.description = "\(firstWord) \(dayNum) Rewards for \(title)"
        }else if type == "aggregate"{
            challengeInfo.description = "\(title) completed"
        }
        return challengeInfo
    }
    func getUnClaimedRewardCount(challenge:[String:Any]) -> (count:Int,day:Int){
        var unclaimedRewardCount = 0
        var unclaimedDay = -1
        guard let type = challenge["type"] as? String else {
            return (unclaimedRewardCount,unclaimedDay)
        }
        if type == "staged"{
            if let dayInfo = challenge["days_info"] as? [[String:Any]]{
                for day in dayInfo{
                    if let status = day["status"] as? String,status == "completed"{
                        if let rewardStatus = day["reward"] as? String,rewardStatus == "unclaimed"{
                            unclaimedRewardCount += 1
                            unclaimedDay = day["day"] as? Int ?? 0
                        }
                    }
                }
            }
        }else{
            if let status = challenge["status"] as? String, status == "completed",
               let rewardStatus = challenge["reward"] as? String, rewardStatus == "unclaimed"{
                unclaimedRewardCount += 1
            }
        }
        return (unclaimedRewardCount,unclaimedDay)
        
    }
}

extension ChallengeDetailVC{
    func sendChallengeDetailCTAEvent(cta:String){
        var properties = [String:Any]()
        properties["campaign_id"] = campaignId
        properties["challenge_id"] = challengeDetail?["challenge_id"] as? Int ?? 0
        properties["challenge_title"] = challengeDetail?["title"] as? String ?? ""
        properties["cta_text"] = cta
        SegmentAnalytics.sharedInstance.track(eventName: Event.CHALLENGE_DETAIL_CTA,
                                              eventProperties: properties,
                                              mediums: [ConfigKey.DESTINATION_CRTRACKER,
                                                        ConfigKey.DESTINATION_MOENGAGE,
                                                        ConfigKey.DESTINATION_PLOTLINE_TRACKER])
    }
    func sendChallengeDetailDetailEvent(){
        var properties = [String:Any]()
        properties["campaign_id"] = campaignId
        properties["challenge_id"] = challengeDetail?["challenge_id"] as? Int ?? 0
        properties["challenge_title"] = challengeDetail?["title"] as? String ?? ""
        SegmentAnalytics.sharedInstance.track(eventName: Event.CHALLENGE_DETAIL_DETAILS,
                                              eventProperties: properties,
                                              mediums: [ConfigKey.DESTINATION_CRTRACKER,
                                                        ConfigKey.DESTINATION_MOENGAGE,
                                                        ConfigKey.DESTINATION_PLOTLINE_TRACKER])
    }
    func sendClaimRewardEvent(campaignId:Int,challengeDesc:ChallengeInfo?){
        var properties = [String:Any]()
        properties["campaign_id"] = campaignId
        properties["challenge_id"] = challengeDetail?["challenge_id"] as? Int ?? 0
        properties["challenge_title"] = challengeDetail?["title"] as? String ?? ""
        properties["reward_type"] = challengeType == "staged" ? "partial" : "aggregate"
        properties["player_screen"] = "detail"
        if let challengeDesc = challengeDesc{
            if let intCash = Int(challengeDesc.bonus),let intPending = Int(challengeDesc.heldBonus){
                properties["cash_bonus"] = intCash
                properties["pending_bonus"] = intPending
                properties["total_bonus"] = intCash + intPending
            }
        }
        SegmentAnalytics.sharedInstance.track(eventName: Event.CLAIM_REWARDS,
                                              eventProperties: properties,
                                              mediums: [ConfigKey.DESTINATION_CRTRACKER,
                                                        ConfigKey.DESTINATION_MOENGAGE,
                                                        ConfigKey.DESTINATION_PLOTLINE_TRACKER])
    }
    func sendChallengeActivateEvent(){
        var properties = [String:Any]()
        let desc = getDescription()
        properties["campaign_id"] = activatedCampaignId
        properties["challenge_id"] = challengeDetail?["challenge_id"] as? Int ?? 0
        properties["challenge_title"] = challengeDetail?["title"] as? String ?? ""
        properties["player_screen"] = "detail"
        properties["challenge_start_date"] = desc?.startDate
        properties["challenge_end_date"] = desc?.endDate
        SegmentAnalytics.sharedInstance.track(eventName: Event.CHALLENGE_ACTIVATE,
                                              eventProperties: properties,
                                              mediums: [ConfigKey.DESTINATION_CRTRACKER,
                                                        ConfigKey.DESTINATION_MOENGAGE,
                                                        ConfigKey.DESTINATION_PLOTLINE_TRACKER])
        activatedCampaignId = 0
    }
}
