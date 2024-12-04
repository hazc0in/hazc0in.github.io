// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

contract hazC0in is IBEP20 {
    using SafeMath for uint256;

    string public constant name = "hazC0in";
    string public constant symbol = "HZC";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply = 100_000_000 * 10**uint256(decimals); // 100 million tokens

    address public owner;

    // Tokenomics
    uint256 public liquidity = _totalSupply.mul(40).div(100);
    uint256 public marketing = _totalSupply.mul(20).div(100);
    uint256 public team = _totalSupply.mul(15).div(100);
    uint256 public advisors = _totalSupply.mul(5).div(100);
    uint256 public rewards = _totalSupply.mul(20).div(100);

    // Tax Rates (in percentage)
    uint256 public liquidityTax = 2;
    uint256 public marketingTax = 2; // Updated to 2%
    uint256 public rewardsTax = 2;   // Updated to 2%

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        // Initial allocation
        _balances[address(this)] = liquidity.add(marketing).add(team).add(advisors).add(rewards);
        _balances[owner] = _totalSupply.sub(_balances[address(this)]);
        emit Transfer(address(0), owner, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        // Calculate total tax
        uint256 totalTaxRate = liquidityTax.add(marketingTax).add(rewardsTax).add(1); // +1% for burning
        uint256 taxAmount = amount.mul(totalTaxRate).div(100);
        uint256 burnAmount = amount.mul(1).div(100); // 1% for burning
        uint256 transferAmount = amount.sub(taxAmount);

        _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(transferAmount);

        // Distribute Tax and Burn
        distributeTax(sender, taxAmount.sub(burnAmount));
        _burn(sender, burnAmount);

        emit Transfer(sender, recipient, transferAmount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function distributeTax(address sender, uint256 taxAmount) internal {
        uint256 liquidityShare = taxAmount.mul(liquidityTax).div(liquidityTax.add(marketingTax).add(rewardsTax));
        uint256 marketingShare = taxAmount.mul(marketingTax).div(liquidityTax.add(marketingTax).add(rewardsTax));
        uint256 rewardsShare = taxAmount.mul(rewardsTax).div(liquidityTax.add(marketingTax).add(rewardsTax));

        _balances[address(this)] = _balances[address(this)].add(taxAmount);

        emit Transfer(sender, address(this), liquidityShare);
        emit Transfer(sender, address(this), marketingShare);
        emit Transfer(sender, address(this), rewardsShare);
    }

    function _burn(address sender, uint256 burnAmount) internal {
        require(burnAmount > 0, "Burn amount must be greater than zero");
        _balances[address(0)] = _balances[address(0)].add(burnAmount);
        _totalSupply = _totalSupply.sub(burnAmount);
        emit Transfer(sender, address(0), burnAmount);
    }
}
