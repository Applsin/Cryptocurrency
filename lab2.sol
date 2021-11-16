pragma solidity ^0.5.1;

contract RockPaperScissors {
    
    enum Turns {None, R, P, S}
    enum RoundResults {None, First, Second, Draw}   
    
    uint constant public MINIMAL_BET = 1 wei;    
    uint constant public REVEAL_TIMEOUT = 1 minutes;  
    uint public initialBet;                            
    uint private firstReveal;                         
    
    //RPS rules
    mapping(bytes32 => mapping(bytes32 => uint8)) private states;
    
    // Players' addresses
    address payable firstPlayer;
    address payable secondPlayer;

    // Encrypted moves 
    bytes32 private encrMoveFirst;
    bytes32 private encrMoveSecond;

    // Clear moves set only after both players have committed their encrypted moves
    Turns private moveFirst;
    Turns private moveSecond;
    
    constructor() public {
        states[keccak256(abi.encodePacked(Turns.R))][keccak256(abi.encodePacked(Turns.R))] = 0;
        states[keccak256(abi.encodePacked(Turns.R))][keccak256(abi.encodePacked(Turns.P))] = 2;
        states[keccak256(abi.encodePacked(Turns.R))][keccak256(abi.encodePacked(Turns.S))] = 1;
        states[keccak256(abi.encodePacked(Turns.P))][keccak256(abi.encodePacked(Turns.R))] = 1;
        states[keccak256(abi.encodePacked(Turns.P))][keccak256(abi.encodePacked(Turns.P))] = 0;
        states[keccak256(abi.encodePacked(Turns.P))][keccak256(abi.encodePacked(Turns.S))] = 2;
        states[keccak256(abi.encodePacked(Turns.S))][keccak256(abi.encodePacked(Turns.R))] = 2;
        states[keccak256(abi.encodePacked(Turns.S))][keccak256(abi.encodePacked(Turns.P))] = 1;
        states[keccak256(abi.encodePacked(Turns.S))][keccak256(abi.encodePacked(Turns.S))] = 0;
    }
    
    /**
     * Players registration
     * */
    // Bet must be greater than a minimum amount and greater than bet of first player
    modifier validBet() {
        require(msg.value >= MINIMAL_BET);
        require(initialBet == 0 || msg.value >= initialBet);
        _;
    }

    modifier notAPlayer() {
        require(msg.sender != firstPlayer && msg.sender != secondPlayer);
        _;
    }

    // Register a player.
    // Return player's ID upon successful registration.
    function register() public payable validBet notAPlayer returns (uint) {
        if (firstPlayer == address(0x0)) {
            firstPlayer = msg.sender;
            initialBet = msg.value;
            return 1;
        } else if (secondPlayer == address(0x0)) {
            secondPlayer = msg.sender;
            return 2;
        }
        return 0;
    }

    /**
     * Commit turns
    */

    modifier isRegistered() {
        require (msg.sender == firstPlayer || msg.sender == secondPlayer);
        _;
    }

    // Save player's encrypted move.
    // Return 'true' if move was valid, 'false' otherwise.
    function play(bytes32 encrMove) public isRegistered returns (bool) {
        if (msg.sender == firstPlayer && encrMoveFirst == 0x0) {
            encrMoveFirst = encrMove;
        } else if (msg.sender == secondPlayer && encrMoveSecond == 0x0) {
            encrMoveSecond = encrMove;
        } else {
            return false;
        }
        return true;
    }

    /**
     * Reveal
     */

    // Check that either two players made their turn or time has passed
    modifier commitPhaseEnded() {
        require(encrMoveFirst != 0x0 && encrMoveSecond != 0x0);
        _;
    }

    // Compare clear move given by the player with saved encrypted move.
    // Return clear move upon success, 'Turns.None' otherwise.
    function reveal(string memory clearMove) public isRegistered commitPhaseEnded returns (Turns) {
        bytes32 encrMove = sha256(abi.encodePacked(clearMove));  
        Turns move       = Turns(enumIteration(clearMove));      

        // If move invalid, exit
        if (move == Turns.None) {
            return Turns.None;
        }

        // If hashes match, clear move is saved
        if (msg.sender == firstPlayer && encrMove == encrMoveFirst) {
            moveFirst = move;
        } else if (msg.sender == secondPlayer && encrMove == encrMoveSecond) {
            moveSecond = move;
        } else {
            return Turns.None;
        }

        // Timer starts after first decision reveal from one of the players
        if (firstReveal == 0) {
            firstReveal = now;
        }

        return move;
    }

    // Return first character of a given string.
    function enumIteration(string memory str) private pure returns (uint) {
        byte firstByte = bytes(str)[0];
            //R
        if (firstByte == 0x31) {
            return 1;
            //P
        } else if (firstByte == 0x32) {
            return 2;
            //S
        } else if (firstByte == 0x33) {
            return 3;
        } else {
            //None
            return 0;
        }
    }

    /**
     * Result
     */
    modifier revealPhaseEnded() {
        require((moveFirst != Turns.None && moveSecond != Turns.None) ||
                (firstReveal != 0 && now >= firstReveal + REVEAL_TIMEOUT));
        _;
    }

    // Compute the outcome and pay the winner(s)
    function getOutcome() public revealPhaseEnded returns (RoundResults) {
        RoundResults outcome;
        uint result = enumSupport(moveFirst, moveSecond);
        if (result == 0) {
            outcome = RoundResults.Draw;
        } else if (result == 1) {
            outcome = RoundResults.First;
        } else {
            outcome = RoundResults.Second;
        }
        address payable addrA = firstPlayer;
        address payable addrB = secondPlayer;
        uint betPlayerA       = initialBet;
        //No reentry for you,buddy
        dropGameState();
        sendMoney(addrA, addrB, betPlayerA, outcome);

        return outcome;
    }

    // Pay the winner or send money back in case of draw.
    function sendMoney(address payable addrA, address payable addrB, uint betPlayerA, RoundResults outcome) private {
        if (outcome == RoundResults.First) {
            addrA.transfer(address(this).balance);
        } else if (outcome == RoundResults.Second) {
            addrB.transfer(address(this).balance);
        } else {
            addrA.transfer(betPlayerA);
            addrB.transfer(address(this).balance);
        }
    }

    // Reset the game.
    function dropGameState() private {
        firstPlayer     = address(0x0);
        secondPlayer    = address(0x0);
        encrMoveFirst = 0x0;
        encrMoveSecond = 0x0;
        moveFirst     = Turns.None;
        moveSecond     = Turns.None;
        initialBet      = 0;
        firstReveal     = 0;
    }
    
    //No enums in Maps, niice
     function enumSupport(Turns turn1, Turns turn2) private returns(uint) {
        return states[keccak256(abi.encodePacked(turn1))][keccak256(abi.encodePacked(turn2))];
    }
}