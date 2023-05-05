// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "contracts/interfaces/IPair.sol";
import "contracts/interfaces/IRouter.sol";

contract VelodromeLibrary {
    IRouter internal immutable router;
    event Log(uint r0, uint r1, bool st, uint sample);

    constructor(address _router) {
        router = IRouter(_router);
    }

    struct Diffs {
        uint256[] aDiffs;
        uint256[] bDiffs;
    }

    struct PairData {
        uint256 dec0;
        uint256 dec1;
        uint256 r0;
        uint256 r1;
        bool st;
        address t0;
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        return x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3*x0*(y*y/1e18)/1e18+(x0*x0/1e18*x0/1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = (xy - k)*1e18/_d(x0, y);
                y = y + dy;
            } else {
                uint dy = (k - xy)*1e18/_d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getTradeDiffs(uint[] memory amountIn, address[] memory tokenIn, address[] memory tokenOut, bool[] memory stable) external view returns (uint[] memory a, uint[] memory b) {
        Diffs memory diffs;
        diffs.aDiffs = new uint256[]( amountIn.length );
        diffs.bDiffs = new uint256[]( amountIn.length );
        for (uint16 i = 0; i < amountIn.length; i++) {
            PairData memory pairData;
            (pairData.dec0, pairData.dec1, pairData.r0, pairData.r1, pairData.st, pairData.t0,) = IPair(router.pairFor(tokenIn[i], tokenOut[i], stable[i])).metadata();
            if (stable[i]) {
                uint sample = tokenIn[i] == pairData.t0 ? pairData.r0*pairData.dec1/pairData.r1 : pairData.r1*pairData.dec0/pairData.r0;
                diffs.aDiffs[i] = _getAmountOut(sample, tokenIn[i], pairData.r0, pairData.r1, pairData.t0, pairData.dec0, pairData.dec1, pairData.st) * 1e18 / sample;
            }
            else {
                diffs.aDiffs[i] = tokenIn[i] == pairData.t0 ? (pairData.r1 * 1e18 / pairData.dec1) * pairData.dec0 / pairData.r0 : (pairData.r0 * 1e18 / pairData.dec0) * pairData.dec1 / pairData.r1;
            }
            diffs.bDiffs[i] = _getAmountOut(amountIn[i], tokenIn[i], pairData.r0, pairData.r1, pairData.t0, pairData.dec0, pairData.dec1, pairData.st) * 1e18 / amountIn[i];
        }
        return (diffs.aDiffs, diffs.bDiffs);
    }

    function getTradeDiff(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        if (stable) {
            uint sample = tokenIn == t0 ? r0*dec1/r1 : r1*dec0/r0;
            a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        }
        else {
            a = tokenIn == t0 ? (r1 * 1e18 / dec1) * dec0 / r0 : (r0 * 1e18 / dec0) * dec1 / r1;
        }
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function getTradeDiff(uint amountIn, address tokenIn, address pair) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(pair).metadata();
        uint sample = tokenIn == t0 ? r0*dec1/r1 : r1*dec0/r0;
        a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function getSample(address tokenIn, address tokenOut, bool stable) external view returns (uint) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? r0*dec1/r1 : r1*dec0/r0;
        return _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
    }

    function getMinimumValue(address tokenIn, address tokenOut, bool stable) external view returns (uint, uint, uint) {
        (uint dec0, uint dec1, uint r0, uint r1,, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        uint sample = tokenIn == t0 ? r0*dec1/r1 : r1*dec0/r0;
        return (sample, r0, r1);
    }

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut, bool stable) external view returns (uint) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.pairFor(tokenIn, tokenOut, stable)).metadata();
        return _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1, address token0, uint decimals0, uint decimals1, bool stable) internal pure returns (uint) {
        if (stable) {
            uint xy =  _k(_reserve0, _reserve1, stable, decimals0, decimals1);
            _reserve0 = _reserve0 * 1e18 / decimals0;
            _reserve1 = _reserve1 * 1e18 / decimals1;
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
            uint y = reserveB - _get_y(amountIn+reserveA, xy, reserveB);
            return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
        } else {
            (uint reserveA, uint reserveB, uint decimalsA, uint decimalsB) = tokenIn == token0 ? (_reserve0, _reserve1, decimals0, decimals1) : (_reserve1, _reserve0, decimals1, decimals0);
            if (decimalsA > decimalsB) {
                return (amountIn * reserveB / (reserveA + amountIn)) * (decimalsA / decimalsB);
            }
            else {
                return (amountIn * reserveB / (reserveA + amountIn)) / (decimalsB / decimalsA);
            }
        }
    }

    function _k(uint x, uint y, bool stable, uint decimals0, uint decimals1) internal pure returns (uint) {
        if (stable) {
            uint _x = x * 1e18 / decimals0;
            uint _y = y * 1e18 / decimals1;
            uint _a = (_x * _y) / 1e18;
            uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return _a * _b / 1e18;  // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }
    
}
