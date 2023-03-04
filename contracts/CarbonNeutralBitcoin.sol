pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./Blacklistable.sol";

/**
* @title Carbon Neutral Bitcoin
* @dev This contract is a ERC20 token that represents a green version of bitcoin.
* It's minted by transferring an equivalent amount of WBTC and MCO2.
*/

contract CarbonNeutralBitcoin is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, UUPSUpgradeable, Blacklistable {
   
   
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTERR_ROLE");

    /**
    * @dev Addresses of the assets
    */
    address WBTC;
    address MCO2;
    /**
    * @dev Carbon offset multiplier
    */
    uint256 carbonOffsetMultiplier;
    uint256 precisionDecimals;
   
    event MCO2changed (address MCO2);
    event WBTCchanged (address WBTC);
    event CarbonOffsetMultiplierChanged(uint256 carbonOffsetMultiplier);
    event PrecisionDecimalsChanged(uint256 precisionDecimals); 
   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    /**
    * @dev Initialize the contract
    * @param _WBTC address of the wrapped asset
    * @param _MCO2 address of the carbon offset token
    * @param _carbonOffsetMultiplier carbon offset multiplier
    */
    function initialize( address _WBTC , address _MCO2, uint256 _carbonOffsetMultiplier, uint256 _decimals ) initializer public {
        __ERC20_init("Carbon Neutral Bitcoin", "eBTC");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();        
        __UUPSUpgradeable_init();
        __Blacklistable_Init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);        
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);

        WBTC = _WBTC;
        MCO2 = _MCO2;
        carbonOffsetMultiplier = _carbonOffsetMultiplier;
        precisionDecimals = _decimals;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
    * @dev Mint new GBTC tokens
    * @param to the address of the recipient
    * @param amount the amount of tokens to be minted
    */
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(!paused(), "Carbon Neutral Bitcoin: Contract is paused");
        require(to != address(0), "Carbon Neutral Bitcoin: 'to' address is the zero address");
        require (carbonOffsetMultiplier > 0, "Carbon Neutral Bitcoin: CarbonOffsetMultiplier equal to zero");
        require(ERC20Upgradeable(WBTC).balanceOf(to) >= amount, "Carbon Neutral Bitcoin: WBCT Balance insufficient");
        require(ERC20Upgradeable(MCO2).balanceOf(to) >= ((amount * carbonOffsetMultiplier)/precisionDecimals), "Carbon Neutral Bitcoin: MCO2 Balance insufficient");
        
        ERC20Upgradeable(WBTC).transferFrom(to, address(this), amount);
        ERC20Upgradeable(MCO2).transferFrom(to, address(this), ((amount * carbonOffsetMultiplier)/precisionDecimals));
        _mint(to, amount);
    }
    
    /**
    * @dev Burn GBTC tokens
    * @param amount the amount of tokens to be burned
    */
     function burn(uint256 amount) public override {
        
        super.burn(amount);
        ERC20Upgradeable(WBTC).transfer(msg.sender, amount);
        //offset carbon emissions?
    }

    /**
    * @dev Set the WBTC address
    * @param _WBTC the address of the wrapped asset
    */
    function setWBTC(address _WBTC) public onlyRole(DEFAULT_ADMIN_ROLE) {
        WBTC = _WBTC;
        emit WBTCchanged(_WBTC);
    }

     /**
    * @dev Set the MCO2 address
    * @param _MCO2 the address of the carbon offset token
    */
    function setMCO2(address _MCO2) public onlyRole(DEFAULT_ADMIN_ROLE){
        MCO2 = _MCO2;   
        emit MCO2changed(_MCO2);
    }

     /**
    * @dev Set the carbon offset multiplier
    * @param _carbonOffsetMultiplier carbon offset multiplier
    */
    function SetCarbonOffsetMultiplier(uint256 _carbonOffsetMultiplier) public onlyRole(DEFAULT_ADMIN_ROLE){
        carbonOffsetMultiplier = _carbonOffsetMultiplier;
        emit CarbonOffsetMultiplierChanged(_carbonOffsetMultiplier);
    }

     /**
    * @dev Set the carbon offset multiplier
    * @param _precisionDecimals carbon offset multiplier
    */
    function SetPrecisionDecimals(uint256 _precisionDecimals) public onlyRole(DEFAULT_ADMIN_ROLE){
        precisionDecimals = _precisionDecimals;
        emit PrecisionDecimalsChanged(_precisionDecimals);
    }

    function getCarbonRatioPerBitcoin(uint256 amount) public view returns(uint256 ratio)
    {
        ratio = ((amount * carbonOffsetMultiplier)/precisionDecimals);
    }
    /**
    Evaluates whether a transfer should be allowed or not.
     */
    modifier notRestricted (address from, address to, uint256 value) {
        require(checkBlacklistAllowed(from, to), "Carbon Neutral Bitcoin: Address restricted");
        _;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        notRestricted(from, to, amount)
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyRole(UPGRADER_ROLE)
        override
    {}
}