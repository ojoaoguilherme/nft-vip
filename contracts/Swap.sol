// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;
import "hardhat/console.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Swap {
   // For the scope of these swap examples,
   // we will detail the design considerations when using
   // `exactInput`, `exactInputSingle`, `exactOutput`, and  `exactOutputSingle`.

   // It should be noted that for the sake of these examples, we purposefully pass in the swap router instead of inherit the swap router for simplicity.
   // More advanced example contracts will detail how to inherit the swap router safely.

   ISwapRouter public immutable swapRouter;
   AggregatorV3Interface public priceFeed;

   // This example swaps DAI/WETH9 for single path swaps and DAI/USDC/WETH9 for multi path swaps.

   address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
   address public constant WETH9 = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

   // For this example, we will set the pool fee to 0.3%.
   uint24 public constant poolFee = 3000;

   constructor(ISwapRouter _swapRouter) {
      swapRouter = _swapRouter;
      // priceFeed = _priceFeed;
      priceFeed = AggregatorV3Interface(
         0xAB594600376Ec9fD91F8e885dADF0CE036862dE0
      );
   }

   /// @notice swapExactInputSingle swaps a fixed amount of DAI for a maximum possible amount of WETH9
   /// using the DAI/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
   /// @dev The calling address must approve this contract to spend at least `amountIn` worth of its DAI for this function to succeed.
   /// @param amountIn The exact amount of DAI that will be swapped for WETH9.
   /// @return amountOut The amount of WETH9 received.
   function swapExactInputSingle(
      uint256 amountIn
   ) external returns (uint256 amountOut) {
      // msg.sender must approve this contract

      // Transfer the specified amount of DAI to this contract.
      TransferHelper.safeTransferFrom(
         WETH9,
         msg.sender,
         address(this),
         amountIn
      );

      // uint256 balanceOfWM = WETH9.balanceOf(address(this));
      console.log("Swap Router amount in");
      console.log(amountIn);

      // Approve the router to spend DAI.
      TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);

      // Naively set amountOutMinimum to 0. In production, use an oracle or other data source to choose a safer value for amountOutMinimum.
      // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
      ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
         .ExactInputSingleParams({
            tokenIn: WETH9,
            tokenOut: DAI,
            fee: poolFee,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: fetchMaticPrice(),
            sqrtPriceLimitX96: 0
         });

      // The call to `exactInputSingle` executes the swap.
      amountOut = swapRouter.exactInputSingle(params);
   }

   function fetchMaticPrice() public view returns (uint256 maticPrice) {
      maticPrice = uint256(getChainlinkDataFeedLatestAnswer());
   }

   function getChainlinkDataFeedLatestAnswer() internal view returns (int) {
      // prettier-ignore
      (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
      return answer;
   }

   // /// @notice swapExactOutputSingle swaps a minimum possible amount of DAI for a fixed amount of WETH.
   // /// @dev The calling address must approve this contract to spend its DAI for this function to succeed. As the amount of input DAI is variable,
   // /// the calling address will need to approve for a slightly higher amount, anticipating some variance.
   // /// @param amountOut The exact amount of WETH9 to receive from the swap.
   // /// @param amountInMaximum The amount of DAI we are willing to spend to receive the specified amount of WETH9.
   // /// @return amountIn The amount of DAI actually spent in the swap.
   // function swapExactOutputSingle(
   //    uint256 amountOut,
   //    uint256 amountInMaximum
   // ) external returns (uint256 amountIn) {
   //    // Transfer the specified amount of DAI to this contract.
   //    TransferHelper.safeTransferFrom(
   //       DAI,
   //       msg.sender,
   //       address(this),
   //       amountInMaximum
   //    );

   //    // Approve the router to spend the specifed `amountInMaximum` of DAI.
   //    // In production, you should choose the maximum amount to spend based on oracles or other data sources to acheive a better swap.
   //    TransferHelper.safeApprove(DAI, address(swapRouter), amountInMaximum);

   //    ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter
   //       .ExactOutputSingleParams({
   //          tokenIn: DAI,
   //          tokenOut: WETH9,
   //          fee: poolFee,
   //          recipient: msg.sender,
   //          deadline: block.timestamp,
   //          amountOut: amountOut,
   //          amountInMaximum: amountInMaximum,
   //          sqrtPriceLimitX96: 0
   //       });

   //    // Executes the swap returning the amountIn needed to spend to receive the desired amountOut.
   //    amountIn = swapRouter.exactOutputSingle(params);

   //    // For exact output swaps, the amountInMaximum may not have all been spent.
   //    // If the actual amount spent (amountIn) is less than the specified maximum amount, we must refund the msg.sender and approve the swapRouter to spend 0.
   //    if (amountIn < amountInMaximum) {
   //       TransferHelper.safeApprove(DAI, address(swapRouter), 0);
   //       TransferHelper.safeTransfer(
   //          DAI,
   //          msg.sender,
   //          amountInMaximum - amountIn
   //       );
   //    }
   // }
}
