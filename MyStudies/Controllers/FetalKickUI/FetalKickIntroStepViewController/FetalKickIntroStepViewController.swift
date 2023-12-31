// License Agreement for FDA MyStudies
// Copyright © 2017-2023 Harvard Pilgrim Health Care Institute (HPHCI) and its Contributors. Permission is
// hereby granted, free of charge, to any person obtaining a copy of this software and associated
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

import Foundation
import ResearchKit
import FirebaseAnalytics

let kFetalKickIntroStepDefaultIdentifier = "FetalIntroStepIdentifier"

class FetalKickIntroStep: ORKStep {
  var introTitle: String?  // MainTitle for the Task
  var subTitle: String?  //Subtitle for Task
  var displayImage: UIImage?
}

class FetalKickIntroStepViewController: ORKStepViewController {

  // MARK: - Outlets
  @IBOutlet weak var descriptionLabel: UILabel?

  /// button to start task as well as increment the counter.
  @IBOutlet weak var buttonNext: UIButton?

  // MARK: - Properties

  var iconImage: UIImage?

  /// Custom Title Label
  var titleLabel: UILabel?

  // MARK: ORKStepViewController overriden methods

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

    if let step = step as? FetalKickIntroStep {
      self.titleLabel?.text = step.introTitle
      self.descriptionLabel?.text = step.subTitle
      self.iconImage = step.displayImage
      buttonNext?.layer.borderColor = kUicolorForButtonBackground
    }
  }

  override func hasNextStep() -> Bool {
    super.hasNextStep()
    return true
  }

  override func goForward() {
    super.goForward()
  }

  // MARK: IBActions

  @IBAction func nextButtonAction(_ sender: UIButton) {
    Analytics.logEvent(analyticsButtonClickEventsName, parameters: [
      buttonClickReasonsKey: "FetalKickIntroStep Next"
    ])
    self.goForward()
  }

}
