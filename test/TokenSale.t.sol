pragma solidity 0.8.13;

import './BaseTest.sol';

contract TokenSaleTest is BaseTest {

    TokenSale sale;
    address user1 = 0x2D66cdD2F86548AaA2B37D7FFbd6aCE28f4D71c4; // WL cap 0.25E
    address user2 = 0xaAA8267C8675Cd632688E726622099D1959797D0; // WL cap 0.25E
    address user3 = 0xF8b3bE51C7D4d1B572b069b182FAE38E04322d6d; // WL cap 0.5E

    function setUp() public {
        deployCoins();
        address[] memory owners = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        owners[0] = address(this);
        amounts[0] = 15000e18;
        mintVelo(owners, amounts);

        // WL rate 1E = 20000 Token
        // public rate 1E = 10000 Token
        // cap 15000 Token
        sale = new TokenSale(IERC20(address(VELO)), 20000, 10000, 15000e18);

        // merkle root is generated in example_proof.json
        sale.setMerkleRoot(0x8d8edd611c4eda08c1a22a6a9b6c3eadc6e4d2e5c7a475268b5be06aaa269de1);

        // mock ether balance
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);
    }

    function testEndToEnd() public {
        VELO.approve(address(sale), 15000e18);
        sale.start();

        // user 1 WL amount = 0.25E
        vm.startPrank(user1);
        bytes32[] memory proof1 = new bytes32[](2);
        proof1[0] = 0x91febd0c2d769895ead0f7873c044f3a367bf2ff9849f6800bc4d2187443cb30;
        proof1[1] = 0xc0fe84ab9aa5f745f7cc7efa9948f35d0a09665a15e62073e466e8841a593c47;
        sale.commitWhitelist{value: 0.1 ether}(0, 0.25e18, proof1);
        sale.commitWhitelist{value: 0.15 ether}(0, 0.25e18, proof1);

        // test: claimable amount is correct
        assertEq(sale.getClaimableAmount(user1), 5000e18);

        // test: individual WL cap reached
        vm.expectRevert("Individual cap reached");
        sale.commitWhitelist{value: 0.01 ether}(0, 0.25e18, proof1);

        vm.stopPrank();

        // user 2 WL amount = 0.25E
        vm.startPrank(user2);
        bytes32[] memory proof2 = new bytes32[](2);
        proof2[0] = 0x7ea9b5357dd8c851ccc7bbd872f3a8f62b9725cf3da0e8431afe31d6544a73e1;
        proof2[1] = 0xc0fe84ab9aa5f745f7cc7efa9948f35d0a09665a15e62073e466e8841a593c47;
        sale.commitWhitelist{value: 0.1 ether}(1, 0.25e18, proof2);

        // test: claimable amount is correct
        assertEq(sale.getClaimableAmount(user2), 2000e18);
        vm.stopPrank();

        // test: user 3 uses invalid merkle proof
        vm.startPrank(user3);
        vm.expectRevert("Invalid proof");
        sale.commitWhitelist{value: 0.25 ether}(1, 0.25e18, proof2);
        vm.stopPrank();

        sale.startPublicRound();

        vm.startPrank(user3);
        // test: commitWhitelist should revert
        vm.expectRevert("Public round already started");
        sale.commitWhitelist{value: 0.25 ether}(1, 0.25e18, proof2);

        // test: user 3 commits public round
        sale.commitPublic{value: 0.8 ether}();
        assertEq(sale.getClaimableAmount(user3), 8000e18);

        // test: 15000e18 tokens sold out, cannot commit anymore
        vm.expectRevert("Global cap reached");
        sale.commitPublic{value: 0.1 ether}();

        // test: cannot claim before end
        vm.expectRevert("Not finished yet");
        sale.claim();
        vm.stopPrank();

        // owner calls finish
        uint256 balanceBefore = address(this).balance;
        sale.finish();
        uint256 balanceAfter = address(this).balance;

        // test: ETH is transferred to owner
        assertEq(balanceAfter - balanceBefore, 1.15 ether);

        // test: user1 claims
        vm.prank(user1);
        sale.claim();
        assertEq(VELO.balanceOf(user1), 5000e18);

        // test: user2 claims
        vm.prank(user2);
        sale.claim();
        assertEq(VELO.balanceOf(user2), 2000e18);

        // test: user3 claims
        vm.startPrank(user3);
        sale.claim();
        assertEq(VELO.balanceOf(user3), 8000e18);

        // test: cannot claim twice
        vm.expectRevert("Nothing to claim");
        sale.claim();
    }
}
