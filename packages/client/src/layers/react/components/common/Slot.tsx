import { EntityID } from "@latticexyz/recs";
import React from "react";
import styled from "styled-components";
import { BlockIcon } from "./BlockIcon";
import { Border } from "./Border";

export const Slot: React.FC<{ blockID?: EntityID; quantity?: number }> = ({ blockID, quantity }) => (
  <Border color={"lightgray"}>
    <Border color={"#999999"}>
      <Inner>
        {blockID ? (
          <BlockIcon blockID={blockID} scale={3.6}>
            {quantity != null ? <Quantity>{quantity}</Quantity> : null}
          </BlockIcon>
        ) : null}
      </Inner>
    </Border>
  </Border>
);

const Inner = styled.div`
  width: 64px;
  height: 64px;
  display: grid;
  justify-items: center;
  align-items: center;
  font-size: 20px;
  border: 3px #626262 solid;
`;

const Quantity = styled.div`
  width: 100%;
  height: 100%;
  display: grid;
  justify-content: end;
  align-content: end;
  padding: 7px 3px;
`;
