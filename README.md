#  Yet Another Crypto Pricing App (yacpa)

Example of using iOS 13 Combine/SwiftUI with an MVVM Flavor.  

## To BUILD and RUN: ##

1. Requires XCode 11 beta 4.  
1. Have only tested on Simulator in iOS 13.
1. Complains if swiftlint is not installed.  You may either need to install it, or change the build step to comment it out.


The only 3rd party Open Source libraries I am using are Quick/Nimble for UnitTests.

You may seen AlamoFire as an installed Switft Package Dependency.
While XCode 11 seems to let you add Swift Packages it is still a mystery how to remove them.  None of the source should be using Alamofire.


## Notes ##

* Coindesk/CoinDeskRequest.swift
    * a low level request enumeration.  Maps encodes URLS, and can build and execute fetch requests.


* Coindesk/CoinDeskModels.swift
  * All of CoinDesk's API Results as Decodable structs.  Some definite odd choices in their API,  but I intentionally leave the JSON models to be name/type compatible with their API.  


* Coindesk/CoinDeskAPI.swift
  * defines CoinDeskAPIType and CoinDeskAPI.   Creates an API layer that has Reactive functions for each API call.


* DummyData.swift/DummyCoinDeskAPI.swift
  * An alternate implentation of CoinDeskAPIType for testing


* Model/APIModel.swift
  * A Model layer built on top of the APIType layer.


* Model/RefreshableValue.swift
  * A way to make it easier to translate async operations (usually from CoindeskAPI) and make Publishers that auto update based on refresh.  There is some early support for error handling, and an 'isRefreshing' Publisher, but I didn't get time to test either.


* Views/PriceList.swift
  * the Top level list of prices, and it's related ViewModels


* Views/PriceListRow.swift
  * the RowElement  and it's related ViewModels


* Views/DetailView.swift
  * the Detail view and it's related ViewModels.  Two different ViewModels depending upon if the data is 'historical' or 'live' since each needs very different API calls.


* Utils/*
  * Some simple utilities and Extensions.


The 'today widget' target shares the MVVM API and Layer classes.
The View is just a Storyboard, but it updates reactively.  THe only thing I didn't get time to do was to wire up the widgetPerformUpdate to be 'correct'.  I worry that I am lying that the refresh is done when it MAY NOT BE.  But everything seems to work.




## Some Observations ##

There are some unit Tests, mostly to test some of the JSON Parsing.
I had planned on doing more,  but spent more time wrangling Combine.

SwiftUI was VERY easy to pickup, Combine was trickier - EVEN if you are experienced at RxSwift/ReactiveSwift.  

There was a lot more Combine efforts, cause this was my first Combine real app.  I kept getting stuck trying to understand the 'Apple Combine' way of Reactive coding and have to unlearn some habits from ReactiveSwift.

I definitely underestimated how different it is from RxSwift/ReactiveSwift, but I can see how crazy powerful it will be.

The PRICES and DATES should be Localized.  (Currency symbols will appear on the left or right based on the iPhone's Locale).

While it's pretty much all the features you wanted...  some things I would have added if I had more time.

1. Real Markup comments for all code.   I used to have an XCode Extension that auto-generated Swift Comments but idk where it went.
1. ViewModel UnitTests using the DummyAPI.
1. Pull To Refresh (this turns out to be a challenge on SwiftUI...).
1. Show the 'change' in price for today vs yesterday's close.
1. 'Settings' to let you change the default 'currency' from 'Euro' to anything CoinDesk supports.
1. Can SwiftUI Previews/Canvas with the DummyAPI?  It doesn't seem to want to work - possibly due to the async nature of our API.


## Known Issues ##

NOTE:  I have ONLY TESTED THIS In the XCode 11 Beta 4 Simulator.

It works on iPhone and Mac just fine.

##### WARNING on iPAD: #####
*Does not work in portrait view on iPad!*

There is a weird layout bug related to the SplitView.  Doesn't show anything in portrait mode, but if you rotate it it works fine.  It seems to putting the 'DetailView' on top of the NavigationView in portraid mode?  I think this is a SwiftUI bug.

##### IGNORE 'nw_endpoint_get_type' #####
There is also weird 'nw_endpoint_get_type called with null endpoint, dumping backtrace:' error that happens at runtime, and shows a stacktrace.   It took me a while to realize I can just ignore it.  It's definitely an XCode 11/iOS 13 Beta issue, and you can ignore it.
