## [Unreleased]

- If a reply block for a Notification raises, suppress the error as defined in the spec

## [0.2.0] - 2025-06-01

**Breaking changes**: As I work towarsd a 1.0.0 release, I've changed the interface to ensure a uniform interface for [JSON-RPC 2.0 batch processing](https://www.jsonrpc.org/specification#batch). I believe we have a much more robust implementation now, so I will try to stay more consistent, but please be cautious upgrading until 1.0.0 is released and we finalize the interface.

- Adds full support for batch processing with uniform reply block interface.
- Better error handling, though this is my biggest area of improvement.
- InvalidMessage is now returned when a message is invalid, allowing the receiver to inspect and handle the message, but still benefiting from automatic replies.

## [0.1.0] - 2025-04-20

- Initial release
