// License Agreement for FDA MyStudies
// Copyright © 2017-2023 Harvard Pilgrim Health Care Institute (HPHCI) and its Contributors.
// Copyright 2023 Google LLC
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the &quot;Software&quot;), to deal in the Software without restriction, including without
// limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
// Software, and to permit persons to whom the Software is furnished to do so, subject to the following
// conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial
// portions of the Software.
// Funding Source: Food and Drug Administration (“Funding Agency”) effective 18 September 2014 as
// Contract no. HHSF22320140030I/HHSF22301006T (the “Prime Contract”).
// THE SOFTWARE IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
// PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT
// OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

import ActionSheetPicker_3_0
import Foundation
import IQKeyboardManagerSwift
import ResearchKit
import FirebaseAnalytics

let kFetalKickCounterStepDefaultIdentifier = "defaultIdentifier"
let kTapToRecordKick = "TAP TO RECORD A KICK"

let kConfirmMessage = "You have recorded "
let kConfirmMessage2 = " Proceed to submitting count and time?"

let kGreaterValueMessage = "This activity records the time it takes to feel "

let kProceedTitle = "Proceed"

let kFetalKickStartTimeStamp = "FetalKickStartTimeStamp"
let kFetalKickActivityId = "FetalKickActivityId"

let kFetalkickStudyId = "FetalKickStudyId"
let kFetalKickCounterValue = "FetalKickCounterValue"
let kFetalKickCounterRunId = "FetalKickCounterRunid"
let kSelectTimeLabel = "Select a time"

class FetalKickCounterStepViewController: ORKStepViewController {

  // MARK: - Outlets

  /// button to start task as well as increment the counter.
  @IBOutlet weak var startButton: UIButton?

  /// displays the title.
  @IBOutlet weak var startTitleLabel: UILabel?

  ///  displays the current timer Value.
  @IBOutlet weak var timerLabel: UILabel?

  /// displays current kick counts.
  @IBOutlet weak var counterTextField: UITextField?

  /// used to edit the counter value.
  @IBOutlet weak var editCounterButton: UIButton?

  /// separator line.
  @IBOutlet weak var seperatorLineView: UIView?

  /// button to submit response to server.
  @IBOutlet weak var submitButton: UIButton?

  @IBOutlet weak var editTimerButton: UIButton?

  /// Counter
  lazy var kickCounter: Int? = 0

  /// Timer for the task
  lazy var timer: Timer? = Timer()

  /// TimerValue
  lazy var timerValue: Int? = 0

  var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

  /// Total duration
  lazy var totalTime: Int? = 0

  lazy var maxKicksAllowed: Int? = 0

  lazy var taskResult: FetalKickCounterTaskResult = FetalKickCounterTaskResult(
    identifier: kFetalKickCounterStepDefaultIdentifier
  )

  // MARK: ORKStepViewController Initializer methods

  override init(step: ORKStep?) {
    super.init(step: step)
  }

  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    var initialTime = 0

    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(
      self,
      selector: #selector(appMovedToBackground),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )

    notificationCenter.addObserver(
      self,
      selector: #selector(appBecameActive),
      name: UIApplication.didBecomeActiveNotification,
      object: nil
    )

    submitButton?.layer.borderColor = kUicolorForButtonBackground

    if let step = step as? FetalKickCounterStep {

      let ud = UserDefaults.standard

      let activityId = ud.value(forKey: kFetalKickActivityId) as! String?
      var differenceInSec = 0
      var autoStartTimer = false
      if ud.bool(forKey: "FKC")
        && activityId != nil
        && activityId == Study.currentActivity?.actvityId
      {

        let previousTimerStartDate = ud.object(forKey: kFetalKickStartTimeStamp) as! Date
        let currentDate = Date()
        differenceInSec = Int(currentDate.timeIntervalSince(previousTimerStartDate))
        autoStartTimer = true
      }

      if differenceInSec >= 0 {
        initialTime += differenceInSec
      }

      // Setting the maximum time allowed for the task
      self.totalTime = step.counDownTimer!  //10

      // Setting the maximum Kicks allowed
      self.maxKicksAllowed = step.totalCounts!

      // Calculating time in required Format
      let hours = Int(initialTime) / 3600
      let minutes = Int(initialTime) / 60 % 60
      let seconds = Int(initialTime) % 60

      self.timerValue = initialTime

      self.timerLabel?.text =
        (hours < 10 ? "0\(hours):" : "\(hours):") + (minutes < 10 ? "0\(minutes):" : "\(minutes):")
        + (seconds < 10 ? "0\(seconds)" : "\(seconds)")

      if autoStartTimer {

        let previousKicks: Int? = ud.value(forKey: kFetalKickCounterValue) as? Int

        self.kickCounter = (previousKicks == nil ? 0 : previousKicks!)
        // Update Step Counter Value
        self.setCounter()

        self.startButtonAction(UIButton())
      }
      backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: {})
            
      // adding guesture to view to support outside tap
      let gestureRecognizer = UITapGestureRecognizer(
        target: self,
        action: #selector(FetalKickCounterStepViewController.handleTap(_:))
      )
      gestureRecognizer.delegate = self
      self.view.addGestureRecognizer(gestureRecognizer)
    }
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    counterTextField?.text = "00" + "\(self.kickCounter!)"
    
    let isAlertShown = UserDefaults.standard.bool(forKey: "isAlertShown")
    if Int((counterTextField?.text)!) == self.maxKicksAllowed! && !isAlertShown {
      UserDefaults.standard.setValue(true, forKey: "isAlertShown")
      self.showAlertOnCompletion()
    }
  }
  
  override func hasNextStep() -> Bool {
    super.hasNextStep()
    return true
  }

  override func goForward() {
    NotificationCenter.default.post(name: Notification.Name("GoForward"), object: nil)
    super.goForward()
  }

  override var result: ORKStepResult? {

    let orkResult = super.result
    orkResult?.results = [self.taskResult]
    return orkResult

  }

  // MARK: Helper Methods

  /// Updates the timer Value
  @objc func setCounter() {

    DispatchQueue.global(qos: .background).async {
      if self.timerValue! < 0 {
        self.timerValue = 0
        self.timer?.invalidate()
        self.timer = nil

        DispatchQueue.main.async {
          self.startButton?.isHidden = true
          self.startTitleLabel?.isHidden = true
          self.submitButton?.isHidden = false
        }

      } else {
        self.timerValue = self.timerValue! + 1
      }

      if self.timerValue! >= 0 {

        DispatchQueue.main.async {

          if self.timerValue! > self.totalTime! {
            self.setResults()
            UserDefaults.standard.setValue(true, forKey: "isAlertShown")
            self.showAlertOnCompletion()

          } else {
            self.editCounterButton?.isHidden = false
            self.setTimerValue()

          }
        }
      }
    }
  }

  /// Updates the UI with timer value.
  func setTimerValue() {

    let hours = Int(self.timerValue!) / 3600
    let minutes = Int(self.timerValue!) / 60 % 60
    let seconds = Int(self.timerValue!) % 60

    self.timerLabel?.text =
      (hours < 10 ? "0\(hours):" : "\(hours):") + (minutes < 10 ? "0\(minutes):" : "\(minutes):")
      + (seconds < 10 ? "0\(seconds)" : "\(seconds)")

    self.taskResult.totalKickCount = self.kickCounter!
  }

  /// Detects the tap gesture event.
  @objc func handleTap(_ sender: UITapGestureRecognizer) {
    counterTextField?.resignFirstResponder()
  }

  /// Stores the details of ongoing Fetal Kick task in local datatbase.
  @objc func appMovedToBackground() {

    let ud = UserDefaults.standard
    if ud.object(forKey: kFetalKickStartTimeStamp) != nil {

      ud.set(true, forKey: "FKC")
      
      ud.set(Study.currentActivity?.actvityId, forKey: kFetalKickActivityId)
      ud.set(Study.currentStudy?.studyId, forKey: kFetalkickStudyId)

      ud.set(self.kickCounter, forKey: kFetalKickCounterValue)
      
      // check if runid is saved
      if ud.object(forKey: kFetalKickCounterRunId) == nil {
        ud.set(Study.currentActivity?.currentRun.runId, forKey: kFetalKickCounterRunId)
      }
            
      ud.synchronize()
    }
  }

  /// Resets the keys when app becomes Active.
  @objc func appBecameActive() {

    let ud = UserDefaults.standard
    ud.set(false, forKey: "FKC")
    ud.synchronize()
    
  }

  /// Alerts User if Kick counts or time is exceeded.
  func showAlertForGreaterValues() {

    let message =
      kGreaterValueMessage + "\(self.maxKicksAllowed!) kicks, " + "please enter "
      + "\(self.maxKicksAllowed!) kicks only"
    
    UserDefaults.standard.setValue(true, forKey: "isGreaterAlertShown")
    
    Utilities.showAlertWithTitleAndMessage (
      title: kMessage,
      message: message,
      on: self,
      cancelAction: {
        Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
          buttonClickReasonsKey: "FetalKick Greater value cancel alert"
        ])
        UserDefaults.standard.setValue(true, forKey: "isGreaterAlertDismissed")
      })
  }

  /// Updates results for the Task.
  func setResults() {

    self.timer?.invalidate()
    self.timer = nil
    self.editTimerButton?.isHidden = false
    self.taskResult.totalKickCount = self.kickCounter == nil ? 0 : self.kickCounter!
    self.taskResult.duration = self.timerValue == nil ? 0 : self.timerValue!

  }

  func getTimerArray() -> [Any] {

    let hoursMax = Int(self.totalTime!) / 3600

    var hoursArray: [String] = []
    var minutesArray: [String] = []
    var secondsArray: [String] = []
    var i = 0
    while i <= hoursMax {
      hoursArray.append("\(i)" + " h")
      minutesArray.append("\(i)" + " m")
      secondsArray.append("\(i)" + " s")
      i += 1
    }
    i = hoursMax + 1
    while i <= 59 {
      minutesArray.append("\(i)" + " m")
      secondsArray.append("\(i)" + " s")
      i += 1
    }

    return [hoursArray, minutesArray, secondsArray]
  }

  func getIndexes() -> [Any] {

    let hoursIndex = Int(self.timerValue!) / 3600
    let minutesIndex = Int(self.timerValue!) / 60 % 60
    let secondsIndex = Int(self.timerValue!) % 60

    return [
      (hoursIndex > 0 ? hoursIndex : 0), (minutesIndex > 0 ? minutesIndex : 0),
      (secondsIndex > 0 ? secondsIndex : 0),
    ]
  }

  /// Alerts user on completion.
  func showAlertOnCompletion() {

    DispatchQueue.main.async {

      self.startButton?.isHidden = true
      self.startTitleLabel?.isHidden = true
      self.submitButton?.isHidden = false
    }

    let timeConsumed = (self.timerLabel?.text!)
    let message =
      kConfirmMessage + "\(self.kickCounter!) kicks in " + "\(timeConsumed!)."
      + kConfirmMessage2
    
//    UserDefaults.standard.setValue(true, forKey: "isAlertShown")
    
    UIUtilities.showAlertMessageWithTwoActionsAndHandler(
      NSLocalizedString(kConfirmation, comment: ""),
      errorMessage: NSLocalizedString(message, comment: ""),
      errorAlertActionTitle: NSLocalizedString(kTitleCancel, comment: ""),
      errorAlertActionTitle2: NSLocalizedString(kProceedTitle, comment: ""),
      viewControllerUsed: self,
      action1: {
        Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
          buttonClickReasonsKey: "OnCompletion Cancel Alert"
        ])
      },
      action2: {
        Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
          buttonClickReasonsKey: "OnCompletion GoFoward Alert"
        ])
        UserDefaults.standard.removeObject(forKey: "isAlertShown")
        UserDefaults.standard.synchronize()
        self.goForward()
      }
    )
  }

  // MARK: Button Actions

  @IBAction func editCounterButtonAction(_ sender: UIButton) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "FetalKickCounter EditCounter"
    ])
    counterTextField?.isUserInteractionEnabled = true
    counterTextField?.isHidden = false
    seperatorLineView?.isHidden = false
    counterTextField?.becomeFirstResponder()
  }

  @IBAction func startButtonAction(_ sender: UIButton) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "FetalKickCounter Start"
    ])

    if Int((self.counterTextField?.text)!)! == 0 {

      if self.timer == nil {
        self.timer = Timer.scheduledTimer(
          timeInterval: 1,
          target: self,
          selector: #selector(FetalKickCounterStepViewController.setCounter),
          userInfo: nil,
          repeats: true
        )

        // save start time stamp
        let ud = UserDefaults.standard
        if ud.object(forKey: kFetalKickStartTimeStamp) == nil {
          ud.set(Date(), forKey: kFetalKickStartTimeStamp)
        }
        ud.synchronize()

        RunLoop.main.add(self.timer!, forMode: RunLoop.Mode.common)

        // start button image and start title changed
        startButton?.setImage(UIImage(named: "kick_btn1.png"), for: .normal)
        startTitleLabel?.text = NSLocalizedString(kTapToRecordKick, comment: "")
      } else {
        self.kickCounter = self.kickCounter! + 1

        editCounterButton?.isHidden = false
        self.counterTextField?.text =
          self.kickCounter! < 10
          ? ("0\(self.kickCounter!)" == "00" ? "000" : "00\(self.kickCounter!)")
          : (self.kickCounter! >= 100 ? "\(self.kickCounter!)" : "0\(self.kickCounter!)")
      }

    } else {
      if self.kickCounter! < self.maxKicksAllowed! {
        self.kickCounter = self.kickCounter! + 1

        editCounterButton?.isHidden = false
        self.counterTextField?.text =
          self.kickCounter! < 10
          ? ("0\(self.kickCounter!)" == "00" ? "000" : "00\(self.kickCounter!)")
          : (self.kickCounter! >= 100 ? "\(self.kickCounter!)" : "0\(self.kickCounter!)")

        if self.kickCounter == self.maxKicksAllowed! {
          self.setResults()
          UserDefaults.standard.setValue(true, forKey: "isAlertShown")
          self.showAlertOnCompletion()
        }

      } else if self.kickCounter! == self.maxKicksAllowed! {
        self.setResults()
        UserDefaults.standard.setValue(true, forKey: "isAlertShown")
        self.showAlertOnCompletion()

      } else if self.kickCounter! > self.maxKicksAllowed! {
        self.showAlertForGreaterValues()
      }
    }
  }

  @IBAction func submitButtonAction(_ sender: UIButton) {

    self.taskResult.duration = self.timerValue!
    self.taskResult.totalKickCount = self.kickCounter == nil ? 0 : self.kickCounter!
    self.perform(#selector(self.goForward))
    
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "FetalKickCounterStep Submit"
    ])
  }

  @IBAction func editTimerButtonAction(_ sender: UIButton) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "FetalKickCounterStep EditTimer"
    ])

    let timerArray = self.getTimerArray()
    let defaultTime = self.getIndexes()

    let acp = ActionSheetMultipleStringPicker(
      title: kSelectTimeLabel,
      rows: timerArray,
      initialSelection: defaultTime,
      doneBlock: {
        _,
        _,
        indexes in
        
        Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
          buttonClickReasonsKey: "EditTimer Done Alert"
        ])

        let result: [String] = (indexes as! [String])
        let hours = result.first?.components(
          separatedBy: CharacterSet.init(charactersIn: " h")
        )
        let minutes = result[1].components(
          separatedBy: CharacterSet.init(charactersIn: " m")
        )
        let seconds = result.last?.components(
          separatedBy: CharacterSet.init(charactersIn: " s")
        )

        let hoursValue: Int = hours?.count != 0 ? Int(hours!.first!)! : 0
        let minuteValue: Int = minutes.count != 0 ? Int(minutes.first!)! : 0
        let secondsValue: Int = seconds?.count != 0 ? Int(seconds!.first!)! : 0

        self.timerValue = hoursValue * 3600 + minuteValue * 60 + secondsValue

        if hoursValue * 3600 + minuteValue * 60 + secondsValue > self.totalTime! {

          let hours = Int(self.totalTime!) / 3600
          let minutes = Int(self.totalTime!) / 60 % 60
          let seconds = Int(self.totalTime!) % 60

          let value =
            (hours < 10 ? "0\(hours):" : "\(hours):") + (minutes < 10 ? "0\(minutes):" : "\(minutes):")
            + (seconds < 10 ? "0\(seconds)" : "\(seconds)")

          Utilities.showAlertWithTitleAndMessageAction(
            title: kMessage,
            message: "Please select a valid time(Max " + value + ")",
            on: self, cancelAction: {
              Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
                buttonClickReasonsKey: "EditTimer Cancel Alert"
              ])
            }
          )

        } else {
          self.setTimerValue()
        }
        return
      },
      cancel: { _ in
        Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
          buttonClickReasonsKey: "EditTimer Cancel Alert"
        ])
        return
      },
      origin: sender
    )

    acp?.setTextColor(kUIColorForSubmitButtonBackground)
    acp?.pickerBackgroundColor = UIColor.white
    acp?.toolbarBackgroundColor = UIColor.white
    acp?.toolbarButtonsColor = kUIColorForSubmitButtonBackground
    acp?.show()
  }
}

open class FetalKickCounterTaskResult: ORKResult {

  open var totalKickCount: Int = 0
  open var duration: Int = 0

  override open var description: String {
    return "hitCount:\(totalKickCount), duration:\(duration)"
  }

  override open var debugDescription: String {
    return "hitCount:\(totalKickCount), duration:\(duration)"
  }
}

// MARK: GetureRecognizer delegate
extension FetalKickCounterStepViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(
    _: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith shouldRecognizeSimultaneouslyWithGestureRecognizer:
      UIGestureRecognizer
  ) -> Bool {
    return true
  }
}

// MARK: TextField Delegates
extension FetalKickCounterStepViewController: UITextFieldDelegate {

  func textFieldDidBeginEditing(_ textField: UITextField) {

    if textField == counterTextField {
      if (textField.text?.count)! > 0 {
        if Int(textField.text!)! == 0 {
          textField.text = ""
        }
      }
    }
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {

    if textField == counterTextField {
      counterTextField?.resignFirstResponder()

      if textField.text?.count == 0 {
        textField.text = "000"
        self.kickCounter = 000
      }
    }
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {

    if textField == counterTextField!
      && (Utilities.isValidValue(someObject: counterTextField?.text as AnyObject?) == false
        || Int(
          (counterTextField?.text)!
        )! <= 0)
    {
      counterTextField?.resignFirstResponder()
      if textField.text?.count == 0 || (Int((counterTextField?.text)!) != nil) {
        textField.text = "000"
        self.kickCounter = 000
      }
    } else {
      self.kickCounter = Int((counterTextField?.text)!)

      if textField.text?.count == 2 {
        counterTextField?.text = "0" + textField.text!
        self.kickCounter = (Int((counterTextField?.text)!))
      } else if (textField.text?.count)! >= 3 {
        let finalValue = (Int((counterTextField?.text)!))

        if finalValue! < 10 {
          counterTextField?.text = "00" + "\(finalValue!)"
        } else if finalValue! >= 10 && finalValue! < 100 {
          counterTextField?.text = "0" + "\(finalValue!)"
        } else {
          counterTextField?.text = "\(finalValue!)"
        }

      } else if textField.text?.count == 1 {
        let finalValue = (Int((counterTextField?.text)!))
        counterTextField?.text = "00" + "\(finalValue!)"
      }

      if self.kickCounter == self.maxKicksAllowed! {
        self.setResults()
        UserDefaults.standard.setValue(true, forKey: "isAlertShown")
        self.showAlertOnCompletion()
      }

    }

  }

  func textField(
    _ textField: UITextField,
    shouldChangeCharactersIn range: NSRange,
    replacementString string: String
  ) -> Bool {

    let finalString = textField.text! + string

    if textField == counterTextField && finalString.count > 0 {
      
      if Int(finalString)! <= self.maxKicksAllowed! {

        return true

      } else {
        if Int(finalString)! >= self.maxKicksAllowed! {
          let finalValue = (Int((counterTextField?.text)!))
          self.editCounterButton?.isUserInteractionEnabled = true
          counterTextField?.isHidden = false
          seperatorLineView?.isHidden = false
          counterTextField?.becomeFirstResponder()
          counterTextField?.text = "\(finalValue ?? 0)"
        }
        
        self.showAlertForGreaterValues()
        return false
      }
    } else {
      return true
    }
  }
}
