// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Crowdfunding {
    address payable public owner;
    uint256 public fundingGoal;
    uint256 public deadline;
    uint256 public minimumContribution;
    mapping(address => uint256) public contributions;
    uint256 public totalContributions;

    enum State { Fundraising, Expired, Successful }
    State public state = State.Fundraising;

    event FundingReceived(address contributor, uint256 amount, uint256 totalContributions);
    event FundraiserPaid(address recipient);
    event FundraiserFailed();

    constructor(uint256 _fundingGoal, uint256 _deadline, uint256 _minimumContribution) {
        owner = payable(msg.sender);
        fundingGoal = _fundingGoal;
        deadline = block.timestamp + _deadline;
        minimumContribution = _minimumContribution;
    }

    modifier inState(State _state) {
        require(state == _state, "Invalid state.");
        _;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    function contribute() external payable inState(State.Fundraising) {
        require(msg.value >= minimumContribution, "Contributions must be greater than or equal to the minimum contribution.");
        contributions[msg.sender] += msg.value;
        totalContributions += msg.value;
        emit FundingReceived(msg.sender, msg.value, totalContributions);
    }

    function payout() external inState(State.Successful) isOwner {
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether.");
        emit FundraiserPaid(owner);
    }

    function fail() external inState(State.Expired) {
        state = State.FundraiserFailed;
        emit FundraiserFailed();
    }

    function isSuccessful() public view returns (bool) {
        return totalContributions >= fundingGoal;
    }

    function endFundraiser() external inState(State.Fundraising) {
        require(block.timestamp >= deadline, "Deadline has not yet passed.");
        if (isSuccessful()) {
            state = State.Successful;
            payout();
        } else {
            state = State.Expired;
            emit FundraiserFailed();
        }
    }

