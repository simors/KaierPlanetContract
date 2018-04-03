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

    string  public  symbol;
    string  public  name;
    uint8   public  decimals;

    uint    public  _totalSupply;
    uint    public  _totalCrystal;
    uint    public  openTime;             // Time of opening
    uint    public  period;               // period of claim

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => uint) public crystals;
    mapping(address => uint256[]) public preClaimList;  //地址待申领token列表

    address[] userAddress;

    event LogRegister (address user);

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function KaierPlanet(
        uint     _openTime,
        uint     _period
        ) {
        symbol      = "KAIER";
        name        = "kaierPlanet Supply Token";
        decimals    = 18;
        openTime    = _openTime;
        period      = _period;
        _totalSupply    = 1000000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }

    function time() constant returns (uint) {
        return block.timestamp;
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
    // register wallet address
    // ------------------------------------------------------------------------
    function register(address user) public returns (bool success) {
        userAddress.push(user);
        return true;
    }

    // ------------------------------------------------------------------------
    // add the crystals balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function addCrystal(uint crystal) public returns (uint balance) {
        require(crystal >= 0);
        crystals[msg.sender] = crystals[msg.sender].add(crystal);
        return crystals[msg.sender];
    }

    // ------------------------------------------------------------------------
    // get total crystals balance 
    // ------------------------------------------------------------------------
    function totalCrystal() public returns (uint) {
        uint totalCrystals = 0;
        for (uint i = 0; i < userAddress.length; i++) {
            if (preClaimList[userAddress[i]].length < 18) {
                totalCrystals = totalCrystals.add(crystals[userAddress[i]]);
            }
        }
        return totalCrystals;
    }

    // ------------------------------------------------------------------------
    // get period token supply,  all token claimed over in 3 years,  periodSupply
    // reduce by half yearly.
    // ------------------------------------------------------------------------
    function getPeriodSupply(uint timestamp) public returns (uint) {
        if (timestamp < openTime) {
            return 0;
        } else if (timestamp.sub(openTime) < 1 years) {
            return 160000;
        } else if (timestamp.sub(openTime) < 2 years) {
            return 80000;
        } else if (timestamp.sub(openTime) < 3 years) {
            return 40000;
        } else {
            return 0;
        }
    }

    function getPreClaimList(address user) public returns (uint[]) {
        return preClaimList[user];
    }

    function preClaim(address user) internal returns(bool success) {
        if(preClaimList[user].length < 18) {
            uint periodSupply = getPeriodSupply(time());
            uint totalCrystals = totalCrystal();
            uint reward = periodSupply.div(totalCrystals).mul(crystals[user]);
            preClaimList[user].push(reward);
        } else {
            preClaimList[user] = new uint[](0);
        }
        return true;
    }

    function preClaimAll() public returns(bool success) {
        for (uint i = 0; i < userAddress.length; i++) {
            preClaim(userAddress[i]);
        }
        return true;
    }

    function claim(address user) public returns (uint balance) {
        uint total = 0;
        for (uint i = 0; i < preClaimList[user].length; i++) {
            total = total.add(preClaimList[user][i]);
        }
        transfer(user, total);
    }
}