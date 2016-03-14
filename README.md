# OAStackView

Fork of OAStachView with behaviour aligned to UIStackView. Original source code https://github.com/oarrabi/OAStackView.

# Contribution

All contributions in any form are welcomed, if you find the project helpful, and you want to contribute then please do.

## Known Issues, and future improvements

### Missing functionality
`OAStackView` implements most of the features from `UIStackView` except the following:

- [ ] `baselineRelativeArrangement`   

	@property(nonatomic,getter=isBaselineRelativeArrangement) BOOL baselineRelativeArrangement;

- [x] `layoutMarginsRelativeArrangement`     


	@property(nonatomic,getter=isLayoutMarginsRelativeArrangement) BOOL layoutMarginsRelativeArrangement;    

`UIStackViewDistribution` is also partially implemented (2 elements out of 5 are still not implemented)    

- [x] `UIStackViewDistributionFill`
- [x] `UIStackViewDistributionFillEqually`    
- [x] `UIStackViewDistributionFillProportionally`   
- [ ] `UIStackViewDistributionEqualSpacing`    
- [ ] `UIStackViewDistributionEqualCentering`

Please refer to [UIStackView](https://developer.apple.com/library/prerelease/ios/documentation/UIKit/Reference/UIStackView_Class_Reference/) for proper documentation.

### Future improvements
The following would be nice to have for future versions

- [ ] Covering the remaining functionality from `UIStackView`
- [ ] Better Documentation
- [ ] Better test coverage for some edge cases
- [ ] Rewrite in swift, or more swift friendly

## Original Author

Omar Abdelhafith, o.arrabi@me.com

## License

OAStackView is available under the MIT license. See the LICENSE file for more info.
