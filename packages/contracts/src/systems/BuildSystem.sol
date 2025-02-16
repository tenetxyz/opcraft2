// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
import "solecs/System.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { getAddressById, addressToEntity } from "solecs/utils.sol";
import { PositionComponent, ID as PositionComponentID } from "../components/PositionComponent.sol";
import { ItemComponent, ID as ItemComponentID } from "../components/ItemComponent.sol";
import { TypeComponent, ID as TypeComponentID } from "../components/TypeComponent.sol";
import { OwnedByComponent, ID as OwnedByComponentID } from "../components/OwnedByComponent.sol";
import { ClaimComponent, ID as ClaimComponentID, Claim } from "../components/ClaimComponent.sol";
import { TypeComponent, ID as TypeComponentID } from "../components/TypeComponent.sol";
import { MineSystem, ID as MineSystemID } from "./MineSystem.sol";
import { getClaimAtCoord } from "../systems/ClaimSystem.sol";
import { VoxelCoord } from "../types.sol";
import { AirID } from "../prototypes/Blocks.sol";
import { BlockInteraction } from "../libraries/BlockInteraction.sol";
import { SignalComponent, ID as SignalComponentID, SignalData } from "../components/SignalComponent.sol";
import { SignalSourceComponent, ID as SignalSourceComponentID } from "../components/SignalSourceComponent.sol";
import { CreateBlock } from "../libraries/CreateBlock.sol";

uint256 constant ID = uint256(keccak256("system.Build"));

// custom flag so tests can work with normal build system
// TODO: The current method of creative mode should be moved to CreativeBuildSystem, and then this flag can be removed
bool constant IS_TESTING = false;

contract BuildSystem is System {
  constructor(IWorld _world, address _components) System(_world, _components) {}

  function execute(bytes memory arguments) public returns (bytes memory) {
    (uint256 blockEntity, VoxelCoord memory coord) = abi.decode(arguments, (uint256, VoxelCoord));

    // Initialize components
    OwnedByComponent ownedByComponent = OwnedByComponent(getAddressById(components, OwnedByComponentID));
    PositionComponent positionComponent = PositionComponent(getAddressById(components, PositionComponentID));
    ClaimComponent claimComponent = ClaimComponent(getAddressById(components, ClaimComponentID));
    ItemComponent itemComponent = ItemComponent(getAddressById(components, ItemComponentID));
    TypeComponent typeComponent = TypeComponent(getAddressById(components, TypeComponentID));

    // Require block to be owned by caller
    require(ownedByComponent.getValue(blockEntity) == addressToEntity(msg.sender), "block is not owned by player");

    // Require no other ECS blocks at this position except Air
    uint256[] memory entitiesAtPosition = positionComponent.getEntitiesWithValue(coord);
    require(entitiesAtPosition.length == 0 || entitiesAtPosition.length == 1, "can not built at non-empty coord");
    if (entitiesAtPosition.length == 1) {
      require(itemComponent.getValue(entitiesAtPosition[0]) == AirID, "can not built at non-empty coord (2)");
      positionComponent.remove(entitiesAtPosition[0]); // remove air ID
    }

    // Check claim in chunk
    uint256 claimer = getClaimAtCoord(claimComponent, coord).claimer;
    require(claimer == 0 || claimer == addressToEntity(msg.sender), "can not build in claimed chunk");

    // copy block and place it in the world

    // curtis removed this so we are in creative mode. I didn't feel like porting this logic to the creative system (cause dhvani may change something)
    // ownedByComponent.remove(blockEntity);

    if (!IS_TESTING) {
      uint256 newEntity = world.getUniqueEntityId();
      uint256 blockType = itemComponent.getValue(blockEntity);
      itemComponent.set(newEntity, blockType); // TODO: remove itemCompoent
      typeComponent.set(newEntity, blockType);
      positionComponent.set(newEntity, coord);

      CreateBlock.addCustomComponents(components, blockType, newEntity);

      // Run block interaction logic
      BlockInteraction.runInteractionSystems(world.systems(), components, newEntity);
    } else {
      // Remove block from inventory and place it in the world
      ownedByComponent.remove(blockEntity);
      positionComponent.set(blockEntity, coord);
      BlockInteraction.runInteractionSystems(world.systems(), components, blockEntity);
    }
  }

  function executeTyped(uint256 entity, VoxelCoord memory coord) public returns (bytes memory) {
    return execute(abi.encode(entity, coord));
  }
}
