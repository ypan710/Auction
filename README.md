# This is an decentralized auction smart contract programmed using Solidity

1. The application has a creator who can create a blueprint of the auction
2. Within the blueprint, auction owners from an external account can create instances of the auction smart contract
3. The auction has a start and end date
4. Users can send Ethers to the auction smart contract by bidding 
5. Users can bid the max they're willing to pay, but are only bound by the amount of th binding bid plus an increment (1 Ether that is automatically bid up by the contract)
6. The selling price is the price of the highest binding bid and the winner is the highest bidder
7. The owner can cancel the auction if there is an emergency or finalize the auction after end time
8. After the auction ends, the owner will receive the amount of the highest binding bid and everyone else will receive their money back by withdrawing their own amount (to prevent reentrancy attacks)
