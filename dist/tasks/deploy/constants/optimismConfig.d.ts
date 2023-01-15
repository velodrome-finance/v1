import { ethers } from "ethers";
declare const optimismConfig: {
    lzChainId: number;
    lzEndpoint: string;
    WETH: string;
    USDC: string;
    teamEOA: string;
    teamMultisig: string;
    emergencyCouncil: string;
    merkleRoot: string;
    tokenWhitelist: string[];
    partnerAddrs: string[];
    partnerAmts: ethers.BigNumber[];
    partnerMax: ethers.BigNumber;
};
export default optimismConfig;