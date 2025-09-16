# Smart Subscription Service

<p>Jag har byggt en tjänst med Smart Contracts som gör att vem som helst har möjlighet att starta en prenumerationstjänst på blockkedjan.</p>

## Hur kontraktet är upplagt

<h2>Dessa funktioner skapade jag:</h2>
- *<b>Skapa prenumerationstjänster som subscription owner</b>* med egen avgift och hur frekvent prenumerationen ska vara
- *<b>Prenumerera på tjänster som subscriber</b>* med ETH
- *<b>Hantera sina prenumerationer som subscriber</b>* Du kan pausa, ge bort din prenumeration, och kolla status på när prenumerationen tar slut
- *<b>Kontrollera prenumerationsägare som subscription owner</b>* Du kan ändra dina tjänster genom att ändra pris, samt pausa/aktivera prenumerationstjänsten

## Kontraktets Funktioner

### 🏗️ FUNKTIONER FÖR ÄGARE (Subscription Owners)

#### `createSub(string title, uint256 fee, uint256 cycleLength)`
- *<b>Syfte:*</b>Skapar en ny prenumerationstjänst
- *<b>Parametrar:*</b> 
  - `title`: Namn på tjänsten (t.ex. "Online Newspaper Subscription")
  - `fee`: Avgift i wei
  - `cycleLength`: Längd på prenumerationscykel i sekunder men man skriver days
- *<b>Returnerar:*</b> Unikt ID för prenumerationen
- *<b>Exempel:*</b> `createSub("Online Newspaper Subscription", 100000000000000000, 30 days)`

#### `manageSub(uint256 subscriptionId, uint256 newFee, SubscriptionStatus newStatus)`
- *<b>Syfte:*</b> Låter subscription owner ändra avgift och status på sin tjänst
- **Parametrar:**
  - `subscriptionId`: ID för prenumerationen som ska ändras
  - `newFee`: Ny avgift i wei
  - `newStatus`: `Active` (öppen) eller `Paused` (stängd)
- **Säkerhet:** Endast prenumerationsägaren kan använda denna funktion
- **Exempel:** `manageSub(0, 150000000000000000, SubscriptionStatus.Active)`

#### `withdrawRevenue(uint256 subscriptionId)`
- *<b>Syfte:*</b> Placeholder för framtida funktionalitet att ta ut intäkter
- *<b>Status:*</b> Förenklad implementation (ingen balanshantering än)

### 👥 FUNKTIONER FÖR PRENUMERANTER (Subscribers)

#### Prenumerera på tjänster:

**`subscribe(uint256 subscriptionId)`**
- *<b>Syfte:*</b> Prenumerera på en tjänst med ID
- *<b>Krav:*</b> Skicka ETH motsvarande tjänstens avgift
- *<b>Säkerhet:*</b> Kontrollerar att tjänsten är aktiv och användaren inte redan prenumererar

**`subscribeByTitle(string title)`** ⭐ *Rekommenderas*
- *<b>Syfte:*</b> Prenumerera på en tjänst med titel (mer användarvänligt!)
- *<b>Krav:*</b> Skicka ETH motsvarande tjänstens avgift
- *<b>Exempel:*</b> `subscribeByTitle("Online Newspaper Subscription")` med 0.1 ETH

#### Hantera prenumerationer:

**`pauseSub(uint256 subscriptionId)`**
- *<b>Syfte:*</b> Avsluta din prenumeration med ID
- *<b>Resultat:*</b> Du förlorar tillgång till tjänsten

**`pauseSubByTitle(string title)`** ⭐ *Rekommenderas*
- *<b>Syfte:*</b> Avsluta din prenumeration med titel
- *<b>Exempel:*</b> `pauseSubByTitle("Netflix Premium")`

**`giveawaySub(uint256 subscriptionId, address to)`**
- *<b>Syfte:*</b> Överför din prenumeration till någon annan
- *<b>Användbart:*</b> För att ge bort eller sälja prenumerationer
- *<b>Behåller:*</b> Ursprunglig starttid och slutdatum

#### Kolla prenumerationsstatus:

**`hasActiveSubscription(uint256 subscriptionId)`**
- *<b>Syfte:*</b> Kontrollera om du har aktiv prenumeration (med ID)
- *<b>Returnerar:*</b> `true` eller `false`

**`hasActiveSubscriptionByTitle(string title)`** ⭐ *Rekommenderas*
- *<b>Syfte:*</b> Kontrollera om du har aktiv prenumeration (med titel)
- *<b>Exempel:*</b> `hasActiveSubscriptionByTitle("Netflix Premium")`

**`getSubscriptionEndDate(uint256 subscriptionId)`**
- *<b>Syfte:*</b> Hämta slutdatum för din prenumeration (med ID)
- *<b>Returnerar:*</b> Unix timestamp

**`getSubscriptionEndDateByTitle(string title)`** ⭐ *Rekommenderas*
- *<b>Syfte:*</b> Hämta slutdatum för din prenumeration (med titel)
- *<b>Returnerar:*</b> Unix timestamp som kan konverteras till datum

## Modifiers, säkerhetsåtgärder osv

### Modifiers:
- *<b>`onlyOwner`*</b>: Endast kontraktsägaren får till exempel tillgång
- *<b>`onlySubOwner`*</b>: Endast prenumerationsägaren
- *<b>`subExists`*</b>: Kontrollerar att prenumerationen existerar
- *<b>`subActive`*</b>: Kontrollerar att prenumerationen är aktiv
- *<b>`validPeriod`*</b>: Validerar cykellängd (minst 1 dag)

### Säkerhetskontroller:
- Förhindrar dubbelprenumerationer
- Validerar ETH-belopp
- Kontrollerar att tjänster existerar och är aktiva
- Endast ägare kan modifiera sina tjänster

## Exempel på kontraktets användning

```solidity
// Du är Daniel Ek, Spotifys ägare som implementerar Spotify Premium för första gången med hjälp av ett smart kontrakt i Solidity.
createSub("Spotify Premium", 50000000000000000, 30 days); // 0.05 ETH/månad

// Jag börjar prenumerera på Spotify Premium, jag skickar 0.05 ETH
subscribeByTitle("Spotify Premium");

// Jag vill se att prenumerationen startades. Jag kollar status
bool active = hasActiveSubscriptionByTitle("Spotify Premium");

// Jag vill se om min prenumeration måste uppdateras någon gång, har ett slutdatum
uint256 endDate = getSubscriptionEndDateByTitle("Spotify Premium");

// Jag bestämmer mig för att ta en paus i min prenumeration
pauseSubByTitle("Spotify Premium");

// Du bestämmer dig för att höja priset och pausa tillgången till Spotify Premium tillfälligt
manageSub(0, 75000000000000000, SubscriptionStatus.Paused);
```
## Så kan det gå till när du använder mitt smart kontrakt!

## Gasoptimeringar

## Tester med hardhat