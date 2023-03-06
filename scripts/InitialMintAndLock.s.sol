// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Scripting tool
import {Script} from "../lib/forge-std/src/Script.sol";

import {Minter} from "../contracts/Minter.sol";

contract InitialMintAndLock is Script {
    address private constant TEAM_MULTI_SIG = 0x13eeB8EdfF60BbCcB24Ec7Dd5668aa246525Dc51;

    // address to receive veNFT to be distributed to partners in the future
    address private constant FLOW_VOTER_EOA = 0xcC06464C7bbCF81417c08563dA2E1847c22b703a;
    address private constant ASSET_EOA = 0x1bAe1083CF4125eD5dEeb778985C1Effac0ecC06;

    // team member addresses
    address private constant DUNKS = 0x069e85D4F1010DD961897dC8C095FBB5FF297434;
    address private constant T0RB1K = 0x0b776552c1Aef1Dc33005DD25AcDA22493b6615d;
    address private constant CEAZOR = 0x06b16991B53632C2362267579AE7C4863c72fDb8;
    address private constant MOTTO = 0x78e801136F77805239A7F533521A7a5570F572C8;
    address private constant COOLIE = 0x03B88DacB7c21B54cEfEcC297D981E5b721A9dF1;

    // token amounts
    uint256 private constant ONE_MILLION = 1e24; // 1e24 == 1e6 (1m) ** 1e18 (decimals)
    uint256 private constant TWO_MILLION = 2e24; // 2e24 == 1e6 (1m) ** 1e18 (decimals)
    uint256 private constant THREE_MILLION = 3e24; // 3e24 == 1e6 (1m) ** 1e18 (decimals)
    uint256 private constant FOUR_MILLION = 4e24; // 4e24 == 1e6 (1m) ** 1e18 (decimals)

    // time
    uint256 private constant ONE_YEAR = 31_536_000;
    uint256 private constant TWO_YEARS = 63_072_000;
    uint256 private constant FOUR_YEARS = 126_144_000;

    Minter private minter;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // TODO: Fill address after mainnet deploy
        minter = Minter(address(0));

        // Mint tokens and lock for veNFT

        // 1. Mint to Flow voter EOA
        _batchInitialMintAndLock({
            owner: FLOW_VOTER_EOA,
            numberOfVotingEscrow: 5,
            amountPerVotingEscrow: ONE_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: FLOW_VOTER_EOA,
            numberOfVotingEscrow: 6,
            amountPerVotingEscrow: TWO_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: FLOW_VOTER_EOA,
            numberOfVotingEscrow: 2,
            amountPerVotingEscrow: THREE_MILLION,
            lockTime: FOUR_YEARS
        });

        // 2. Mint to team members
        _batchInitialMintAndLock({
            owner: DUNKS,
            numberOfVotingEscrow: 1,
            amountPerVotingEscrow: FOUR_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: DUNKS,
            numberOfVotingEscrow: 1,
            amountPerVotingEscrow: TWO_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: T0RB1K,
            numberOfVotingEscrow: 3,
            amountPerVotingEscrow: FOUR_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: CEAZOR,
            numberOfVotingEscrow: 3,
            amountPerVotingEscrow: FOUR_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: MOTTO,
            numberOfVotingEscrow: 3,
            amountPerVotingEscrow: FOUR_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: COOLIE,
            numberOfVotingEscrow: 3,
            amountPerVotingEscrow: FOUR_MILLION,
            lockTime: FOUR_YEARS
        });

        // 3. Mint for future partners
        _batchInitialMintAndLock({
            owner: ASSET_EOA,
            numberOfVotingEscrow: 4,
            amountPerVotingEscrow: THREE_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: TEAM_MULTI_SIG,
            numberOfVotingEscrow: 18,
            amountPerVotingEscrow: THREE_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: ASSET_EOA,
            numberOfVotingEscrow: 4,
            amountPerVotingEscrow: TWO_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: TEAM_MULTI_SIG,
            numberOfVotingEscrow: 14,
            amountPerVotingEscrow: TWO_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: TEAM_MULTI_SIG,
            numberOfVotingEscrow: 15,
            amountPerVotingEscrow: ONE_MILLION,
            lockTime: FOUR_YEARS
        });

        _batchInitialMintAndLock({
            owner: ASSET_EOA,
            numberOfVotingEscrow: 5,
            amountPerVotingEscrow: ONE_MILLION,
            lockTime: TWO_YEARS
        });

        _batchInitialMintAndLock({
            owner: ASSET_EOA,
            numberOfVotingEscrow: 5,
            amountPerVotingEscrow: ONE_MILLION,
            lockTime: ONE_YEAR
        });
        // Mint for current partners and presale
        _singleInitialMintAndLock(0x69224dbA1D77bfe6eA99409aB595d04631D95C22, 1205636240970620000000000);
        _singleInitialMintAndLock(0x69224dbA1D77bfe6eA99409aB595d04631D95C22, 1201854505093560000000000);
        _singleInitialMintAndLock(0x69224dbA1D77bfe6eA99409aB595d04631D95C22, 1207527108909160000000000);
        _singleInitialMintAndLock(0x69224dbA1D77bfe6eA99409aB595d04631D95C22, 1207527108909160000000000);
        _singleInitialMintAndLock(0x69224dbA1D77bfe6eA99409aB595d04631D95C22, 1207527108909160000000000);
        _singleInitialMintAndLock(0xCFFC6e659DF622e2d41c7A879C76E6d33F37925E, 1207527108909160000000000);
        _singleInitialMintAndLock(0xF09d213EE8a8B159C884b276b86E08E26B3bfF75, 5000000000000000000000000);
        _singleInitialMintAndLock(0x50149b01f19c2D4A403B1FE4469c117a5cEdb4fc, 1006272590757630000000000);

        // Mint for snapshot recipients, quants already 1.2x
        _singleInitialMintAndLock(0xd0cC9738866cd82B237A14c92ac60577602d6c18, 1200000000000000000);
        _singleInitialMintAndLock(0x38dAEa6f17E4308b0Da9647dB9ca6D84a3A7E195, 24000000000000000000000);
        _singleInitialMintAndLock(0xaA970e6bD6E187492f8327e514c9E8c36c81f11E, 24000000000000000000000);
        _singleInitialMintAndLock(0xa66e216b038d0F4121bf9A218dABbf4759375f5E, 1200000000000000000000);
        _singleInitialMintAndLock(0xC9eebecb1d0AfF4fb2B9978516E075A33639892C, 1025088000000000000000);
        _singleInitialMintAndLock(0xe9335fabfB4536bE78D539D759a29e1AFE7455A6, 3508800000000000000000);
        _singleInitialMintAndLock(0x37FC9Dc092E8a30A63A1567C9ac9738A7D4A08ed, 1200000000000000000000);
        _singleInitialMintAndLock(0x0496cbAD3B943cc246Aa793AB069bFC5516961Ef, 1200000000000000000000);
        _singleInitialMintAndLock(0xaA970e6bD6E187492f8327e514c9E8c36c81f11E, 12000000000000000000000);
        _singleInitialMintAndLock(0x3aE6a0e8Ec1Edd305553686387dC85Ff8D16AC51, 1014000000000000000000);
        _singleInitialMintAndLock(0xED20BC9f8BE737572d7e40237023C7A8FEA3449e, 61044000000000000000);
        _singleInitialMintAndLock(0x6c7286c5AB525ccD92c134c0dCDfDdfcA018B048, 600000000000000000000);
        _singleInitialMintAndLock(0x5Be66f4095f89BD18aBE4aE9d2acD5021EC433Bc, 900000000000000000000);
        _singleInitialMintAndLock(0xB1fC41Cbad16caFDfC2ED196c7fe515DfB6a1577, 3762240000000000000000);
        _singleInitialMintAndLock(0x2Ba838E42126aC349D01c3D1FAc85a36266151a4, 36000000000000000000);
        _singleInitialMintAndLock(0x609470c2f08FF626078bA64Ceb905d73b155089d, 840000000000000000000);
        _singleInitialMintAndLock(0x947D9bcDc2C34Df8587630CAf45b2a2bf07c88cB, 6000000000000000000000);
        _singleInitialMintAndLock(0x82619EDe0ac5d964a0711613cFf5446ED3fF85Dc, 1200000000000000000);
        _singleInitialMintAndLock(0x707c4603FB72996FF95AB91f571516aFC0F3Fe1b, 70608000000000000000);
        _singleInitialMintAndLock(0x7E3b6f966f3666F77813db84DD352173749D24d8, 600000000000000000000);
        _singleInitialMintAndLock(0x037B21279931E628b11b4507b9F7870B15dE1C17, 787824000000000000000);
        _singleInitialMintAndLock(0x3C2d6d7144241F1F1203c29C124585e55B58975E, 240000000000000000000);
        _singleInitialMintAndLock(0x3C2d6d7144241F1F1203c29C124585e55B58975E, 240000000000000000000);
        _singleInitialMintAndLock(0xc742a9458c4Cc6f6498007ffC81266Cd3a3f578A, 28800000000000000000);
        _singleInitialMintAndLock(0x891C16d225e4Fd30d0874Bf2E139B0c11a459a07, 1351200000000000000000);
        _singleInitialMintAndLock(0x5FE1521173F553084eD21e5CbeDE7233b5fE1AA7, 120000000000000000000);
        _singleInitialMintAndLock(0x540A6992368aA24dd6baD1DB8BF4982e6183Caf3, 892536000000000000000);
        _singleInitialMintAndLock(0x20cE0C0f284219f4E0B68804a8333A782461674c, 30000000000000000000);
        _singleInitialMintAndLock(0x41a6ac7f4e4DBfFEB934f95F1Db58B68C76Dc4dF, 43788000000000000000);
        _singleInitialMintAndLock(0x9665B6F0CF162792851A902E452248B16F2f4b5A, 1692540023765800000000);
        _singleInitialMintAndLock(0x9665B6F0CF162792851A902E452248B16F2f4b5A, 978720000000000000000);
        _singleInitialMintAndLock(0x02706C602c59F86Cc2EbD9aE662a25987A7C7986, 198000000000000000000);
        _singleInitialMintAndLock(0x5FE1521173F553084eD21e5CbeDE7233b5fE1AA7, 480000000000000000000);
        _singleInitialMintAndLock(0x15Eb585735334Db4B0B75919e5990E6391863B39, 34800000000000000000);
        _singleInitialMintAndLock(0x96FCa82BB2ce4c5A700a14581412366CC05dd6fA, 3600000000000000000000);
        _singleInitialMintAndLock(0xb00d51d3992BC412f783D0e21EDcf952Ce651D91, 1824000000000000000);
        _singleInitialMintAndLock(0x56BbBDD8d9e939EC047E3a61907a4caF4d90d231, 4645200000000000000000);
        _singleInitialMintAndLock(0x274949b0dB377742A46074f75749E953A8da45A7, 5545200000000000000000);
        _singleInitialMintAndLock(0xDc43D0c0497FBf3BB3cf43dcAFaCe9c116d5dd21, 120000000000000000000);
        _singleInitialMintAndLock(0xAf79312EB821871208ac76A80c8E282f8796964e, 768000000000000000000);
        _singleInitialMintAndLock(0xe4ec13946CE37ae7b3EA6AAC315B486DAD7766F2, 774000000000000000000);
        _singleInitialMintAndLock(0xB3dDC2A5B4EbDb7640191906Bd4195E23e17142c, 1800000000000000000000);
        _singleInitialMintAndLock(0xb0FabE3bCAC50F065DBF68C0B271118DDC005402, 24000000000000000000000);
        _singleInitialMintAndLock(0x6fE4aceD57AE0b50D14229F3d40617C8b7d2F2E1, 2230332000000000000000);
        _singleInitialMintAndLock(0xd264bC31A13D962c22967f02e44DAdD8Bbf25232, 240000000000000000000);
        _singleInitialMintAndLock(0xbFB5458071867Bc00985BC6c13EE400327Ac5F97, 60000000000000000000);
        _singleInitialMintAndLock(0x56F662AADe12e5aB99C4dcb037d1274d0d5dcb94, 29897047241334700000000);
        _singleInitialMintAndLock(0x3a390b018fc3425d06FB84DCcdD140481A960939, 2452800000000000000000);
        _singleInitialMintAndLock(0xCb59280EB3983a4221263343EF184D2D0189De17, 158400000000000000000);
        _singleInitialMintAndLock(0x0d7BbDb6d0D82E896ECB8ED8Bc33aaBd20dE0dA9, 3506400000000000000000);
        _singleInitialMintAndLock(0x2ed284077cc25A3f400DAEA79714Ac4A5AC474aC, 613200000000000000000);
        _singleInitialMintAndLock(0x14989473630F117Dd5583B946B9B4733CD305e57, 6741600000000000000000);
        _singleInitialMintAndLock(0x6f5a8A35fb10EEcEF9128f407a0fe67B898556CF, 12554198211802100000000);
        _singleInitialMintAndLock(0x812B9c3Ea2c49beC95D0Bcda4Db39513baaee261, 1789008000000000000000);
        _singleInitialMintAndLock(0x80bb0D87DCe1a94329586Ce9C7d39692bBf44af6, 1200000000000000000000);
        _singleInitialMintAndLock(0x80bb0D87DCe1a94329586Ce9C7d39692bBf44af6, 120000000000000000000);
        _singleInitialMintAndLock(0x30B5a6e6f54507E0DEE280923234204B6A82664A, 195492000000000000000);
        _singleInitialMintAndLock(0x2e0692A3d9097931E9b7ba47035C8EA4A388f747, 7044000000000000000000);
        _singleInitialMintAndLock(0x57702217d1cDbf4DF7110ABD91832216310B4062, 1200000000000000000000);
        _singleInitialMintAndLock(0x09bAc567D73E8BC701a900D14C90c06644eA0156, 885600000000000000000);
        _singleInitialMintAndLock(0x4A228f14d2130E8E4636418B52aAF3D6b4E887D3, 4382400000000000000000);
        _singleInitialMintAndLock(0xd8b87A01980eB792e3BC030bDEc42Db2b9B5CBfc, 241200000000000000000);
        _singleInitialMintAndLock(0x25217b4A6138350350A2ce1f97A6B0111bbFdB56, 1200000000000000000000);
        _singleInitialMintAndLock(0x973872cA85cD7175b02FE24701438174901ED751, 1560000000000000000000);
        _singleInitialMintAndLock(0xB0720A40d6335dF0aC90fF9e4b755217632Ca78C, 1488000000000000000000);
        _singleInitialMintAndLock(0x3AA6605d87f611E43aD0a64740d6BeF9b80FCD2C, 6000000000000000000000);
        _singleInitialMintAndLock(0x135Cc51c0b07a8f70256e8DF398e6B916b402444, 360000000000000000000);
        _singleInitialMintAndLock(0x945a873B0E08a361458141f637031490cA01b9c1, 576000000000000000000);
        _singleInitialMintAndLock(0x464F6392E68Bc6093354E5bf12692e37F5e4113e, 1200000000000000000000);
        _singleInitialMintAndLock(0x1C86E98A4CC451db8A502f31c14327D2B7CEC123, 339532320000000000000);
        _singleInitialMintAndLock(0x17114903eB90909D3058dAE24D583E5970030FFb, 5400000000000000000000);
        _singleInitialMintAndLock(0x17114903eB90909D3058dAE24D583E5970030FFb, 3829200000000000000000);
        _singleInitialMintAndLock(0xe12D731750E222eC53b001E00d978901B134CFC9, 332400000000000000000);
        _singleInitialMintAndLock(0x801612E860e40612cfbbdEF0133A2Fb6938f2f73, 48000000000000000000);
        _singleInitialMintAndLock(0xe12D731750E222eC53b001E00d978901B134CFC9, 2145600000000000000000);
        _singleInitialMintAndLock(0xE7A1C621Ed75EC40fe4c86605e60d2851287D14D, 146400000000000000000);
        _singleInitialMintAndLock(0xD1A0B66835D830e9ada42eEf436f3AA8005b20B5, 1896000000000000000000);
        _singleInitialMintAndLock(0x7Cb552152e2b28F9f6911c51B69B0d8D1FADafe1, 96000000000000000000);
        _singleInitialMintAndLock(0x249A49d3201C1B92a1029Aab1BC76a6Ca8f5FFf0, 248400000000000000000);
        _singleInitialMintAndLock(0xc27FD9D5113dE19EA89D0265Be9FD93F35f052c8, 2341200000000000000000);
        _singleInitialMintAndLock(0xf6301E682769A8b3ECdCe94b2419ba40A958D17e, 3085080000000000000000);
        _singleInitialMintAndLock(0xfe5a2B6Cf60e8A5c06a87c999E7944421653e0f3, 240000000000000000000);
        _singleInitialMintAndLock(0x0D0d6625F9A0B3370b4b69393E59fdD4d077BB38, 784800000000000000000);
        _singleInitialMintAndLock(0xbC82A7232c1f043e4cc608e0eC1510Cf50E28f64, 108000000000000000000);
        _singleInitialMintAndLock(0x35128c4263aA0213c59A897Fd31d8C837E8B71C8, 120000000000000000000);
        _singleInitialMintAndLock(0x7Cb552152e2b28F9f6911c51B69B0d8D1FADafe1, 12000000000000000000);
        _singleInitialMintAndLock(0xDE0187458364Eb836D5bF563721efD1ED14B9673, 240000000000000000000);
        _singleInitialMintAndLock(0x0a3043F9d2b1c6cCfc492EB59Af5156F378c57BD, 1200000000000000000);
        _singleInitialMintAndLock(0xAE886e2A6AA00e98C0C7b1e4885f94a2dB720690, 6240696000000000000000);
        _singleInitialMintAndLock(0x5fA275BA9F04BDC906084478Dbf41CBE29388C5d, 112800000000000000000);
        _singleInitialMintAndLock(0x97294B51BF128E6988c7747E0696Ed7F7CfEe993, 1856040000000000000000);
        _singleInitialMintAndLock(0x945a873B0E08a361458141f637031490cA01b9c1, 805200000000000000000);
        _singleInitialMintAndLock(0x865D7eb5db37cc02ec209DD778f4e3851a421A20, 329760000000000000000);
        _singleInitialMintAndLock(0x97c98D6ab8DBbfe6ba464BD7a849d376DA1bB540, 180000000000000000000);
        _singleInitialMintAndLock(0x55e1490a1878D0B61811726e2cB96560022E764c, 86880000000000000000);
        _singleInitialMintAndLock(0x97Db0E57b1C315a08cc889Ed405ADB100D7F137d, 1327116000000000000000);
        _singleInitialMintAndLock(0xc45D05CDc809d20c7B14959E8cd4a1199E3e966F, 1419144000000000000000);
        _singleInitialMintAndLock(0xEfce38f31Ebeb9637E85D3487595261FDf6ebeEb, 174600000000000000000);
        _singleInitialMintAndLock(0x5A1a3dff949225E39767Ca981218756DB47C7d8c, 60000000000000000000);
        _singleInitialMintAndLock(0xd286a9bB11d2165915E3bf6D1c79aadEBe30f605, 90900000000000000000);
        _singleInitialMintAndLock(0xBd1E1Cc9613B510d1669D1e79Fd0115C70a4C7be, 480000000000000000000);
        _singleInitialMintAndLock(0xBd1E1Cc9613B510d1669D1e79Fd0115C70a4C7be, 547200000000000000000);
        _singleInitialMintAndLock(0xC438E5d32f9381b59072b9a0c730Cbac41575A4E, 6000000000000000000000);
        _singleInitialMintAndLock(0x1E480827489E3eA19f82EF213b67200A76C0DF58, 360000000000000000000);
        _singleInitialMintAndLock(0x0D69BF20A4A00cbebC569E4beF27a78DcB4C0880, 240000000000000000000);
        _singleInitialMintAndLock(0x1E480827489E3eA19f82EF213b67200A76C0DF58, 1492800000000000000000);
        _singleInitialMintAndLock(0x908E8E8084d660f8f9054AA8Ad1B31380d04B08F, 85572000000000000000);
        _singleInitialMintAndLock(0xdDb3e886D78F180A0B435741901cE091cdd0a848, 1862400000000000000000);
        _singleInitialMintAndLock(0x90F15E09B8Fb5BC080B968170C638920Db3A3446, 120000000000000000000000);
        _singleInitialMintAndLock(0xbC82A7232c1f043e4cc608e0eC1510Cf50E28f64, 217200000000000000000);
        _singleInitialMintAndLock(0x56E30aF541D4d54b96770Ecc1a9113F02FEe3bf1, 18917688000000000000000);
        _singleInitialMintAndLock(0x20cE0C0f284219f4E0B68804a8333A782461674c, 30000000000000000000);
        _singleInitialMintAndLock(0xd7F1BfBfA430FFEE78511E37772cAdaFF63A9A23, 1200000000000000000);
        _singleInitialMintAndLock(0xCba1A275e2D858EcffaF7a87F606f74B719a8A93, 300000000000000000000000);
        _singleInitialMintAndLock(0x4A401Ee7Fef089CD20D183fE2510d7BD38294728, 241200000000000000000);
        _singleInitialMintAndLock(0xFe36AacBCF5677a4A04288764C16acb4220894b9, 1200000000000000000000);
        _singleInitialMintAndLock(0x707c4603FB72996FF95AB91f571516aFC0F3Fe1b, 61398000000000000000);
        _singleInitialMintAndLock(0xAA1742ab92c694934b97Ab9F557E565Bd2217BFf, 120000000000000000000);
        _singleInitialMintAndLock(0xE524D29daf6D7CDEaaaF07Fa1aa7732a45f330B3, 1080000000000000000000);
        _singleInitialMintAndLock(0x8E07Ab8Fc9E5F2613b17a5E5069673d522D0207a, 120000000000000000000);
        _singleInitialMintAndLock(0x9DEB607b7E92096df55b02aA563e82F612fD0DEf, 1670256000000000000000);
        _singleInitialMintAndLock(0x7798Ba9512B5A684C12e31518923Ea4221A41Fb9, 1712160000000000000000);
        _singleInitialMintAndLock(0x868CBfd33ec93B451c510125E4D9f1AB1E42fcD2, 1680396000000000000000);
        _singleInitialMintAndLock(0xAB63953B631336bD204fdcF126e2a010A47b1A36, 780000000000000000000);
        _singleInitialMintAndLock(0x7074E05C39b41EDd1C16478856b5de54B3ac67D6, 1200000000000000000);
        _singleInitialMintAndLock(0x479dE30A1E7e53657C437a6d36ae6389B290B5Fb, 3600000000000000000000);
        _singleInitialMintAndLock(0xb8920e475E32B807cE51e0eF823fE070D7D96e8C, 528000000000000000000);
        _singleInitialMintAndLock(0xb0916C38861dCeef1A62A77887e573861FFb5d63, 27600000000000000000);
        _singleInitialMintAndLock(0x707c4603FB72996FF95AB91f571516aFC0F3Fe1b, 27634800000000000000);
        _singleInitialMintAndLock(0xDEb3994785Bfc8863e808df0E0C43C9C0058d7c9, 571440000000000000000);
        _singleInitialMintAndLock(0x4CE69fd760AD0c07490178f9a47863Dc0358cCCD, 600000000000000000000);
        _singleInitialMintAndLock(0x6F106e0ef498a594CCE8280976822fA3798A35cb, 2429760000000000000000);
        _singleInitialMintAndLock(0x9b25235ee2e5564F50810E03eA5F91976A8EE6fA, 4705200000000000000000);
        _singleInitialMintAndLock(0xEFa9bEbE299dE7AcAECa6876E1E4f5508eEeF2db, 7200000000000000000);
        _singleInitialMintAndLock(0x5fA275BA9F04BDC906084478Dbf41CBE29388C5d, 120000000000000000000);
        _singleInitialMintAndLock(0x5fA275BA9F04BDC906084478Dbf41CBE29388C5d, 62400000000000000000);
        _singleInitialMintAndLock(0xC9eebecb1d0AfF4fb2B9978516E075A33639892C, 1200000000000000000000);
        _singleInitialMintAndLock(0x865D7eb5db37cc02ec209DD778f4e3851a421A20, 364800000000000000000);
        _singleInitialMintAndLock(0xd0441C0B63f6c97D56e9490B3fdd1c45F89D3678, 5806800000000000000000);
        _singleInitialMintAndLock(0xb0916C38861dCeef1A62A77887e573861FFb5d63, 14400000000000000000);
        _singleInitialMintAndLock(0xbA00D84Ddbc8cAe67C5800a52496E47A8CaFcd27, 21493200000000000000000);
        _singleInitialMintAndLock(0xD40846A19fdC9c8255DCcD18BcBB261BDBF5e4db, 338040000000000000000);
        _singleInitialMintAndLock(0xFe36AacBCF5677a4A04288764C16acb4220894b9, 1200000000000000000000);
        _singleInitialMintAndLock(0x4c890Dc20f7D99D0135396A08d07d1518a45a1DD, 1200000000000000000);
        _singleInitialMintAndLock(0xbA00D84Ddbc8cAe67C5800a52496E47A8CaFcd27, 19147200000000000000000);
        _singleInitialMintAndLock(0xD40846A19fdC9c8255DCcD18BcBB261BDBF5e4db, 2815200000000000000000);
        _singleInitialMintAndLock(0x5fA275BA9F04BDC906084478Dbf41CBE29388C5d, 122400000000000000000);
        _singleInitialMintAndLock(0xD40846A19fdC9c8255DCcD18BcBB261BDBF5e4db, 978000000000000000000);
        _singleInitialMintAndLock(0x9505F160A9a74ad532d674De4F200484e0049b43, 1489680000000000000000);
        _singleInitialMintAndLock(0x9505F160A9a74ad532d674De4F200484e0049b43, 1489680000000000000000);
        _singleInitialMintAndLock(0xb6fB12999a09eFfdbcC6F60776331eacCc42E539, 60000000000000000000000);
        _singleInitialMintAndLock(0xb6fB12999a09eFfdbcC6F60776331eacCc42E539, 60000000000000000000000);
        _singleInitialMintAndLock(0x0a3043F9d2b1c6cCfc492EB59Af5156F378c57BD, 14164800000000000000000);
        _singleInitialMintAndLock(0xD26eA7412FB75D5E4c8c9F3EE7b1dfFf64440eE8, 31200000000000000000);
        _singleInitialMintAndLock(0xDE0187458364Eb836D5bF563721efD1ED14B9673, 6000000000000000000);
        _singleInitialMintAndLock(0x859Fc918Cf1322686FeC52A30E4A9eA388DF876D, 12000000000000000000);
        _singleInitialMintAndLock(0xe9bCCEd88099FC4aacF78b7c43307E758E1a5382, 1200000000000000000000);
        _singleInitialMintAndLock(0x7206BC81E2C52441EEFfE120118aC880f4528dDA, 3049200000000000000000);
        _singleInitialMintAndLock(0x1448D297420799a0dEB4bE0C270E8ec310c8E8dD, 4800000000000000000);
        _singleInitialMintAndLock(0x75592081D5FC1c38d2da8098dfE535CaDBe39425, 12000000000000000000);
        _singleInitialMintAndLock(0x9105F56F58A9cDB0e2DFb8696197CFAF3E45b9F0, 2904000000000000000);
        _singleInitialMintAndLock(0x8DE3c3891268502F77DB7E876d727257DEc0F852, 40380000000000000000);
        _singleInitialMintAndLock(0x5D8A52e816b7A29789C32dD21A034caDDd2bC750, 60000000000000000000);
        _singleInitialMintAndLock(0x7074E05C39b41EDd1C16478856b5de54B3ac67D6, 1200000000000000000);
        _singleInitialMintAndLock(0xD016cCF7B485D658E063d2E7CB3Afef94Bf79548, 6000000000000000000);
        _singleInitialMintAndLock(0x7A8B83DaC270463895233Bb3932A799c12919f27, 4200000000000000000);
        _singleInitialMintAndLock(0xDE0187458364Eb836D5bF563721efD1ED14B9673, 337200000000000000000);
        _singleInitialMintAndLock(0xdDb3e886D78F180A0B435741901cE091cdd0a848, 165264000000000000000);
        _singleInitialMintAndLock(0x0b776552c1Aef1Dc33005DD25AcDA22493b6615d, 1200120000000000000000);
        _singleInitialMintAndLock(0x9BDbdb4A8f7f816C87a67F5281484ED902C6b942, 1800000000000000000);
        _singleInitialMintAndLock(0xf4E2152c622260A1f1f8E8B8c4C3C5065165Ce55, 118800000000000000000);
        _singleInitialMintAndLock(0xd204Bc46046FC0Cd3f074fF9B3Be7b5C59f0a150, 3475464000000000000000);
        _singleInitialMintAndLock(0xD7bb2EeE591CE19A54636600936eAB8a40f5a65C, 9600000000000000000);
        _singleInitialMintAndLock(0xEb0CeB1F89D1dd01bDFD2Ff9e145271d8FEEfB00, 192000000000000000000);
        _singleInitialMintAndLock(0x686Bd59caE3e78107515E87B2895cCBe27fb7D0A, 1800000000000000000000);
        _singleInitialMintAndLock(0xb245A959A3D2608e248239638a240c5FCFE20596, 856800000000000000000);
        _singleInitialMintAndLock(0xdDb3e886D78F180A0B435741901cE091cdd0a848, 246396000000000000000);
        _singleInitialMintAndLock(0x4A80f927126eC56c1E6773805fFa03A04216b293, 28406400000000000000000);
        _singleInitialMintAndLock(0xB1e22281E1BC8Ab83Da1CB138e24aCB004B5a4ca, 3600000000000000000000);
        _singleInitialMintAndLock(0x84A51c92a653dc0e6AE11C9D873C55Ee7Af62106, 2113200000000000000);
        _singleInitialMintAndLock(0x84A51c92a653dc0e6AE11C9D873C55Ee7Af62106, 2110800000000000000000);
        _singleInitialMintAndLock(0x3bE2a617a86DD49Bc8893ca04CEa2e5F444F9c12, 717600000000000000000);

        // set initializer to 0 so we can no longer mint more
        minter.startActivePeriod();

        vm.stopBroadcast();
    }

    function _singleInitialMintAndLock(address owner, uint256 amount) private {
        Minter.Claim[] memory claim = new Minter.Claim[](1);
        claim[0] = Minter.Claim({claimant: owner, amount: amount, lockTime: FOUR_YEARS});
        minter.initialMintAndLock(claim, amount);
    }

    function _batchInitialMintAndLock(
        address owner,
        uint256 numberOfVotingEscrow,
        uint256 amountPerVotingEscrow,
        uint256 lockTime
    ) private {
        Minter.Claim[] memory claim = new Minter.Claim[](numberOfVotingEscrow);
        for (uint256 i; i < numberOfVotingEscrow; i++) {
            claim[i] = Minter.Claim({claimant: owner, amount: amountPerVotingEscrow, lockTime: lockTime});
        }
        minter.initialMintAndLock(claim, amountPerVotingEscrow * numberOfVotingEscrow);
    }
}
