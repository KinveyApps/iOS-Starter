# Kinvey iOS SDK

The Kinvey iOS SDK is a package that can be used to develop iOS applications on the Kinvey platform.
Refer to the Kinvey [DevCenter](http://devcenter.kinvey.com/ios-v3.0) for documentation on using Kinvey.

In the version 3 of the library, all new code is written in Swift and any application using v3 must also use Swift to access the API.

While we transition from Objective C to the latest Swift versions, we will use the following branching scheme. Please, pick the right version of our library depending of which langugage / version you are using:

| Language / Version | Kinvey SDK Version | Development Branch |
| ------------------ | ------------------ | --------------- |
| Swift 2.2 | 3.1.x | `develop` |
| Swift 2.3 | 3.2.x | swift-2.3 |
| Swift 3.x | 3.3.x | swift-3.0 |
| Objective-C | 1.x | 1.x | 

Note: 
* The `master` branch represents the latest [release](https://devcenter.kinvey.com/ios-v3.0/downloads) of the SDK. See the [CONTRIBUTING](CONTRIBUTING.md) guidelines for details on submitting code.
* On version 1.x, use the `KinveyKit` workspace. On all other versions, use the `Kinvey` workspace.

## Building
You will need [Carthage](https://github.com/Carthage/Carthage), [Jazzy](https://github.com/realm/jazzy) and `Xcode command line tools` installed to be able to build the SDK.

* `carthage build`: build the dependencies frameworks using `Carthage`
* `make`: runs a script that compile and generate the documentation files using `Jazzy`

## Testing

Use `Xcode` to run the unit tests.

* Open the file `Kinvey.xcworkspace` in Xcode
* Select the `Kinvey` scheme
* Select the menu item `Product` -> `Test` or press `Command+U`

Or run the command line:

`make test`

## Releasing
We use [GitFlow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) workflow for better management.

The workflow for releasing a new version of the SDK is as follows:

1. Merge all waiting pull requests / feature branches on the develop branch.
2. Bump the version running `make set-version` on the develop branch.
3. Checkout the master branch and merge the develop branch.
4. Tag the version with git.
5. Push all changes.
6. Upload the zip file containing all the binary files for Amazon AWS.
7. Run `make deploy-cocoapods` in order to publish the new release for [CocoaPods](https://cocoapods.org)
8. Publish `release notes`, `API Reference Docs`, and the `Download` section in the DevCenter repo.
9. Push all changes to deploy.
10. Send the email with the release notes for the `Customer Service` and `Development` team

### Version Management
Updating the sdk version should follow [Semantic Version 2.0.0](http://semver.org/):

* Major (x.0.0): when making an incompatible API changes.
* Minor (3.x.0): when adding functionality in a backwards-compatible manner.
* Patch (3.0.x): when making backwards-compatible bug fixes or enhancements.

## License
See [LICENSE](LICENSE) for details.

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md) for details on reporting bugs and making contributions.
