pragma solidity ^0.4.15;

contract BettingContract {
	/* Standard state variables */
	address owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
	uint outcome;
	uint amount;
	bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
		require(msg.sender == owner);
		_;
	}
	modifier OracleOnly() {
		require(msg.sender == oracle);
		_;
	}

	/* Constructor function, where owner and outcomes are set */
	function BettingContract(uint[] _outcomes) {
		owner = msg.sender;
		outcomes = _outcomes;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
		oracle = _oracle;
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
		require(!bets[msg.sender].initialized && msg.sender != owner && oracle != 0 && msg.sender != oracle);

		if(!bets[gamblerA].initialized){
			gamblerA = msg.sender;
			bets[gamblerB].amount = msg.value;
			bets[gamblerB].outcome = _outcome;
			bets[gamblerB].initialized = true;
			BetMade(gamblerA);
		}
		else if(!bets[gamblerB].initialized){
			gamblerB = msg.sender;
			bets[gamblerB].amount = msg.value;
			bets[gamblerB].outcome = _outcome;
			bets[gamblerB].initialized = true;
			BetMade(gamblerB);
		}
		else{
			BetClosed();
			return false;
		}
		return true;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		require(bets[gamblerA].initialized && bets[gamblerB].initialized);
		if(bets[gamblerA].outcome == bets[gamblerB].outcome){
			winnings[gamblerA] = bets[gamblerA].amount;
			bets[gamblerA].amount = 0;
			winnings[gamblerB] = bets[gamblerB].amount;
			bets[gamblerB].amount = 0;
		}
		else if(bets[gamblerA].outcome == _outcome){
			winnings[gamblerA] = bets[gamblerA].amount + bets[gamblerB].amount;
			bets[gamblerA].amount = 0;
			bets[gamblerB].amount = 0;
		}
		else if(bets[gamblerB].outcome == _outcome){
			winnings[gamblerB] = bets[gamblerA].amount + bets[gamblerB].amount;
			bets[gamblerA].amount = 0;
			bets[gamblerB].amount = 0;
		}
		else{
			winnings[oracle] = bets[gamblerA].amount + bets[gamblerB].amount;
			bets[gamblerA].amount = 0;
			bets[gamblerB].amount = 0;
		}
		contractReset();
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
		if(winnings[msg.sender] >= withdrawAmount){
			winnings[msg.sender] -= withdrawAmount;
			if(!msg.sender.send(withdrawAmount)){
				winnings[msg.sender] += withdrawAmount;
			}
			return winnings[msg.sender];
		}
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
		return outcomes;
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
		return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
		delete outcomes;
		delete gamblerA;
		delete gamblerB;
	}

	/* Fallback function */
	function() {
		revert();
	}
}
