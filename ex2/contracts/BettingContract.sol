pragma solidity ^0.4.15;

contract BettingContract {
	/* Standard state variables */
	address public owner;
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
		if(msg.sender == owner){
		_;
		}
	}
	modifier OracleOnly() {
		if(msg.sender == oracle){
		_;
		}
	}

	/* Constructor function, where owner and outcomes are set */
	function BettingContract(uint[] _outcomes) {
		owner = msg.sender;
		outcomes = _outcomes;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
		if(oracle==0){
		oracle = _oracle;
		return oracle;
		}
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
		if(msg.sender == owner || msg.sender == oracle){
			return false;
		}
		bool bet = false;
		var allowed = checkOutcomes();
		for(uint x = 0; x < allowed.length; x++){
			if(_outcome==allowed[x]){
				if(gamblerA == 0){
					gamblerA = msg.sender;
					bet = true;
				}
				else if(gamblerB == 0){
					gamblerB = msg.sender;
					bet = true;
				}
				else{
					return false;
				}
			}
			if(bet){
				Bet memory a = Bet({outcome:_outcome, amount:msg.value, initialized:true});
				bets[msg.sender] = a;
				BetMade(msg.sender);
				return true;
			}
		}
		return false;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		BetClosed();
		if(gamblerA != 0 && gamblerB != 0){
		uint pot = bets[gamblerA].amount + bets[gamblerB].amount;
		if(bets[gamblerA].outcome == bets[gamblerB].outcome){
			winnings[gamblerA] = bets[gamblerA].amount;
			winnings[gamblerB] = bets[gamblerB].amount;
			winnings[oracle] = 0;
		}
		else if(bets[gamblerA].outcome == _outcome){
			winnings[gamblerA] = pot;
			winnings[gamblerB] = 0;
			winnings[oracle] = 0;
		}
		else if(bets[gamblerB].outcome == _outcome){
			winnings[gamblerA] = 0;
			winnings[gamblerB] = pot;
			winnings[oracle] = 0;
		}
		else{
			winnings[gamblerA] = 0;
			winnings[gamblerB] = 0;
			winnings[oracle] = pot;
		}
		contractReset();
		}
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {

		require(winnings[msg.sender] >= withdrawAmount);
			winnings[msg.sender] -= withdrawAmount;
			msg.sender.transfer(withdrawAmount);
			remainingBal =  winnings[msg.sender];

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
		delete(outcomes);
		delete(bets[gamblerA]);
		delete(bets[gamblerB]);
		delete(gamblerA);
		delete(gamblerB);
	}

	/* Fallback function */
	function() {
		revert();
	}
}
