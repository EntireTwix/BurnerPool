# BurnerPool
A library for [CCash](https://github.com/EntireTwix/CCash) connected services that manages pools of burner accounts. This is for connected services that need to receive many transactions without worrying about exceeding the log limit. It requires the [CCash Api](https://github.com/SpaceCat-Chan/CatsCCashLuaApi) by SpaceCat-Chan. This is for CCash `v2.6.1`.

## Burner Account
Temporary accounts made with a random username and password.

## Shells
A burner account that stores in its data structure where it is "aimed at". Shells can forward funds to its target, or withdraw funds to a given account, in both cases their purpose is obfuscating the origin of funds. 

## Burner Pool
A collection of burner accounts that through abstraction pretend to be one large account, this allows for the output of `get_logs()` to exceed the typical `100` logs limit per CCash account. Sending to this account is done through asking the pool for an adress, this **must be done for each transaction** lest you distort their logs. Burner pools are an internal structure of a connected service, not intended as a user facing structure; in contrast, Shells are user facing.