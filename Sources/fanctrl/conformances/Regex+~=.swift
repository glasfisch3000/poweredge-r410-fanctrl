func ~=<Output>(regex: Regex<Output>, str: String) -> Bool {
    (try? regex.wholeMatch(in: str)) != nil
}

func ~=<Output>(regex: Regex<Output>, str: Substring) -> Bool {
    (try? regex.wholeMatch(in: str)) != nil
}
