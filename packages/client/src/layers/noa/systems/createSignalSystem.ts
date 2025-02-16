import { defineComponentSystem, getComponentValue } from "@latticexyz/recs";
import { keccak256 } from "@latticexyz/utils";
import { EntityID } from "@latticexyz/recs";
import { NetworkLayer } from "../../network";
import { NoaLayer } from "../types";

export async function createSignalSystem(network: NetworkLayer, context: NoaLayer) {
  const {
    api: { setBlock },
  } = context;

  const {
    world,
    components: { Position, Signal },
    api: { getSignalData, isSignalSource },
  } = network;

  defineComponentSystem(world, Signal, (update) => {
    const position = getComponentValue(Position, update.entity);
    const blockSignalData: any = getSignalData(update.entity);

    if (position !== undefined) {
      if (blockSignalData.isActive) {
        // set block to redflower
        setBlock(position, keccak256("block.RedFlower") as EntityID);
      } else {
        setBlock(position, keccak256("block.CyanFlower") as EntityID);
      }
    }
  });
}
