// SPDX-FileCopyrightText: 2020 mtgto <hogerappa@gmail.com>
// SPDX-License-Identifier: GPL-3.0-only

import React, { useContext, useEffect } from "react";
import { useNavigate } from "rocon/react";

import { Collection } from "../domain/collection";
import { StateContext } from "../reducer";
import Library from "./Library";
import { collectionRoutes } from "./Routes";

type Props = {
  readonly id: string;
  readonly page?: number;
};

const CollectionPage: React.VoidFunctionComponent<Props> = (props: Props) => {
  const state = useContext(StateContext);
  const collection: Collection | undefined = state.collections.find(
    (collection) => collection.id === props.id
  );
  const navigate = useNavigate();
  useEffect(() => {
    if (collection) {
      document.title = `${collection.name} - Fomalhaut2`;
    }
  }, [collection]);

  return (
    <Library
      books={collection?.books ?? []}
      title={collection?.name ?? "Loading"}
      page={props.page}
      pageChanged={(page) =>
        navigate(collectionRoutes.route, {
          id: props.id,
          page: page.toString(),
        })
      }
    />
  );
};

export default CollectionPage;
