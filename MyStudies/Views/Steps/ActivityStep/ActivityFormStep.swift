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

let kStepFormSteps = "steps"

class ActivityFormStep: ActivityStep {

  /// itemsArray stores the step details
  var itemsArray: [[String: Any]]

  override init() {
    self.itemsArray = Array()
    super.init()

  }

  /// Initializer method which initializes all params
  /// - Parameter stepDict: Dictionary which contains all the properties of ActivityForm Step
  override func initWithDict(stepDict: [String: Any]) {
    if Utilities.isValidObject(someObject: stepDict as AnyObject?) {

      super.initWithDict(stepDict: stepDict)
      if Utilities.isValidObject(someObject: stepDict[kStepFormSteps] as AnyObject) {
        self.itemsArray = (stepDict[kStepFormSteps] as? [[String: Any]])!
      }
    }
  }

  /// Creates Form step based on the ActivityStep and using itemsArray and return ORKFromStep. NOTE: this method only return formStep of Questions, does not support ActiveTask as items
  func getFormStep() -> ORKFormStep? {

    if Utilities.isValidValue(someObject: key as AnyObject?)
      && Utilities.isValidObject(someObject: self.itemsArray as AnyObject?)
    {

      let step: ORKFormStep?

      if self.repeatable == true {

        step = RepeatableFormStep(
          identifier: key!,
          title: (self.title == nil ? "" : self.title!),
          text: text!
        )
        (step as? RepeatableFormStep)!.repeatable = true
        (step as? RepeatableFormStep)!.repeatableText = self.repeatableText

      } else {
        step = ORKFormStep(
          identifier: key!,
          title: self.title ?? "",
          text: text!
        )
      }

      if Utilities.isValidValue(someObject: title! as AnyObject?) {
        step?.title = title!
      }
      if Utilities.isValidValue(someObject: self.skippable! as AnyObject?) {
        step?.isOptional = self.skippable!
      }

      var formItemsArray = [ORKFormItem]()

      for dict in self.itemsArray {

        if Utilities.isValidObject(someObject: dict as AnyObject?) {

          let questionStep: ActivityQuestionStep? = ActivityQuestionStep()
          questionStep?.initWithDict(stepDict: dict)

          guard let orkQuestionStep = questionStep?.getQuestionStep()
          else { continue }

          let formItem01 = ORKFormItem(
            identifier: orkQuestionStep.identifier,
            text: orkQuestionStep.question,
            answerFormat: orkQuestionStep.answerFormat
          )
          formItem01.placeholder =
            orkQuestionStep.placeholder == nil
            ? "" : orkQuestionStep.placeholder
          formItem01.isOptional = (questionStep?.skippable)!
          formItemsArray.append(formItem01)

        }
      }

      if self.repeatable == true {
        (step as? RepeatableFormStep)!.initialItemCount = formItemsArray.count
      }

      step?.formItems = formItemsArray
      return step

    } else {
      return nil  // Form Data is null
    }
  }
}
