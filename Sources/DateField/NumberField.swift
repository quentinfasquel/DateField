//
//  NumberField.swift
//  DateField
//
//  Created by Quentin Fasquel on 08/12/2019.
//  Copyright © 2019 Quentin Fasquel. All rights reserved.
//

import UIKit

@available(iOS 10.0, *)
public final class NumberField: UIView, UITextFieldDelegate {
    
    public var numberOfDigits: Int = 2 {
        didSet {
            if numberOfDigits != oldValue {
                setupDigitLabels()
            }
        }
    }

    /// Assuming we are in base 10,
    /// - note: should fit on `numberOfDigits`
    public var maxValue: Int = 99 {
        willSet { precondition(newValue > minValue) }
        didSet { clampValue() }
    }
    /// A minimum value cannot really be decided as you type
    public var minValue: Int = 1 {
        willSet { precondition(newValue < maxValue) }
        didSet { clampValue() }
    }

    public var value: Int {
        get { return Int(textField.text ?? "") ?? minValue }
        set { setValue(newValue); clampValue() }
    }
    
    /// This property affects the input field's completion behavior
    ///
    /// If no new character/digit can be accepted (`maxValue` may be reached, lenght may still be less than `numberOfDigits`),
    /// settings this value to `true` will not invoke the completion handler immediately.
    /// Instead it will wait for the next character/digit to complete and pass the later to the completion handler.
    /// Default is `false`.
    public var allowsDeletionAfterReachingCount: Bool = false

    ///
    public var inputCompletionHandler: ((Int) -> Void)?
    
    // MARK: - Private Properties
    
    internal let stackView = UIStackView()
    internal let textField = UITextField()
    
    private lazy var stackViewLeadingConstraint = {
        return stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor)
    }()
    
    private lazy var stackViewCenterXConstraint = {
        return stackView.centerXAnchor.constraint(equalTo: centerXAnchor)
    }()
    
    private lazy var stackViewTopConstraint = {
        return stackView.topAnchor.constraint(equalTo: topAnchor)
    }()

    private lazy var stackViewBottomConstraint = {
        return stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
    }()
    
    private var shouldResetChange: Bool = false
    
    // MARK: - Private Methods
    
    private func setupViews() {
        stackView.axis = .horizontal
        stackView.distribution = .equalCentering
        stackView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stackView)

        textField.delegate = self
        textField.isHidden = true
        textField.keyboardType = .numberPad
        addSubview(textField)

        NSLayoutConstraint.activate([
            stackViewLeadingConstraint,
            stackViewCenterXConstraint,
            stackViewTopConstraint,
            stackViewBottomConstraint])
        
        //
        setupDigitLabels()
        
        // Set as input
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(becomeFirstResponder))
        addGestureRecognizer(tapGesture)

        isUserInteractionEnabled = true
        
        value = minValue
    }
    
    private func setupDigitLabels() {
        // Remove all arranged subviews
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
            stackView.removeArrangedSubview($0)
        }
        
        (0..<numberOfDigits).forEach { _ in
            let digitLabel = UILabel()
            stackView.addArrangedSubview(digitLabel)
        }
    }

    internal func digitLabel(atIndex index: Int) -> UILabel {
        return stackView.arrangedSubviews[index] as! UILabel
    }
    
    private func clampValue() {
        setValue(max(minValue, min(value, maxValue)))
    }

    private func setValue(_ value: Int) {
        let newText = formatValue(value)
        textField.text = newText
        updateValue(newText)
    }
    
    private func formatValue(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = numberOfDigits // digits do want before decimal
        formatter.paddingPosition = .beforePrefix
        formatter.paddingCharacter = ""
        return formatter.string(for: value)!
    }
    
    // typically receives a number without '0' prefix, '9'
    private func updateValue(_ text: String) {
        text.enumerated().forEach { index, character in
            let label = digitLabel(atIndex: index)
            label.isHidden = false
            label.text = String(character)
        }

        if stackView.arrangedSubviews.count > text.count {
            (text.count..<stackView.arrangedSubviews.count).forEach { index in
                digitLabel(atIndex: index).isHidden = true
            }
        }
        
        // Validate value
//        if allowsDeletionWhenMaxIsReached, let value = Int(text) {
//            if text.count < numberOfDigits, value * 10 > maxValue {
//                inputCompletionHandler?(0)
//            } // if newValue < minValue, expect
//        }
    }

    // MARK: - Lifecycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        setupViews()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: Responder
    
    override public func becomeFirstResponder() -> Bool {
        return textField.becomeFirstResponder()
    }

    public func becomeFirstResponderSetValue(initialValue: Int) -> Bool {
        setValue(initialValue)
        return becomeFirstResponder()
    }

    // MARK: - Text Field Delegate

    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        shouldResetChange = true
        return true
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // get the current text, or use an empty string if that failed
        let currentText = textField.text ?? ""
        // attempt to read the range they are trying to change, or exit if we can't
        guard let stringRange = Range(range, in: currentText) else {
            return false
        }
        
        let isDeletion = string.isEmpty
        let newText = shouldResetChange && !isDeletion ? string : currentText.replacingCharacters(in: stringRange, with: string)
        let newValue = Int(newText) ?? minValue
        shouldResetChange = false

        guard newValue <= maxValue else {
            // get last digit & complet
            let remainder = Int(string) ?? 0
            inputCompletionHandler?(remainder)

            return false
        }

        textField.text = newText

        switch newText.count {
        case 0..<numberOfDigits:
            updateValue(newText)

        case numberOfDigits where allowsDeletionAfterReachingCount:
            updateValue(newText)

        case numberOfDigits:
            updateValue(newText)
            let remainder = Int(string) ?? 0
            inputCompletionHandler?(remainder)

        default:
            break
        }

        return false
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        let newText = formatValue(value)
        updateValue(newText)
    }
}
