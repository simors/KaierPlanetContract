pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
// kaierPlanet token contract
//
// Symbol      : KAIER
// Name        : kaierPlanet
// Total supply: 1,000,000.000000000000000000
// Decimals    : 18
//
//
// (c) lvyii net Ltd 2018. The MIT Licence.
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// KaierPlanet Token
// ----------------------------------------------------------------------------
contract KaierPlanet is ERC20Interface, Owned {
	using SafeMath for uint;

    string 	public 	symbol;
    string 	public  name;
    uint8 	public 	decimals;
    uint 	public 	_totalSupply;
    uint    public  _totalCrystal;
    uint    public  _periodSupply;

	mapping(address => uint) balances;
	mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) public crystals;
    mapping (uint => mapping (address => bool))  public  claimed;


    event LogClaim    (uint window, address user, uint amount);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function KaierPlanet() {
    	symbol = "KAIER";
        name = "kaierPlanet Supply Token";
        decimals = 18;
        _totalSupply = 1000000 * 10**uint(decimals);
        _periodSupply = 1000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
	}

	// ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // ------------------------------------------------------------------------
    // Get the crystals balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function getCrystal(address tokenOwner) public constant returns (uint balance) {
        return crystals[tokenOwner];
    }

    // ------------------------------------------------------------------------
    // add the crystals balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function addCrystal(uint crystal) public returns (uint balance) {
        require(crystal >= 0);
        crystals[msg.sender] = crystals[msg.sender].add(crystal);
        _totalCrystal = _totalCrystal.add(crystal);
        return crystals[msg.sender];
    }

    // ------------------------------------------------------------------------
    // get total crystals balance 
    // ------------------------------------------------------------------------
    function totalCrystal() public returns (uint amount) {
        return _totalCrystal;
    }

    // ------------------------------------------------------------------------
    // get period crystals supply  
    // ------------------------------------------------------------------------
    function periodSupply() public returns (uint amount) {
        return _periodSupply;
    }

    function claim(uint period) public returns (uint balance) {
        if(claimed[period][msg.sender]) {
            return;
        }
        uint reward = _periodSupply.div(_totalCrystal).mul(crystals[msg.sender]);
        transferFrom(owner, msg.sender, reward);

        claimed[period][msg.sender] = true;
        LogClaim(period, msg.sender, reward);
    }
}