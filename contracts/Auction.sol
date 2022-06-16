//SPDX-Lisence-Identifier: GPL-3.0
pragma solidity >0.5.0 <0.9.0;

    //contract that deploys instance of Auction contract
    contract auctionCreator{
    Auction[] public auctions;
    function createAuction () public {
        //Allows the address that called this function to be the creator of the Auction Contract/
        Auction newAuction = new Auction(msg.sender);
        auctions.push(newAuction);
    }
}

    contract Auction {
    address payable public owner;
    uint public startBlock; 
    uint public endBlock;
    string public ipfsHash;
    enum State {Started, Running, Ended, Canceled}
    State public auctionState;
    uint public highestBindingBid;
    address payable public highestBidder; 
    mapping(address => uint) public bids;
    uint bidIncrement; 
    //Sets the owner of the Auction Contract to the externally owned account that called createAuction() in contract auctionCreator
    constructor(address externallyOwnedAccount) {
        owner = payable(externallyOwnedAccount);
        auctionState = State.Running;
        startBlock = block.number;
        //40320 is about the amount of blocks generated in a week, auction lasts one week. 
        endBlock = startBlock + 40320; 
        ipfsHash = "";
        bidIncrement = 100;
    }

    modifier notOwner(){
        require (msg.sender != owner);
        _;
    }   
    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }
    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    //Find minimum value in order to give the state variable highestBindingBid it's value. 
    function min(uint a, uint b) pure internal returns(uint) {
    if(a <= b) {
        return a;
    }else{
        return b;
    }
    }
    //Any address can place a bid other than the owner of the contract. 
    function placeBid() public payable notOwner afterStart beforeEnd {
        require(auctionState == State.Running);
        require(msg.value >= 100);
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);
        bids[msg.sender] = currentBid;
        // If the bid placed is less than the highest bid, find the minimum value between the newly set bid + increment and the highestBidder. 
        if(currentBid <= bids[highestBidder]) {
            highestBindingBid = min(currentBid +bidIncrement,bids[highestBidder]);
        } else{
            highestBindingBid = min(currentBid, bids[highestBidder]+bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }
    //Cancels auction, only owner can. 
    function cancelAuction() public onlyOwner{
        auctionState = State.Canceled; 
    }

    function finalizeAuction() public {
    //Require State enum to be equal to Canceled or the current block number must be greater than the endBlock, which is equivalent to the block one week after the contract is deployed.
    require(auctionState == State.Canceled || block.number > endBlock);
    //Require the address that called finalizeAuction() to be the owner or an address that has placed a bid.
    require(msg.sender == owner || bids[msg.sender] > 0);
    //Create two local variables type address and type uint. 
    address payable recipient;
    uint value; 
    //Local variables used to set conditions 
    if(msg.sender == owner){
        recipient = owner;
        value = highestBindingBid;
    }else{
        if(msg.sender == highestBidder){
            recipient = highestBidder;
            value = bids[highestBidder] - highestBindingBid;
        }else{
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }
    }
    //Only allows one withdrawal of funds.
    bids[recipient] = 0;
    recipient.transfer(value);
}
}

