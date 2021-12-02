pragma solidity >=0.7.0 <0.9.0;
import "./RPC.sol";

contract SecondContract {
    RPC MainContract;
    
    function set_contract_address(address contract_address) public {
        MainContract = RPC(contract_address);
    }
 
    function start_game() public {
        MainContract.start_game();
    }
    
    function dropGameState() public {
        MainContract.dropGameState();
    }

    function play(bytes32 data) public {
        MainContract.play(data);
    }
} 
