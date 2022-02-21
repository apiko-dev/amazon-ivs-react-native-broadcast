struct IVSBroadcastCameraViewError: LocalizedError
{
    let message: String

    init(_ message: String)
    {
        self.message = message
    }

    public var errorDescription: String?
    {
        return message
    }
}
