# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Minor features that don't break backwards compatibility are released as patches.

## 0.6.0 [UNRELEASED]

### Changed

- `MethodProxy#rewrite_signature` only rewrites typed params and the return type, keeping the rest of the source as is
- `ParamProxy#export(typed: false)` uses the source of the default value rather than its evaluated value
- `ReturnProxy` has its own source rather than the method's source
- `MethodProxy#expressions?` is only true for a return type when it has an expression

### Added

- Byte offsets on sources/proxies (`start_offset`, `end_offset`, `start_column`, `line_offset`)
- `MethodProxy#signature_end_line` and `ParamProxy#default`
- `MethodProxy#receiver` and `MethodProxy#receiver?` for methods defined like `def self.method`
- `Lowkey[file_path]` loads the file on first access and returns the cached file proxy after that
- `MethodCallProxy` for method calls, with `node`, `arguments`, `keywords`, `default`, `rewrite(text)` and `remove`. Details and the source are read from the node on first access
- `ModuleProxy#method_calls` builds method call proxies on first access and `ModuleProxy#method_call_nodes` has the nodes
- `Source#rewrite_lines` to edit lines without changing the amount of lines

### Fixed

- Rewriting multiline signatures, endless methods, splats, blocks, code before `def` and comments after the signature
- `def ClassName.method` and `class << ClassName` methods are class methods, and methods defined on other objects are neither class nor instance methods

## 0.5.0

### Added

- RBS export
- Untyped export
- Support virtual file systems

## 0.4.0

### Added

- Proxy source code rewriting via `wrap()`
- Proxy source code exporting via `export()`

### Added

- Support queries
- Create param and return proxies

## 0.2.0

### Added

- Enable or disable caching of results

## 0.1.0

### Added

- Split out LowType::FileParser into Lowkey
