# Blockchain-based Subscription and Card System

This repository contains code of a blockchain-based infrastructure for card issuing in a public transportation system. It allows customers to purchase subscriptions for a transportation card, and for system owners to control and approve the use of the card. The system was developed as a research project by Aleksa Stanivuk (owner of the reposityory).

## Video Tutorial

A video tutorial will be available soon.

## Deployment

Follow these steps to deploy the smart contracts in RemixIDE:

1. Open **RemixIDE** and create three new files corresponding to the ones in this repository. Paste their content and save.
2. Choose the first available account (address) from the dropdown on the left. These accounts are test accounts and each has 100 ETH for testing purposes. The selected account will be the owner of the smart contracts.
3. Deploy the `CardFactory` contract through the menu on the left and copy the address once it is deployed (use the copy icon next to the deployed contract).
4. Deploy the `SubscriptionOfferFactory` contract by passing the copied `CardFactory` address.
5. Deploy the `CardControl` contract by passing the copied `CardFactory` address.
6. Go back to the deployed `SubscriptionOfferFactory` and copy its address.
7. Open the `CardFactory` contract and set the `SubscriptionOfferFactory` address by calling the `setSubscriptionContractAddress` function.

## Usage

### Creating Subscription Offers

First we have to create some subscription offers that our customers will be able to pay for and in that way prolong the validity of their cards later on.
To create subscription offers that customers can pay for:

1. As the owner, open the menu of the deployed `SubscriptionOfferFactory`. You can see all the functions that are available for the contract.
2. Create two offers:
   - Open `addSubscriptionOffer` and add the following parameters: `"1 month"`, `4`, `1000`. Press **transact**.
   - Change the parameters to `"3 months"`, `12`, `2500` and press **transact** again.
3. Check the offers on the blockchain by calling the `getSubscriptionOffers` function from the menu on the left. You can see the available offers either on the right in the terminal (press on the log to see more details) or on the left, below the called function.
4. Let's update the second offer (ID `1`) by using the `updateSubscriptionFee` function with the parameters `1` for ID and `2600` for the new fee. Press **transact**.
5. Call `getSubscriptionOffers()` again to view the updated offers.

### Creating and Using Cards

Now let’s create our first customer:

1. Switch to the second available account from Remix's dropdown of test accounts (this will be the customer's account).
2. Open the deployed `CardFactory` and use the `createCard` function. Enter the customer's name (you can try yours) and press **transact**.
3. Check the card information by calling `getCard`. Initially, the card will not be approved (`false`), and no subscription will be active (`0`).
4. To fix that the owner of the system first needs to approve the card:
   - Therefore let’s first get the cardId by pressing `getCardId` as the customer and copy the received id.
   - Now switch to the owner's account and use the `approveCard` function, pasting the copied cardId.
   - Switch back to the customer's account and call `getCard`. The card should now have the `isApproved` property set to `true`. The customer can now pay for the subscription and use the card!
5. For customer to pay for a subscription:
   - Go to the deployed `SubscriptionOfferFactory` and use the `paySubscription` function. Pass `1` for the offerId (3-month offer) and the copied cardId.
   - Scroll up in the left menu and find input for Value, and a dropdown next to it. Set the dropdown value to Wei and for value write 2600 (it is the price we set for the 3 months offer). This is how you pay to the contract. Scroll back down and press **transact** in the paySubscription function
6. Congratulations! The card is now valid for the next three months. You can verify the validity by calling `getCard` again.

### Controlling Cards

Let’s imagine our system is in use, and we have customers on the bus. We need a way to control if they actually paid for the ride.

1. As the owner (Switch to the owner test account), add the first controller:
   - Copy the address of the third available test account and paste it into the `addNewController` function of the deployed `CardControl` contract.
2. Switch to the controller account and call the `controlCard` function in the `CardControl` contract, passing the customer’s cardId (copy it again by followig the steps above if needed). Press **transact**.
   - We can see the status of the card in the logs on the right.
3. Congratulations! The proof of concept works.
