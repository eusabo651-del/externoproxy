Button {
    Task {
        await manager.validate(key: inputKey)
        if manager.isValidated { onValidated() }
    }
} label: {
    if manager.isLoading {
        ProgressView().tint(.white)
    } else {
        Text("Validate").fontWeight(.semibold)
    }
}
