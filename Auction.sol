pragma solidity >=0.6.0 < 0.9.0;

// this contract creates an EOA address to be deployed and used by contract Auction
contract AuctionCreator {
    // create an dynamic array to store the address of the auctions
    Auction[] public auctions;

    // create an auction
    function createAuction() public {
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

contract Auction {
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;

    // store the state of the auction
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    
    uint public highestBindingBid;
    address payable public highestBidder;

    // mapping to store bids amount corresponding to each bidder's address
    mapping(address => uint) public bids;

    uint bidIncrement;

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    modifier notOwner() {
        require(msg.sender != owner, "You are the owner!");
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock, "The auction hasn't started yet!");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "The auction hasn't ended yet!");
        _;
    }

    // eao is the address that clicked on createAuction from AuctionCreator contract
    constructor(address eoa) {
        owner = payable(eoa);
        auctionState = State.Running;
        startBlock = block.number;  // initialize the start block as the current block
        endBlock = startBlock + 3;  // 40320 represents the number of blocks generated in a week (assuming 15 secs/block)
        ipfsHash = "";
        bidIncrement = 1000000000000000000; // 1 Ether
    }

    function min(uint a, uint b) public pure returns (uint) {
        if (a >= b) return b;
        return a;
    }

    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running, "Auction is not in running state!");
        require(msg.value >= 100, "Bid increment is less than 100 wei!");

        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid, "Current bid is lower than the highest binding bid!");
        bids[msg.sender] = currentBid;
        if (currentBid <= bids[highestBidder]) {
            // highest bidder remains unchanged
            // set highest binding bid between the lower value of current bid and increment vs. current highest bid
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        }
        // executed when the current bid is higher than that of the highest bidder
        // highest bidder is another bidder
        highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
        // set the current bidder to be the highest bidder
        highestBidder = payable(msg.sender);  
    }

    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock); // requires the auction to have been canceled or ended
        require(msg.sender == owner || bids[msg.sender] > 0); // only the owner or bidder can finalize the auction

        address payable recipient;
        uint value;

        // auction canceled
        if (auctionState == State.Canceled) {
            // recipient is the bidder who calls this function to get their money back
            recipient = payable(msg.sender); 
            // this is the value the bidder has sent in the auctiond
            value = bids[msg.sender];

        }
        // auction ended, not canceled
        if (msg.sender == owner) { // this is the owner
            recipient = owner;
            value = highestBindingBid;
        }
        else { // this is a bidder
            if (msg.sender == highestBidder) { // case for the highest bidder
                recipient = highestBidder;
                value = bids[highestBidder] - highestBindingBid;
            }
            // case for one of the other bidders in the auction
            recipient = payable(msg.sender);
            value = bids[msg.sender]; 
        }
        // resetiing the bids of the recipient to zero
        bids[recipient] = 0; // prevent any bidder from finalizing the auction more than once
        recipient.transfer(value);
    }
}