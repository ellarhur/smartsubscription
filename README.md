# smartsubscription
<h1>Smart Subscription Service</h1>
<p>"Develop a contract that functions as a subscription platform, where anyone can create their own subscription service.
Each created subscription service should have:
an owner, a fee, and a period length (e.g., 30 days), and be able to be paused or resumed individually.
The contract should have functions to pay for or extend a subscription, check if an address has an active subscription, and retrieve the end date of active subscriptions. It should also be possible to remove a subscription to someone else.
The creator of a subscription service should be able to change the fee for the subscription, pause or resume their particular service, and collect the revenue that has been collected for the current subscription.</p>

<b>Min planerade logik i nuläget: (In swedish)</b>
<p>
- pragma
- contract SmartSub - öppna med namnet på kontraktet
- enum SubStatus { Active, Paused 
- struct för datatyperna vi kommer behöva: address owner; uint256 fee; uint256 periodLength; - bool paused; uint256 balance;
- mappings på Event (events) och om en deltagare är registrerad (isRegistered)
- Constructor (för vad?) kanske owner = msg.sender, samt eventCounter ska vara 0 från början.
- funktioner: paySub, extendSub, isActive, getEndDate, giveawaySub
- custom modifiers: bara skaparen av prenumerationstjänsten ska kunna ändra avgiften för prenumerationen, pausa eller återuppta sin tjänst, ta ut intäkter som samlats in av aktuella prenumerationen.
- Events: prenumeration har skapats, användare har prenumererat, användare har pausat, pengar har tagits emot ?
- TESTER.</p>