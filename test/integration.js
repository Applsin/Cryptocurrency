const MainContract = artifacts.require("RPC");
const WrapperContract = artifacts.require("Wrap");

contract("Integration testing", function() {
    it("Check init before start", async () => {
        RPC = await MainContract.deployed();
        subcontract = await WrapperContract.deployed();
        subcontract.set_contract_address(RPC.address);

        let startable = true;
        try {
            await subcontract.start_game()
        } catch (err) {
            startable = false;
        }
        assert.equal(startable, false)
    });
    it("Check correctness of commitments via external contract", async () => {
        await subcontract.play('0x846b7b6deb1cfa110d0ea7ec6162a7123b761785528db70cceed5143183b11fc');
        player_1_choise = await RPC.encrMoveFirst.call();
        player_2_choise = await RPC.encrMoveSecond.call();
        assert.equal(player_1,'0x846b7b6deb1cfa110d0ea7ec6162a7123b761785528db70cceed5143183b11fc');
        assert.equal(player_2,'0x0000000000000000000000000000000000000000000000000000000000000000');
    });
    it("Check values after flashing game via external contract", async () => {
        await subcontract.dropGameState();
        player_1_choise = await RPC.encrMoveFirst.call();
        player_2_choise = await RPC.encrMoveSecond.call();
        assert.equal(player_1,'0x0000000000000000000000000000000000000000000000000000000000000000');
        assert.equal(player_2,'0x0000000000000000000000000000000000000000000000000000000000000000');
    });
    
})