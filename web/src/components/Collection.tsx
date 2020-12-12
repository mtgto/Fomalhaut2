import React, { useContext } from "react";
import { useParams } from "react-router-dom";
import { StateContext } from "../reducer";

import { Collection } from "../domain/collection";
import Library from "./Library";

type Props = {};

const CollectionPage = (props: Props) => {
  const state = useContext(StateContext);
  const { id }: { id: string } = useParams();
  const collection: Collection | undefined = state.collections.find(
    (collection) => collection.id === id
  );
  return (
    <Library
      books={collection?.books ?? []}
      title={collection?.name ?? "Loading"}
    />
  );
};

export default CollectionPage;
