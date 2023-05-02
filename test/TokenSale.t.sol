pragma solidity 0.8.13;

import './BaseTest.sol';

contract TokenSaleTest is BaseTest {

    TokenSale sale;
    VotingEscrow ve;
    address user1 = 0x2D66cdD2F86548AaA2B37D7FFbd6aCE28f4D71c4; // WL cap 0.25E
    address user2 = 0xaAA8267C8675Cd632688E726622099D1959797D0; // WL cap 0.25E
    address user3 = 0xF8b3bE51C7D4d1B572b069b182FAE38E04322d6d; // WL cap 0.5E

    function setUp() public {
        deployCoins();
        address[] memory owners = new address[](1);
        uint256[] memory amounts = new uint256[](1);
        owners[0] = address(this);
        amounts[0] = 20000e18;
        mintVelo(owners, amounts);
        
        VeArtProxy artProxy = new VeArtProxy();
        ve = new VotingEscrow(address(VELO), address(artProxy));

        // WL rate 1E = 20000 Token
        // public rate 1E = 10000 Token
        // cap 15000 Token
        // max 30% bonus
        sale = new TokenSale(IERC20(address(VELO)), IVotingEscrow(address(ve)), 20000 * 1e6, 10000 * 1e6, 15000e18);

        // merkle root is generated in example_proof.json
        sale.setMerkleRoot(0x8d8edd611c4eda08c1a22a6a9b6c3eadc6e4d2e5c7a475268b5be06aaa269de1);

        // mock ether balance
        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);
    }

    function testNoBonus() public {
        VELO.approve(address(sale), 19500e18); // approve extra 30% bonus

        // test: status is correct
        assertEq(sale.getStatus(), 0);

        sale.start();

        // test: status is correct
        assertEq(sale.getStatus(), 1);

        // user 1 WL amount = 0.25E
        vm.startPrank(user1);
        bytes32[] memory proof1 = new bytes32[](2);
        proof1[0] = 0x91febd0c2d769895ead0f7873c044f3a367bf2ff9849f6800bc4d2187443cb30;
        proof1[1] = 0xc0fe84ab9aa5f745f7cc7efa9948f35d0a09665a15e62073e466e8841a593c47;
        sale.commitWhitelist{value: 0.1 ether}(0.25e18, proof1);
        sale.commitWhitelist{value: 0.14 ether}(0.25e18, proof1);

        // test: claimable amount is correct
        assertEq(sale.getClaimableAmount(user1), 4800e18);

        // test: individual WL cap reached
        vm.expectRevert("Individual cap reached");
        sale.commitWhitelist{value: 0.02 ether}(0.25e18, proof1);
        
        // fill up the rest of WL cap
        sale.commitWhitelist{value: 0.01 ether}(0.25e18, proof1);

        // test: claimable amount is correct
        assertEq(sale.getClaimableAmount(user1), 5000e18);

        vm.stopPrank();

        // user 2 WL amount = 0.25E
        vm.startPrank(user2);
        bytes32[] memory proof2 = new bytes32[](2);
        proof2[0] = 0x7ea9b5357dd8c851ccc7bbd872f3a8f62b9725cf3da0e8431afe31d6544a73e1;
        proof2[1] = 0xc0fe84ab9aa5f745f7cc7efa9948f35d0a09665a15e62073e466e8841a593c47;
        sale.commitWhitelist{value: 0.1 ether}(0.25e18, proof2);

        // test: claimable amount is correct
        assertEq(sale.getClaimableAmount(user2), 2000e18);
        vm.stopPrank();

        // test: user 3 uses invalid merkle proof
        vm.startPrank(user3);
        vm.expectRevert("Invalid proof");
        sale.commitWhitelist{value: 0.25 ether}(0.25e18, proof2);
        vm.stopPrank();

        sale.startPublicRound();

        // test: status is correct
        assertEq(sale.getStatus(), 2);

        vm.startPrank(user3);
        // test: commitWhitelist should revert
        vm.expectRevert("Not whitelist round");
        sale.commitWhitelist{value: 0.25 ether}(0.25e18, proof2);

        // test: user 3 commits public round
        sale.commitPublic{value: 0.8 ether}();
        assertEq(sale.getClaimableAmount(user3), 8000e18);

        // test: 15000e18 tokens sold out, cannot commit anymore
        vm.expectRevert("Global cap reached");
        sale.commitPublic{value: 0.1 ether}();

        // test: cannot claim before end
        vm.expectRevert("Cannot claim yet");
        sale.claim();
        vm.stopPrank();

        // owner calls finish
        uint256 balanceBefore = address(this).balance;
        sale.finish();
        uint256 balanceAfter = address(this).balance;

        // test: ETH is transferred to owner
        assertEq(balanceAfter - balanceBefore, 1.15 ether);
        
        // test: status is correct
        assertEq(sale.getStatus(), 3);

        // test: still cannot claim before "enableClaim"
        vm.expectRevert("Cannot claim yet");
        sale.claim();
        vm.stopPrank();

        sale.enableClaim();
        
        // test: status is correct
        assertEq(sale.getStatus(), 4);

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
        vm.stopPrank();

        balanceBefore = VELO.balanceOf(address(this));
        sale.withdrawRemainingTokens();
        balanceAfter = VELO.balanceOf(address(this));

        // test: 30% bonus tokens are returned because no one got bonus 
        assertEq(balanceAfter - balanceBefore, 15000e18 * 30 / 100);

        // test: totalTokensSold is correct
        assertEq(sale.totalTokensSold(), 15000e18);
    }

    function testBonus() public {
        VELO.approve(address(sale), 19500e18); // approve extra 30% bonus
        sale.start();

        // user 1 WL amount = 0.25E
        bytes32[] memory proof1 = new bytes32[](2);
        proof1[0] = 0x91febd0c2d769895ead0f7873c044f3a367bf2ff9849f6800bc4d2187443cb30;
        proof1[1] = 0xc0fe84ab9aa5f745f7cc7efa9948f35d0a09665a15e62073e466e8841a593c47;
        vm.prank(user1);
        sale.commitWhitelist{value: 0.25 ether}(0.25e18, proof1);

        // test: claimable amount is correct
        assertEq(sale.getClaimableAmount(user1), 5000e18);

        sale.startPublicRound();

        // user 2 commits public round
        vm.prank(user2);
        sale.commitPublic{value: 1 ether}();
        assertEq(sale.getClaimableAmount(user2), 10000e18);

        // owner calls finish and enable claim
        uint256 balanceBefore = address(this).balance;
        sale.finish();
        uint256 balanceAfter = address(this).balance;

        sale.enableClaim();

        // test: ETH is transferred to owner
        assertEq(balanceAfter - balanceBefore, 1.25 ether);

        // user1 claims and locks 1 year (12 months)
        vm.prank(user1);
        sale.claimAndLock(12);

        // test: 30% liquid token bonus, and 1 veNFT
        assertEq(VELO.balanceOf(user1), 5000e18 * 30 / 100);
        assertEq(ve.ownerOf(1), address(user1));
        assertEq(ve.balanceOf(address(user1)), 1);

        // test: owner can claim remaining
        balanceBefore = VELO.balanceOf(address(this));
        sale.withdrawRemainingTokens();
        balanceAfter = VELO.balanceOf(address(this));
        uint expectedReturned = 19500e18 - 5000e18 * 130 / 100 - 10000e18 * 130 / 100;
        assertEq(balanceAfter - balanceBefore, expectedReturned);

        // user2 claims and locks 4 months
        vm.startPrank(user2);

        // test: cannot lock anything other than 1/2/4/8/12 months
        vm.expectRevert("Must lock 1/2/4/8/12 months");
        sale.claimAndLock(13);
        vm.expectRevert("Must lock 1/2/4/8/12 months");
        sale.claimAndLock(9);
        vm.expectRevert("Must lock 1/2/4/8/12 months");
        sale.claimAndLock(0);

        // lock 4 months
        sale.claimAndLock(4);

        // test: 18% liquid token bonus, and 1 veNFT
        assertEq(VELO.balanceOf(user2), 10000e18 * 18 / 100);
        assertEq(ve.ownerOf(2), address(user2));
        assertEq(ve.balanceOf(address(user2)), 1);

        // test: cannot claim and lock twice
        vm.expectRevert("Nothing to claim");
        sale.claimAndLock(4);
        vm.stopPrank();

        balanceBefore = VELO.balanceOf(address(this));
        sale.withdrawRemainingTokens();
        balanceAfter = VELO.balanceOf(address(this));

        // test: owner can claim remaining
        expectedReturned = 19500e18 - 5000e18 - 10000e18 - 5000e18 * 30 / 100 - 10000e18 * 18 / 100;
        assertEq(balanceAfter - balanceBefore, expectedReturned);

        // test: totalTokensSold is correct
        assertEq(sale.totalTokensSold(), 15000e18);
    }
}
