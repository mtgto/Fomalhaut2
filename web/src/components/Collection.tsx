// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { useContext, useEffect } from "react";
import { StateContext } from "../reducer";

import { Collection } from "../domain/collection";
import Library from "./Library";

type Props = {
  readonly id: string;
};

const CollectionPage: React.VoidFunctionComponent<Props> = (props: Props) => {
  const state = useContext(StateContext);
  const collection: Collection | undefined = state.collections.find(
    (collection) => collection.id === props.id
  );
  useEffect(() => {
    if (collection) {
      document.title = `${collection.name} - Fomalhaut2`;
    }
  });
  return (
    <Library
      books={collection?.books ?? []}
      title={collection?.name ?? "Loading"}
    />
  );
};

export default CollectionPage;
