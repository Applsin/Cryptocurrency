const MainContract = artifacts.require("RPC");

contract("Unit ", function() {
    it("Check init stage", async () => {

        RPC = await MainContract.deployed();
        let player_1 = await RPC.choices.call(0);
        let player_2 = await RPC.choices.call(1);

        assert.equal(player_1.player_addr, '0x0000000000000000000000000000000000000000');
        assert.equal(player_2.player_addr, '0x0000000000000000000000000000000000000000');
        assert.equal(player_1.choice_hash, '0x0000000000000000000000000000000000000000000000000000000000000000');
        assert.equal(player_2.choice_hash, '0x0000000000000000000000000000000000000000000000000000000000000000');
        assert.equal(player_1.choice, '');
        assert.equal(player_2.choice, '');
    });

    it("Check commit single execution", async () => {
        let could_commit = true;
        try {
            await RPC.play('0x846b7b6deb1cfa110d0ea7ec6162a7123b761785528db70cceed5143183b11fc');
        } catch (err) {
            could_commit = false;
        }
        assert.equal(could_commit, false)
    });
})