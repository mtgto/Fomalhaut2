import React from "react";
import { useParams } from "react-router-dom";

import { Collection } from "../domain/collection";
import Library from "./Library";

type Props = {
  collections: Collection[];
};

const CollectionPage = (props: Props) => {
  const { id }: { id: string } = useParams();
  const collection: Collection | undefined = props.collections.find(
    (collection) => collection.id === id
  );
  return (
    <Library
      books={collection?.books ?? []}
      collections={props.collections}
      title={collection?.name ?? "Loading"}
    />
  );
};

export default CollectionPage;
