// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

// Interfaces for Uniswap V2
import "https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Callee.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Factory.sol";

// Interfaces for PancakeSwap
import "https://github.com/PancakeSwap/pancake-swap-lib/blob/master/contracts/interfaces/IPancakeRouter02.sol";
import "https://github.com/PancakeSwap/pancake-swap-lib/blob/master/contracts/interfaces/IPancakeFactory.sol";

contract UniswapV2FrontBot {

    // Variables for token and router contracts
    string public tokenName;
    string public tokenSymbol;
    address public uniswapRouterAddress;
    address public pancakeRouterAddress;
    address public uniswapFactoryAddress;
    address public pancakeFactoryAddress;
    IUniswapV2Router02 public uniswapRouter;
    IPancakeRouter02 public pancakeRouter;
    IUniswapV2Factory public uniswapFactory;
    IPancakeFactory public pancakeFactory;
    
    // Variables for tracking front-running attacks
    uint256 public attackThreshold;
    uint256 public maxGasPrice;
    address public targetToken;
    
    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        address _uniswapRouterAddress,
        address _pancakeRouterAddress,
        address _uniswapFactoryAddress,
        address _pancakeFactoryAddress,
        uint256 _attackThreshold,
        uint256 _maxGasPrice
    ) public {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        uniswapRouterAddress = _uniswapRouterAddress;
        pancakeRouterAddress = _pancakeRouterAddress;
        uniswapFactoryAddress = _uniswapFactoryAddress;
        pancakeFactoryAddress = _pancakeFactoryAddress;
        attackThreshold = _attackThreshold;
        maxGasPrice = _maxGasPrice;
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
        pancakeRouter = IPancakeRouter02(pancakeRouterAddress);
        uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
        pancakeFactory = IPancakeFactory(pancakeFactoryAddress);
    }

    // Receive function to accept ETH
    receive() external payable {}

    // Function to set the target token for front-running
    function setTargetToken(address _targetToken) public {
        targetToken = _targetToken;
    }

    // Function to perform front-running attack
    function performFrontRun(
        address tokenIn,
        address tokenOut,
        uint amountIn,
        uint minAmountOut,
        uint deadline
    ) public payable {
        require(tokenIn != address(0) && tokenOut != address(0), "Invalid token address");
        require(amountIn > 0, "Amount in must be greater than zero");
        require(minAmountOut > 0, "Minimum amount out must be greater than zero");

        // Perform a swap on Uniswap
        uniswapRouter.swapExactETHForTokens{value: msg.value}(
            minAmountOut,
            getPathForETHToToken(tokenOut),
            address(this),
            deadline
        );

        // Check if the swap was successful
        uint amountReceived = IERC20(tokenOut).balanceOf(address(this));
        require(amountReceived >= minAmountOut, "Received amount is less than minimum amount");

        // Perform a swap on PancakeSwap
        pancakeRouter.swapExactTokensForTokens(
            amountReceived,
            minAmountOut,
            getPathForTokenToToken(tokenIn, tokenOut),
            address(this),
            deadline
        );

        // Log transaction details
        emit FrontRunExecuted(tokenIn, tokenOut, amountIn, amountReceived);
    }

    // Function to calculate the path for swapping ETH to Token
    function getPathForETHToToken(address token) private view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = token;
        return path;
    }

    // Function to calculate the path for swapping Token to Token
    function getPathForTokenToToken(address tokenIn, address tokenOut) private pure returns (address[] memory) {
        address[] memory path = new address[](3);
        path[0] = tokenIn;
        path[1] = uniswapRouter.WETH();
        path[2] = tokenOut;
        return path;
    }

    // Function to get the current gas price
    function getCurrentGasPrice() public view returns (uint256) {
        return tx.gasprice;
    }

    // Function to check if the current gas price is under the maximum limit
    function isGasPriceAcceptable() public view returns (bool) {
        return getCurrentGasPrice() <= maxGasPrice;
    }

    // Function to withdraw ETH from the contract
    function withdraw(uint256 amount) public {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(msg.sender).transfer(amount);
    }

    // Function to withdraw ERC20 tokens from the contract
    function withdrawERC20(address tokenAddress, uint256 amount) public {
        IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    // Event to log front-running execution
    event FrontRunExecuted(
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );
}

        
        
            // console.log(out_token_addr.blue)
            // console.log(out_token_address)
            //return false;
}
