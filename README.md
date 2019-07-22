#  Yet Another Crypto Pricing App (yacpa)

To BUILD and RUN:

- Uses Combine/SwiftUI  with an MVVM Flavor.  

This took me a bit longer than I had wanted, as I had to relearn Reactive MVVM ontop of Combine.

1 - Requires XCode 11 beta 4.  
2 - Have only tested on Simulator in iOS 13.    Would require an IOS 13 Beta 4 I think.
3 - Complains if swiftlint is not installed.  


The target of the app, was to use SwiftUI, Combine to create a set of MVVM based objects.


Notes:
Coindesk/
    CoinDeskRequest.swift 
            - a low level request enumeration.  Maps encodes URLS, and can build and execute fetch requests.
    CoinDeskModels.swift 
            - All of CoinDesk's API Results as Decodable structs.  Some definite odd choices in their API,  but I intentionally leave the JSON models to be name/type compatible with their API.  
    CoinDeskAPI.swift 
            - defines CoinDeskAPIType and CoinDeskAPI.   Creates an API layer that has Reactive functions for each API call.
    DummyData.swift/DummyCoinDeskAPI.swift 
            - An alternate implentation of CoinDeskAPIType for testing
Model/
    APIModel.swift
            - A Model layer built on top of the APIType layer.
    RefreshableValue.swift
            - A way to make it easier to translate async operations (usually from CoindeskAPI) and make Publishers that auto update based on refresh.  There is some early support for error handling, and an 'isRefreshing' Publisher, but I didn't get time to test either.
Views/
    PriceList.swift
        - the Top level list of prices, and it's related ViewModels
    PriceListRow.swift
        - the RowElement  and it's related ViewModels
    DetailView.swift
        - the Detail view and it's related ViewModels.  Two different ViewModels depending upon if the data is 'historical' or 'live' since each needs very different API calls.
Utils/
    Some simple utilities and Extensions. 



There is an API Layer (CoinDeskAPIType).


The only 3rd party Open Source libraries I am using are Quick/Nimbe. 
        You may seen AlamoFire as an installed Switft Package Dependency.  
        While XCode 11 seems to let you add Swift Packages it is still a mystery how to remove them. 


There are 'some' unit Tests, mostly to test some of the JSON Parsing.
I had planned on doing more,  but spent more time wrangling Combine.

There was a lot more Combine refactoring (cause this was my first Combine real app.)
SwiftUI was VERY easy to pickup, Combine was tricky - EVEN if you are experienced at RxSwift/ReactiveSwift. 
I definitely underestimated how different it is from RxSwift/ReactiveSwift, but I can see how crazy powerful it will be.

The PRICES and DATES should be Localized.  (Currency symbols will appear on the left or right based on the iPhone's Locale).

While it's pretty much all the features you wanted...  some things I would have added if I had more time.

1)  Real Markup comments for all code.   I used to have an XCode Extension that auto-generated Swift Comments but idk where it went.
2)  ViewModel UnitTests using the DummyAPI.
3)  Pull To Refresh (this turns out to be a challenge on SwiftUI...).
4)  Show the 'change' in price for today vs yesterday's close.
5) 'Settings' to let you change the default 'currency' from 'Euro' to anything CoinDesk supports. 
6) Can SwiftUI Previews/Canvas with the DummyAPI?  It doesn't seem to want to work - possibly due to the async nature of our API.

NOTE:  I have ONLY TESTED THIS In the SImulator. 

It works on iPhone and Mac just fine.
For iPad - there is a weird layout bug related to the SplitView.  Doesn't show anything in portrait mode, but if you rotate it it works fine.  It seems to putting the 'DetailView' on top of the NavigationView in portraid mode?  I think this is a SwiftUI bug. 

There is also weird 'nw_endpoint_get_type called with null endpoint, dumping backtrace:' error that happens at runtime, and shows a stacktrace.   It took me a while to realize I can just ignore it.  It's definitely an XCode 11/iOS 13 Beta issue, and you can ignore it.












