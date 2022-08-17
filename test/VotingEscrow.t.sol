// 1:1 with Hardhat test
pragma solidity 0.8.13;

import './BaseTest.sol';

contract VotingEscrowTest is BaseTest {
    VotingEscrow escrow;

    function setUp() public {
        deployOwners();
        deployCoins();
        mintStables();
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1e21;
        mintVelo(owners, amounts);

        VeArtProxy artProxy = new VeArtProxy();
        escrow = new VotingEscrow(address(VELO), address(artProxy));
    }

    function testCreateLock() public {
        VELO.approve(address(escrow), 1e21);
        uint256 lockDuration = 7 * 24 * 3600; // 1 week

        // Balance should be zero before and 1 after creating the lock
        assertEq(escrow.balanceOf(address(owner)), 0);
        escrow.create_lock(1e21, lockDuration);
        assertEq(escrow.ownerOf(1), address(owner));
        assertEq(escrow.balanceOf(address(owner)), 1);
    }

    function testCreateLockOutsideAllowedZones() public {
        VELO.approve(address(escrow), 1e21);
        uint256 oneWeek = 7 * 24 * 3600;
        uint256 fourYears = 4 * 365 * 24 * 3600;
        vm.expectRevert(abi.encodePacked('Voting lock can be 4 years max'));
        escrow.create_lock(1e21, fourYears + oneWeek);
    }

    function testWithdraw() public {
        VELO.approve(address(escrow), 1e21);
        uint256 lockDuration = 7 * 24 * 3600; // 1 week
        escrow.create_lock(1e21, lockDuration);

        // Try withdraw early
        uint256 tokenId = 1;
        vm.expectRevert(abi.encodePacked("The lock didn't expire"));
        escrow.withdraw(tokenId);
        // Now try withdraw after the time has expired
        vm.warp(block.timestamp + lockDuration);
        vm.roll(block.number + 1); // mine the next block
        escrow.withdraw(tokenId);

        assertEq(VELO.balanceOf(address(owner)), 1e21);
        // Check that the NFT is burnt
        assertEq(escrow.balanceOfNFT(tokenId), 0);
        assertEq(escrow.ownerOf(tokenId), address(0));
    }

    function testCheckTokenURICalls() public {
        // tokenURI should not work for non-existent token ids
        vm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        escrow.tokenURI(999);
        VELO.approve(address(escrow), 1e21);
        uint256 lockDuration = 7 * 24 * 3600; // 1 week
        escrow.create_lock(1e21, lockDuration);

        uint256 tokenId = 1;
        vm.warp(block.timestamp + lockDuration);
        vm.roll(block.number + 1); // mine the next block

        // Just check that this doesn't revert
        escrow.tokenURI(tokenId);

        // Withdraw, which destroys the NFT
        escrow.withdraw(tokenId);

        // tokenURI should not work for this anymore as the NFT is burnt
        vm.expectRevert(abi.encodePacked("Query for nonexistent token"));
        escrow.tokenURI(tokenId);
    }

    function testConfirmSupportsInterfaceWorksWithAssertedInterfaces() public {
        // Check that it supports all the asserted interfaces.
        bytes4 ERC165_INTERFACE_ID = 0x01ffc9a7;
        bytes4 ERC721_INTERFACE_ID = 0x80ac58cd;
        bytes4 ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

        assertTrue(escrow.supportsInterface(ERC165_INTERFACE_ID));
        assertTrue(escrow.supportsInterface(ERC721_INTERFACE_ID));
        assertTrue(escrow.supportsInterface(ERC721_METADATA_INTERFACE_ID));
    }

    function testCheckSupportsInterfaceHandlesUnsupportedInterfacesCorrectly() public {
        bytes4 ERC721_FAKE = 0x780e9d61;
        assertFalse(escrow.supportsInterface(ERC721_FAKE));
    }
}
