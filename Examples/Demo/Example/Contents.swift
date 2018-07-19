//
//  Contents.swift
//  Example
//
//  Created by Måns Bernhardt on 2018-05-09.
//  Copyright © 2018 iZettle. All rights reserved.
//

import UIKit
import Flow
import Form

extension UIViewController {
    func presentContents() -> Disposable {
        let bag = DisposeBag()

        displayableTitle = "Contents"

        func present(_ setup: @escaping (UIViewController) -> Disposable) -> Disposable {
            let vc = UIViewController()
            self.navigationController?.pushViewController(vc, animated: true)
            return setup(vc)
        }

        let form = FormView()
        let stylingSection = form.appendSection(header: "Styling")

        let segmented = UISegmentedControl(titles: styles.map { $0.title }, index: styleIndex)
        activate(segmented.heightAnchor == 28) // Intrinsict content size for small resizeable images will set the height to small
        bag += stylingSection.appendRow(title: "Segmented").append(segmented).onValue {
            styleIndex = $0

            // Update current style defaults and reload UI.
            styles[styleIndex].install()
            self.navigationController?.navigationBar.tintColor = UINavigationBar.appearance().tintColor
            bag.dispose()
            bag += self.presentContents()
        }

        let label = UILabel(value: "Hello")
        stylingSection.appendRow(title: "Label").append(label)

        let firstField = UITextField(value: "Hello", placeholder: "PlaceHolder")
        firstField.accessibilityIdentifier = "firstField"
        
        let textRow = stylingSection.appendRow(title: "TextField").append(firstField)
        bag += textRow.atOnce().map { $0 }.bindTo(label, \.value)
        
        let secondField = UITextField(value: "", placeholder: "")
        secondField.accessibilityIdentifier = "secondField"
        let secondRow = stylingSection.appendRow(title: "SecondRow").append(secondField)
        secondRow.row.accessibilityIdentifier = "secondRow"
        
        let thirdField = UITextField(value: "", placeholder: "")
        thirdField.accessibilityIdentifier = "thirdField"
        
        let testSwitch = UISwitch()
        testSwitch.accessibilityIdentifier = "switch"
        
        let switchRow = stylingSection.appendRow(title: "SwitchRow").append(thirdField).append(testSwitch)
        switchRow.row.accessibilityIdentifier = "switchRow"
        
        let valueField = ValueField(value: 0)
        valueField.accessibilityIdentifier = "valueField"
        let valueRow = stylingSection.appendRow(title: "ValueRow").append(valueField)
        
        
        valueRow.row.accessibilityIdentifier = "valueRow"
        
        let buttonRow = stylingSection.appendRow(title: "Button").append(UIButton(title: "Hello"))

        bag += stylingSection.appendRow(title: "Switch").append(UISwitch(value: true)).atOnce().negate().bindTo(buttonRow, \.[animated: \.isHidden])

        bag += form.appendSection().appendRow(title: "Values").append(.chevron).onValueDisposePrevious {
            present { $0.presentValues() }
        }

        let messages = ReadWriteSignal(testMessages)
        bag += form.appendSection().appendRow(title: "Messages").append(.chevron).onValueDisposePrevious {
            present { messagesController in
                let bag = DisposeBag()

                bag += messagesController.present(messages: messages.readOnly())

                bag += messagesController.navigationItem.addItem(UIBarButtonItem(system: .compose), position: .right).onValue {
                    let composeController = UIViewController()
                    let navigationController = UINavigationController(rootViewController: composeController)
                    navigationController.modalPresentationStyle = .formSheet
                    messagesController.present(navigationController, animated: true)

                    composeController.presentComposeMessage().always {
                        navigationController.dismiss(animated: true, completion: nil)
                    }.onValue { message in
                        messages.value.insert(message, at: 0)
                    }
                }

                return bag
            }
        }

        let tableStyles: [(String, DynamicTableViewFormStyle)] = [("Grouped Tables", .grouped), ("Plain Tables", .plain)]
        for (title, style) in tableStyles {
            let section = form.appendSection(header: title)

            bag += section.appendRow(title: "Forms").append(.chevron).onValueDisposePrevious {
                present { $0.presentTableUsingForm(style: style) }
            }

            bag += section.appendRow(title: "TableKit").append(.chevron).onValueDisposePrevious {
                present { $0.presentTableUsingKit(style: style) }
            }

            bag += section.appendRow(title: "TableKit and Reusable").append(.chevron).onValueDisposePrevious {
                present { $0.presentTableUsingKitAndReusable(style: style) }
            }

            bag += section.appendRow(title: "TableKit, Reusable and forms header").append(.chevron).onValueDisposePrevious {
                present { $0.presentTableUsingKitAndReusableWithFormHeader(style: style) }
            }

            bag += section.appendRow(title: "TableKit, Reusable and blending forms header").append(.chevron).onValueDisposePrevious {
                present { $0.presentTableUsingKitAndReusableWithBlendingFormHeader(style: style) }
            }
        }

        bag += self.install(form)

        return bag
    }
}

extension DefaultStyling {
    static func installSystem() {
        UINavigationBar.appearance().tintColor = UIApplication.shared.keyWindow!.tintColor
        current = .system
    }
}

private var styleIndex = 0
private var styles: [(title: String, install: () -> Void)] = [
    ("System", DefaultStyling.installSystem),
    ("Custom", DefaultStyling.installCustom),
]
