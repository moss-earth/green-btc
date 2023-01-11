pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GreenWrappedBitcoin is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, PausableUpgradeable, AccessControlUpgradeable, ERC20PermitUpgradeable, UUPSUpgradeable {
   
   
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    address WBTC;
    address MCO2;
    uint256 carbonOffsetMultiplier;
   
    event MCO2changed (address MCO2);
    event WBTCchanged (address WBTC);
    event CarbonOffsetMultiplierChanged(uint256 carbonOffsetMultiplier);   
   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize( address _WBTC , address _MCO2, uint256 _carbonOffsetMultiplier) initializer public {
        __ERC20_init("GreenWrappedBitcoin", "GBTC");
        __ERC20Burnable_init();
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init("GreenWrappedBitcoin");
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        WBTC = _WBTC;
        MCO2 = _MCO2;
        carbonOffsetMultiplier = _carbonOffsetMultiplier;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        require(ERC20Upgradeable(WBTC).balanceOf(to) >= amount, "GreenWrappedBitcoin: WBCT Balance insufficient");
        require(ERC20Upgradeable(MCO2).balanceOf(to) >= amount * carbonOffsetMultiplier, "GreenWrappedBitcoin: MCO2 Balance insufficient");
        
        ERC20Upgradeable(WBTC).transferFrom(to, address(this), amount);
        ERC20Upgradeable(MCO2).transferFrom(to, address(this), amount * carbonOffsetMultiplier);
        _mint(to, amount);
    }

     function burn(uint256 amount) public override {
        
        super.burn(amount);
        ERC20Upgradeable(WBTC).transfer(msg.sender, amount);
    }


    function setWBTC ( address _WBTC) public onlyRole(DEFAULT_ADMIN_ROLE) {
        WBTC = _WBTC;
        emit WBTCchanged(_WBTC);
    }


    function setMCO2 (address _MCO2) public onlyRole(DEFAULT_ADMIN_ROLE){
        MCO2 = _MCO2;   
        emit MCO2changed(_MCO2);
    }
   
    function CarbonOffsetMultiplier (uint256 _carbonOffsetMultiplier) public onlyRole(DEFAULT_ADMIN_ROLE){
        carbonOffsetMultiplier = _carbonOffsetMultiplier;
        emit CarbonOffsetMultiplierChanged(_carbonOffsetMultiplier);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
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